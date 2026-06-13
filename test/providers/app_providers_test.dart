import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaeger_flutter/core/api/jaeger_api.dart';
import 'package:jaeger_flutter/core/models/models.dart';
import 'package:jaeger_flutter/core/providers/app_providers.dart';

class _FakeJaegerApi implements JaegerApi {
  _FakeJaegerApi({this.services = const [], this.traces = const []});

  final List<String> services;
  final List<Trace> traces;

  @override
  Future<ServicesResponse> getServices() async =>
      ServicesResponse(data: services);

  @override
  Future<OperationsResponse> getOperations(String service) async =>
      const OperationsResponse();

  @override
  Future<Trace> getTrace(String traceId) async => traces.first;

  @override
  Future<TracesResponse> searchTraces(TraceSearchRequest request) async =>
      TracesResponse(data: traces);
}

void main() {
  group('TraceSearchParamsNotifier', () {
    test('defaults to empty service', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final params = container.read(traceSearchParamsProvider);
      expect(params.service, '');
      expect(params.limit, 20);
    });

    test('update changes state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(traceSearchParamsProvider.notifier)
          .update(const TraceSearchRequest(service: 'jaeger', limit: 10));

      final params = container.read(traceSearchParamsProvider);
      expect(params.service, 'jaeger');
      expect(params.limit, 10);
    });
  });

  group('ServicesNotifier', () {
    test('loads services from API', () async {
      final container = ProviderContainer(
        overrides: [
          jaegerApiProvider.overrideWithValue(
            _FakeJaegerApi(services: ['jaeger', 'frontend']),
          ),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        servicesNotifierProvider,
        (previous, next) {},
      );

      await container.read(servicesNotifierProvider.future);

      final state = subscription.read();
      expect(state.value, ['jaeger', 'frontend']);
    });
  });

  group('TracesNotifier', () {
    test('returns empty list when no service is selected', () async {
      final container = ProviderContainer(
        overrides: [jaegerApiProvider.overrideWithValue(_FakeJaegerApi())],
      );
      addTearDown(container.dispose);

      await container.read(tracesNotifierProvider.future);

      final state = container.read(tracesNotifierProvider);
      expect(state.value, isEmpty);
    });

    test('loads traces when service is selected', () async {
      final container = ProviderContainer(
        overrides: [
          jaegerApiProvider.overrideWithValue(
            _FakeJaegerApi(traces: [const Trace(traceID: 'trace1')]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(traceSearchParamsProvider.notifier)
          .update(const TraceSearchRequest(service: 'jaeger'));

      await container.read(tracesNotifierProvider.future);

      final state = container.read(tracesNotifierProvider);
      expect(state.value?.length, 1);
      expect(state.value?.first.traceID, 'trace1');
    });
  });
}
