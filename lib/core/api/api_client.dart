import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';

import '../../platform_io.dart'
    if (dart.library.js_interop) '../../platform_stub.dart';

/// Creates a [Dio] instance configured for the Jaeger API.
///
/// On native mobile platforms the native HTTP stack is used so that the
/// platform trust store (including user-installed CAs on Android) is respected.
Dio createApiClient({
  required String baseUrl,
  Map<String, String> defaultHeaders = const {},
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        HttpHeaders.userAgentHeader: 'JaegerFlutter/1.0',
        ...defaultHeaders,
      },
    ),
  );

  if (!kIsWeb && (isAndroid || isIOS)) {
    dio.httpClientAdapter = NativeAdapter();
  }

  return dio;
}

/// Normalizes a user-entered server URL so it is safe to use as a Dio base URL.
String normalizeServerUrl(String raw) {
  var url = raw.trim();
  if (url.isEmpty) return '';
  if (!url.startsWith(RegExp(r'https?://'))) {
    url = 'http://$url';
  }
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  return url;
}

class JaegerApiException implements Exception {
  const JaegerApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'JaegerApiException: $message (status: $statusCode)';
}

void throwIfRequestFailed(Response<dynamic> response) {
  if (response.statusCode == null || response.statusCode! >= 400) {
    final data = response.data;
    final message = data is Map<String, dynamic>
        ? data['errors']?.toString() ?? response.statusMessage
        : response.statusMessage;
    throw JaegerApiException(
      message ?? 'Request failed',
      statusCode: response.statusCode,
    );
  }
}
