import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

// ---------------------------------------------------------------------------
// Theme helpers
// ---------------------------------------------------------------------------

const double _kBorderRadiusSmall = 12;
const double _kBorderRadiusLarge = 16;
const double _kBorderRadiusModal = 24;

const EdgeInsets _kCardPadding = EdgeInsets.all(16);
const EdgeInsets _kCardMargin = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
const EdgeInsets _kInputPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
const EdgeInsets _kChipPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 4);
const EdgeInsets _kChipLabelPadding = EdgeInsets.symmetric(horizontal: 4);

/// Shared page transitions used by the router.
CustomTransitionPage<void> buildPageTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  bool fade = false,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (fade) {
        return FadeTransition(
          opacity: animation.drive(Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut))),
          child: child,
        );
      }
      // Shared-axis horizontal feel via slide + fade
      final slide = Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut));
      final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut));
      return FadeTransition(
        opacity: animation.drive(fadeTween),
        child: SlideTransition(
          position: animation.drive(slide),
          child: child,
        ),
      );
    },
  );
}

ThemeData _buildTheme(Brightness brightness) {
  final seedColor = const Color(0xFFDC382D);
  final secondaryColor = const Color(0xFF0066CC);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
    secondary: secondaryColor,
  );

  final surfaceColor = brightness == Brightness.light
      ? colorScheme.surface
      : colorScheme.surface;

  final cardColor = brightness == Brightness.light
      ? colorScheme.surfaceContainerLow
      : colorScheme.surfaceContainerHigh;

  final textTheme = Typography.material2021(platform: TargetPlatform.android).copyWith(
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      color: colorScheme.onSurface,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      color: colorScheme.onSurface,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurface,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurface,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: colorScheme.onSurface,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: colorScheme.onSurfaceVariant,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: colorScheme.onSurface,
    ),
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: surfaceColor,
    // Typography
    textTheme: textTheme,
    // AppBar
    appBarTheme: AppBarTheme(
      centerTitle: false,
      scrolledUnderElevation: 0,
      backgroundColor: surfaceColor,
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: Border(
        bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
    ),
    // Card
    cardTheme: CardThemeData(
      elevation: 0,
      margin: _kCardMargin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kBorderRadiusLarge),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      color: cardColor,
    ),
    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      prefixIconColor: colorScheme.onSurfaceVariant,
      suffixIconColor: colorScheme.onSurfaceVariant,
      labelStyle: textTheme.bodyMedium!.copyWith(color: colorScheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kBorderRadiusSmall),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kBorderRadiusSmall),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kBorderRadiusSmall),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      contentPadding: _kInputPadding,
    ),
    // Chip
    chipTheme: ChipThemeData(
      padding: _kChipPadding,
      labelPadding: _kChipLabelPadding,
      shape: const StadiumBorder(),
      side: BorderSide.none,
      backgroundColor: colorScheme.surfaceContainerHighest,
      selectedColor: colorScheme.primaryContainer,
      labelStyle: textTheme.bodyMedium!.copyWith(color: colorScheme.onSurface),
      secondaryLabelStyle: textTheme.bodyMedium!.copyWith(color: colorScheme.onPrimaryContainer),
      checkmarkColor: colorScheme.onPrimaryContainer,
    ),
    // Divider
    dividerTheme: DividerThemeData(
      space: 1,
      thickness: 1,
      color: colorScheme.outlineVariant,
    ),
    // Bottom Navigation / NavigationBar
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      indicatorColor: colorScheme.secondaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return textTheme.labelLarge!.copyWith(
            color: colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w600,
          );
        }
        return textTheme.labelLarge!.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: colorScheme.onSecondaryContainer);
        }
        return IconThemeData(color: colorScheme.onSurfaceVariant);
      }),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: colorScheme.surfaceTint,
      height: 80,
    ),
    // Buttons
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kBorderRadiusSmall)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: textTheme.labelLarge,
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withOpacity(0.12);
          }
          return null; // fallback to default filled button color (primary)
        }),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kBorderRadiusSmall)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(8),
      ),
    ),
    // BottomSheet / Dialog
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(_kBorderRadiusLarge),
          topRight: Radius.circular(_kBorderRadiusLarge),
        ),
      ),
      elevation: 0,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kBorderRadiusModal)),
      elevation: 0,
    ),
    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium!.copyWith(color: colorScheme.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kBorderRadiusSmall)),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),
    // ListTile
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kBorderRadiusSmall)),
      tileColor: Colors.transparent,
      selectedTileColor: colorScheme.primaryContainer.withOpacity(0.24),
    ),
    // PopupMenu
    popupMenuTheme: PopupMenuThemeData(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kBorderRadiusSmall)),
      elevation: 0,
    ),
    // Tooltip
    tooltipTheme: TooltipThemeData(
      textStyle: textTheme.bodySmall!.copyWith(color: colorScheme.onInverseSurface),
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(_kBorderRadiusSmall),
      ),
    ),
    // MaterialTapTargetSize
    materialTapTargetSize: MaterialTapTargetSize.padded,
    // Animation defaults
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
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
