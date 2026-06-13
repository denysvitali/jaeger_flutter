import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'platform_io.dart' if (dart.library.js_interop) 'platform_stub.dart';
import 'user_certs_io.dart'
    if (dart.library.js_interop) 'user_certs_stub.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadUserCertificates();
  runApp(const ProviderScope(child: JaegerApp()));
}

/// Loads user-installed CA certificates on Android into the default
/// [SecurityContext] so that Dio (via the native adapter) trusts them.
Future<void> _loadUserCertificates() async {
  if (kIsWeb || !isAndroid) return;

  try {
    final certs = await FlutterUserCertificatesAndroid().getUserCertificates();
    if (certs == null || certs.isEmpty) return;

    for (final derBytes in certs.values) {
      final pem = _derToPem(derBytes);
      SecurityContext.defaultContext.setTrustedCertificatesBytes(pem);
    }
  } catch (e) {
    // Certificate loading is best-effort; failures are logged but not fatal.
    debugPrint('Failed to load user certificates: $e');
  }
}

/// Converts DER-encoded certificate bytes to PEM format.
Uint8List _derToPem(Uint8List der) {
  final base64Data = base64Encode(der);
  final buffer = StringBuffer()
    ..writeln('-----BEGIN CERTIFICATE-----');
  for (var i = 0; i < base64Data.length; i += 64) {
    buffer.writeln(
      base64Data.substring(i, (i + 64).clamp(0, base64Data.length)),
    );
  }
  buffer.writeln('-----END CERTIFICATE-----');
  return Uint8List.fromList(utf8.encode(buffer.toString()));
}

class JaegerApp extends ConsumerWidget {
  const JaegerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Jaeger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
