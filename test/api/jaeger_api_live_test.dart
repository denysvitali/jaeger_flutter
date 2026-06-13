import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jaeger_flutter/core/api/jaeger_api.dart';
import 'package:jaeger_flutter/core/services/server_config.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();

  const runLive = bool.fromEnvironment('LIVE_TESTS');

  group('Jaeger API live test', () {
    late JaegerApi api;

    setUp(() {
      HttpOverrides.global = _RealHttpOverrides();
      api = NetworkJaegerApi(serverConfig: ServerConfig());
    });

    test('fetch services from local Jaeger', () async {
      final response = await api.getServices();
      expect(response.data, isNotEmpty);
      expect(response.data, contains('jaeger'));
    }, skip: !runLive);

    test('fetch operations for jaeger service', () async {
      final response = await api.getOperations('jaeger');
      expect(response.data, isNotEmpty);
    }, skip: !runLive);

    test('search traces for jaeger service', () async {
      const request = TraceSearchRequest(
        service: 'jaeger',
        limit: 5,
      );
      final response = await api.searchTraces(request);
      expect(response.data, isNotEmpty);
    }, skip: !runLive);

    test('fetch a trace by ID', () async {
      const searchRequest = TraceSearchRequest(
        service: 'jaeger',
        limit: 1,
      );
      final searchResponse = await api.searchTraces(searchRequest);
      expect(searchResponse.data, isNotEmpty);

      final traceId = searchResponse.data.first.traceID;
      final trace = await api.getTrace(traceId);
      expect(trace.traceID, traceId);
      expect(trace.spans, isNotEmpty);
    }, skip: !runLive);
  });
}
