import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/jaeger_api.dart';
import '../models/models.dart';
import '../services/certificate_provider.dart';
import '../services/server_config.dart';

final serverConfigProvider = Provider<ServerConfig>(
  (ref) => ServerConfig(),
);

final jaegerApiProvider = Provider<JaegerApi>(
  (ref) => NetworkJaegerApi(
    serverConfig: ref.watch(serverConfigProvider),
  ),
);

final certificateStatusProvider = FutureProvider<CertificateStatus>(
  (ref) => const CertificateProvider().getStatus(),
);

final servicesNotifierProvider =
    AsyncNotifierProvider<ServicesNotifier, List<String>>(
  ServicesNotifier.new,
);

class ServicesNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final api = ref.read(jaegerApiProvider);
    final response = await api.getServices();
    return response.data;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(jaegerApiProvider);
      final response = await api.getServices();
      return response.data;
    });
  }
}

final operationsProvider = FutureProvider.family<List<String>, String>(
  (ref, service) async {
    if (service.isEmpty) return const [];
    final api = ref.read(jaegerApiProvider);
    final response = await api.getOperations(service);
    return response.data;
  },
);

final traceSearchParamsProvider =
    NotifierProvider<TraceSearchParamsNotifier, TraceSearchRequest>(
  TraceSearchParamsNotifier.new,
);

class TraceSearchParamsNotifier extends Notifier<TraceSearchRequest> {
  @override
  TraceSearchRequest build() =>
      const TraceSearchRequest(service: '', limit: 20);

  void update(TraceSearchRequest request) {
    state = request;
  }
}

final tracesNotifierProvider =
    AsyncNotifierProvider<TracesNotifier, List<Trace>>(
  TracesNotifier.new,
);

class TracesNotifier extends AsyncNotifier<List<Trace>> {
  @override
  Future<List<Trace>> build() async {
    final params = ref.watch(traceSearchParamsProvider);
    if (params.service.isEmpty) return const [];
    final api = ref.read(jaegerApiProvider);
    final response = await api.searchTraces(params);
    return response.data;
  }

  Future<void> search(TraceSearchRequest request) async {
    ref.read(traceSearchParamsProvider.notifier).update(request);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final params = ref.read(traceSearchParamsProvider);
      if (params.service.isEmpty) return const <Trace>[];
      final api = ref.read(jaegerApiProvider);
      final response = await api.searchTraces(params);
      return response.data;
    });
  }
}

final traceProvider = FutureProvider.family<Trace, String>(
  (ref, traceId) async {
    final api = ref.read(jaegerApiProvider);
    return api.getTrace(traceId);
  },
);
