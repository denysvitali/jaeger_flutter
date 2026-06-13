import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../services/server_config.dart';

/// Query parameters supported by the Jaeger `/api/traces` endpoint.
class TraceSearchRequest {
  const TraceSearchRequest({
    required this.service,
    this.operation,
    this.tags,
    this.startTime,
    this.endTime,
    this.limit = 20,
    this.offset = 0,
    this.minDuration,
    this.maxDuration,
  });

  final String service;
  final String? operation;
  final Map<String, String>? tags;
  final DateTime? startTime;
  final DateTime? endTime;
  final int limit;
  final int offset;
  final Duration? minDuration;
  final Duration? maxDuration;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'service': service,
      'limit': limit,
      'offset': offset,
    };

    if (operation != null && operation!.isNotEmpty) {
      params['operation'] = operation;
    }
    if (tags != null && tags!.isNotEmpty) {
      params['tags'] = tags!.entries
          .map((e) => '${e.key}=${e.value}')
          .join(',');
    }
    if (startTime != null) {
      params['start'] = _microsecondsSinceEpoch(startTime!);
    }
    if (endTime != null) {
      params['end'] = _microsecondsSinceEpoch(endTime!);
    }
    if (minDuration != null) {
      params['minDuration'] = _durationString(minDuration!);
    }
    if (maxDuration != null) {
      params['maxDuration'] = _durationString(maxDuration!);
    }

    return params;
  }

  static int _microsecondsSinceEpoch(DateTime dt) =>
      dt.microsecondsSinceEpoch;

  static String _durationString(Duration d) {
    final us = d.inMicroseconds;
    if (us < 1000) return '${us}us';
    final ms = d.inMilliseconds;
    if (ms < 1000) return '${ms}ms';
    return '${d.inSeconds}s';
  }
}

abstract class JaegerApi {
  Future<ServicesResponse> getServices();
  Future<OperationsResponse> getOperations(String service);
  Future<TracesResponse> searchTraces(TraceSearchRequest request);
  Future<Trace> getTrace(String traceId);
}

class NetworkJaegerApi implements JaegerApi {
  NetworkJaegerApi({required ServerConfig serverConfig})
      : _serverConfig = serverConfig;

  final ServerConfig _serverConfig;

  Future<Dio> _createDio() async {
    final baseUrl = await _serverConfig.getServerUrl();
    return createApiClient(baseUrl: baseUrl);
  }

  @override
  Future<ServicesResponse> getServices() async {
    final dio = await _createDio();
    try {
      final response = await dio.get<dynamic>('/api/services');
      throwIfRequestFailed(response);
      final data = response.data as Map<String, dynamic>;
      return ServicesResponse.fromJson(data);
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<OperationsResponse> getOperations(String service) async {
    final dio = await _createDio();
    try {
      final response = await dio.get<dynamic>(
        '/api/services/${Uri.encodeComponent(service)}/operations',
      );
      throwIfRequestFailed(response);
      final data = response.data as Map<String, dynamic>;
      return OperationsResponse.fromJson(data);
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<TracesResponse> searchTraces(TraceSearchRequest request) async {
    final dio = await _createDio();
    try {
      final response = await dio.get<dynamic>(
        '/api/traces',
        queryParameters: request.toQueryParameters(),
      );
      throwIfRequestFailed(response);
      final data = response.data as Map<String, dynamic>;
      return TracesResponse.fromJson(data);
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<Trace> getTrace(String traceId) async {
    final dio = await _createDio();
    try {
      final response = await dio.get<dynamic>(
        '/api/traces/${Uri.encodeComponent(traceId)}',
      );
      throwIfRequestFailed(response);
      final data = response.data as Map<String, dynamic>;
      final wrapper = TracesResponse.fromJson(data);
      if (wrapper.data.isEmpty) {
        throw const JaegerApiException('Trace not found');
      }
      return wrapper.data.first;
    } finally {
      dio.close(force: true);
    }
  }
}
