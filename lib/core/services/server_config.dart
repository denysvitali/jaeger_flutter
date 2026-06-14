import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

const _serverUrlKey = 'jaeger_server_url';
const _serverVerifiedAtKey = 'jaeger_server_verified_at';
const _defaultServerUrl = 'http://jaeger.monitoring.svc.cluster.local:16686';

class ServerConfig {
  ServerConfig({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  Future<String> getServerUrl() async {
    final value = await _prefs.getString(_serverUrlKey);
    return value ?? _defaultServerUrl;
  }

  Future<void> setServerUrl(String url) async {
    await _prefs.setString(_serverUrlKey, normalizeServerUrl(url));
  }

  Future<DateTime?> getLastVerifiedAt() async {
    final value = await _prefs.getString(_serverVerifiedAtKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> setLastVerifiedAt(DateTime value) async {
    await _prefs.setString(_serverVerifiedAtKey, value.toIso8601String());
  }

  Future<void> clearServerUrl() async {
    await _prefs.remove(_serverUrlKey);
    await _prefs.remove(_serverVerifiedAtKey);
  }
}

sealed class ServerUrlVerificationResult {
  const ServerUrlVerificationResult();
}

class ServerUrlVerified extends ServerUrlVerificationResult {
  const ServerUrlVerified(this.url);
  final String url;
}

class ServerUrlFailed extends ServerUrlVerificationResult {
  const ServerUrlFailed(this.error);
  final String error;
}

Future<ServerUrlVerificationResult> verifyServerUrl(String rawUrl) async {
  final url = normalizeServerUrl(rawUrl);
  if (url.isEmpty) {
    return const ServerUrlFailed('Server URL is required.');
  }

  final dio = createApiClient(baseUrl: url);
  try {
    final response = await dio.get<dynamic>('/api/services');
    throwIfRequestFailed(response);
    return ServerUrlVerified(url);
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return ServerUrlFailed('Could not connect to $url.');
    }
    if (e.error is HandshakeException) {
      return ServerUrlFailed(
        'TLS handshake failed. If you are using a custom CA, make sure it is '
        'installed in the Android user trust store.',
      );
    }
    return ServerUrlFailed(e.message ?? 'Request failed');
  } catch (e) {
    return ServerUrlFailed(e.toString());
  } finally {
    dio.close(force: true);
  }
}
