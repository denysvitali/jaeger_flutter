import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'platform_io.dart' if (dart.library.js_interop) 'platform_stub.dart';
import 'user_certs_io.dart' if (dart.library.js_interop) 'user_certs_stub.dart';

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
  final buffer = StringBuffer()..writeln('-----BEGIN CERTIFICATE-----');
  for (var i = 0; i < base64Data.length; i += 64) {
    buffer.writeln(
      base64Data.substring(i, (i + 64).clamp(0, base64Data.length)),
    );
  }
  buffer.writeln('-----END CERTIFICATE-----');
  return Uint8List.fromList(utf8.encode(buffer.toString()));
}

ThemeData _buildTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFDC382D),
    brightness: brightness,
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surfaceContainerHighest,
      foregroundColor: colorScheme.onSurface,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: colorScheme.surfaceContainerLow,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide.none,
      backgroundColor: colorScheme.surfaceContainerHighest,
    ),
    dividerTheme: const DividerThemeData(space: 1),
  );
}

class JaegerApp extends ConsumerWidget {
  const JaegerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Jaeger',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      routerConfig: router,
    );
  }
}
