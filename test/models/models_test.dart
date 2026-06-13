import 'package:flutter_test/flutter_test.dart';
import 'package:jaeger_flutter/core/models/models.dart';

void main() {
  group('KeyValue', () {
    test('parses string tag', () {
      final kv = KeyValue.fromJson({
        'key': 'http.method',
        'type': 'string',
        'value': 'GET',
      });
      expect(kv.key, 'http.method');
      expect(kv.type, 'string');
      expect(kv.value, 'GET');
    });

    test('parses int64 tag', () {
      final kv = KeyValue.fromJson({
        'key': 'http.status_code',
        'type': 'int64',
        'value': 200,
      });
      expect(kv.value, 200);
    });
  });

  group('Trace', () {
    test('parses a minimal trace response', () {
      final trace = Trace.fromJson({
        'traceID': 'abc123',
        'spans': [
          {
            'traceID': 'abc123',
            'spanID': 'span1',
            'operationName': 'GET /api/services',
            'references': [],
            'startTime': 1781366444419159,
            'duration': 62,
            'tags': [],
            'logs': [],
            'processID': 'p1',
          }
        ],
        'processes': {
          'p1': {
            'serviceName': 'jaeger',
            'tags': []
          }
        },
      });

      expect(trace.traceID, 'abc123');
      expect(trace.spans, hasLength(1));
      expect(trace.spans.first.operationName, 'GET /api/services');
      expect(trace.processes['p1']?.serviceName, 'jaeger');
    });

    test('parses a span with a child reference', () {
      final trace = Trace.fromJson({
        'traceID': 'abc123',
        'spans': [
          {
            'traceID': 'abc123',
            'spanID': 'child',
            'operationName': 'child',
            'references': [
              {
                'refType': 'CHILD_OF',
                'traceID': 'abc123',
                'spanID': 'parent'
              }
            ],
            'startTime': 1,
            'duration': 1,
            'tags': [],
            'logs': [],
            'processID': 'p1',
          }
        ],
        'processes': {
          'p1': {'serviceName': 'svc', 'tags': []}
        },
      });

      expect(trace.spans.first.references.first.refType, 'CHILD_OF');
      expect(trace.spans.first.references.first.spanID, 'parent');
    });
  });

  group('ServicesResponse', () {
    test('parses services list', () {
      final response = ServicesResponse.fromJson({
        'data': ['jaeger', 'happy-cli-go'],
        'total': 2,
        'limit': 0,
        'offset': 0,
        'errors': null,
      });

      expect(response.data, ['jaeger', 'happy-cli-go']);
      expect(response.total, 2);
    });
  });

  group('TracesResponse', () {
    test('parses empty traces list', () {
      final response = TracesResponse.fromJson({
        'data': [],
        'total': 0,
        'limit': 0,
        'offset': 0,
        'errors': null,
      });

      expect(response.data, isEmpty);
    });
  });
}
