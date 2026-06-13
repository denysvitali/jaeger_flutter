import 'package:flutter_test/flutter_test.dart';
import 'package:jaeger_flutter/core/api/api_client.dart';
import 'package:jaeger_flutter/core/api/jaeger_api.dart';

void main() {
  group('normalizeServerUrl', () {
    test('adds http scheme when missing', () {
      expect(normalizeServerUrl('jaeger.example.com:16686'),
          'http://jaeger.example.com:16686');
    });

    test('preserves https scheme', () {
      expect(normalizeServerUrl('https://jaeger.example.com'),
          'https://jaeger.example.com');
    });

    test('trims trailing slashes', () {
      expect(normalizeServerUrl('http://jaeger.example.com/'),
          'http://jaeger.example.com');
    });

    test('returns empty string for empty input', () {
      expect(normalizeServerUrl(''), '');
    });
  });

  group('TraceSearchRequest', () {
    test('builds query parameters for service only', () {
      const request = TraceSearchRequest(service: 'jaeger', limit: 10);
      final params = request.toQueryParameters();

      expect(params['service'], 'jaeger');
      expect(params['limit'], 10);
      expect(params['offset'], 0);
      expect(params.containsKey('operation'), isFalse);
    });

    test('includes operation and tags when set', () {
      const request = TraceSearchRequest(
        service: 'jaeger',
        operation: 'GET /api/services',
        tags: {'http.status_code': '200'},
        limit: 5,
      );
      final params = request.toQueryParameters();

      expect(params['operation'], 'GET /api/services');
      expect(params['tags'], 'http.status_code=200');
      expect(params['limit'], 5);
    });

    test('formats durations', () {
      const request = TraceSearchRequest(
        service: 'jaeger',
        minDuration: Duration(milliseconds: 10),
        maxDuration: Duration(seconds: 1),
      );
      final params = request.toQueryParameters();

      expect(params['minDuration'], '10ms');
      expect(params['maxDuration'], '1s');
    });
  });
}
