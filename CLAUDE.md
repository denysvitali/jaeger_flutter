# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

`jaeger_flutter` is a Flutter mobile app for browsing Jaeger distributed tracing data. It talks to a Jaeger Query HTTP API (default: `http://jaeger.monitoring.svc.cluster.local:16686`), lets users search traces by service/operation/tags, and renders trace detail with an interactive timeline.

Android package name: `it.denv.jaeger`.

## Environment setup

This repo is developed inside a Nix environment. The standard `flutter` wrapper on `PATH` tries to write to the read-only Nix store and fails; use the `sdk-links` wrapper instead:

```bash
export PATH="/nix/store/fqcjikcpdcn123csd805bmg05jv75szj-flutter-wrapped-3.41.9-sdk-links/bin:$PATH"
flutter --version
```

## Common commands

Install dependencies:

```bash
flutter pub get
```

Analyze and format (matches CI):

```bash
flutter analyze
dart format --output=none --set-exit-if-changed .
```

Run all tests:

```bash
flutter test
```

Run a single test file:

```bash
flutter test test/api/api_client_test.dart
```

Run a single test by name:

```bash
flutter test --name 'normalizeServerUrl'
```

Regenerate generated code after changing Freezed/json_serializable models:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Build release APK:

```bash
flutter build apk --release --target-platform android-arm64
```

The release artifact is written to `build/app/outputs/flutter-apk/app-release.apk`.

## CI / release

`.github/workflows/flutter.yml` runs on pushes/PRs to `master`/`main` and tags `v*`:

1. `flutter pub get`
2. `dart format --output=none --set-exit-if-changed .`
3. `flutter analyze`
4. `flutter test`

On pushes to `master`/`main` (and version tags), a second job builds a release APK, uploads it as an artifact, and creates a GitHub release. A signed release requires `KEYSTORE_BASE64`, `KEYSTORE_STORE_PASSWORD`, `KEYSTORE_KEY_PASSWORD`, and `KEYSTORE_KEY_ALIAS` repository secrets; without them the APK is signed with the debug key. `tool/generate_keystore.sh` can create a local keystore for testing.

## Architecture

### Layer / directory layout

- `lib/core/api/` — HTTP layer. `api_client.dart` creates and configures a `Dio` instance, normalizes server URLs, and defines `JaegerApiException`. `jaeger_api.dart` defines `JaegerApi` and `NetworkJaegerApi`, which maps the Jaeger Query endpoints (`/api/services`, `/api/services/{service}/operations`, `/api/traces`, `/api/traces/{traceId}`) to typed responses. `TraceSearchRequest` builds the query parameters for `/api/traces`.
- `lib/core/models/` — Immutable data models generated with `freezed` + `json_serializable`. `models.dart` re-exports them. Generated `.freezed.dart` and `.g.dart` files are checked in; regenerate with `build_runner`.
- `lib/core/providers/` — Riverpod providers. `app_providers.dart` exposes the API, server config, certificate status, and notifiers for services, operations, trace search params, traces, and single trace lookup.
- `lib/core/routing/` — `go_router` configuration. `app_router.dart` sets up a `StatefulShellRoute.indexedStack` with three branches: `/traces`, `/services`, `/settings`. Trace detail is a nested route at `/traces/:traceId`.
- `lib/core/services/` — Shared services. `server_config.dart` persists the Jaeger server URL in `SharedPreferencesAsync` and verifies connectivity. `certificate_provider.dart` reports whether user-installed CA certificates are supported.
- `lib/core/utils/` — Small UI helpers, e.g. service colors, duration formatting, timeline ticks.
- `lib/features/` — One directory per screen/feature: `home/home_shell.dart` (bottom navigation shell), `services/services_screen.dart`, `settings/server_config_screen.dart`, `traces/traces_search_screen.dart`, `traces/trace_detail_screen.dart`.
- `lib/platform_io.dart` / `lib/platform_stub.dart` and `lib/user_certs_io.dart` / `lib/user_certs_stub.dart` — Conditional imports (`dart.library.js_interop`) so the Android-only `dart:io` and certificate plugin code compile on web.

### State management

State is handled with Riverpod:

- `serverConfigProvider` — synchronous access to `ServerConfig`.
- `jaegerApiProvider` — builds the API client from the current server config.
- `servicesNotifierProvider` / `operationsProvider` — load services and per-service operations from Jaeger.
- `traceSearchParamsProvider` — mutable `TraceSearchRequest` state.
- `tracesNotifierProvider` — watches `traceSearchParamsProvider` and fetches traces automatically.
- `traceProvider(traceId)` — fetches a single trace by ID.

### Networking and certificates

On native mobile platforms, `createApiClient` swaps Dio’s adapter for `NativeAdapter` so the platform trust store is used. At startup, `main.dart` loads user-installed CA certificates on Android via `FlutterUserCertificatesAndroid` and injects them into `SecurityContext.defaultContext`; failures are logged but not fatal. The web stub skips certificate handling entirely.

### Trace detail rendering

`TraceDetailScreen` watches `traceProvider(traceId)`. `_TraceBody` pre-computes the span tree (roots, children map, depth, service names) in `initState`, then renders:

- A header with metadata, a mini timeline (`CustomPainter`), and zoom controls.
- A horizontally scrollable timeline with a fixed label column and a zoomable span-bar column.
- Expandable/collapsible span rows driven by `_expandedSpanIds`.
- A bottom sheet with span details, tags, and logs when a row is tapped.

Performance matters here: the screen has been tested with 500+ spans and uses `RepaintBoundary` and lazy `ListView.builder`.

## Testing approach

- Unit / provider tests use `ProviderContainer` and override `jaegerApiProvider` (or specific providers) with fakes; see `test/providers/app_providers_test.dart`.
- Widget tests pump `ProviderScope` with provider overrides; see `test/features/traces/trace_detail_screen_test.dart`.
- `test/api/jaeger_api_live_test.dart` is a live integration test that requires a running Jaeger instance and is not run in CI.

## Code generation

The project uses `build_runner` with `freezed` and `json_serializable`. `build.yaml` configures `json_serializable` with `explicit_to_json: true` and `include_if_null: false`. Always run `build_runner` after editing model classes and commit the generated files.
