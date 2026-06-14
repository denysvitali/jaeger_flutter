import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaeger_flutter/core/models/models.dart';
import 'package:jaeger_flutter/core/providers/app_providers.dart';
import 'package:jaeger_flutter/features/traces/trace_detail_screen.dart';

void main() {
  group('TraceDetailScreen', () {
    testWidgets('renders a trace with 500+ spans', (WidgetTester tester) async {
      final trace = _generateLargeTrace(spanCount: 550);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            traceProvider(trace.traceID).overrideWith((ref) => trace),
          ],
          child: MaterialApp(home: TraceDetailScreen(traceId: trace.traceID)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('550 spans'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('zoom controls change scale', (WidgetTester tester) async {
      final trace = _generateLargeTrace(spanCount: 10);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            traceProvider(trace.traceID).overrideWith((ref) => trace),
          ],
          child: MaterialApp(home: TraceDetailScreen(traceId: trace.traceID)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.zoom_in), findsOneWidget);
      expect(find.byIcon(Icons.zoom_out), findsOneWidget);

      final zoomIn = find.byIcon(Icons.zoom_in);
      await tester.tap(zoomIn);
      await tester.pumpAndSettle();

      // After zooming, the zoomed percentage label should no longer read 100%.
      expect(find.text('100%'), findsNothing);
    });

    testWidgets('renders trace timeline on a phone-sized viewport', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final trace = _generateLargeTrace(spanCount: 25);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            traceProvider(trace.traceID).overrideWith((ref) => trace),
          ],
          child: MaterialApp(home: TraceDetailScreen(traceId: trace.traceID)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('25 spans'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_left), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_right), findsOneWidget);
      expect(find.byIcon(Icons.manage_search), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Trace _generateLargeTrace({required int spanCount}) {
  const traceId = 'large-trace';
  const processId = 'p1';
  const serviceName = 'test-service';

  final spans = <Span>[];
  const startTime = 1700000000000000;
  const baseDuration = 1000000; // 1 second

  for (var i = 0; i < spanCount; i++) {
    final isRoot = i == 0;
    final references = isRoot
        ? <SpanRef>[]
        : <SpanRef>[
            SpanRef(
              refType: 'CHILD_OF',
              traceID: traceId,
              spanID: 'span-${i - 1}',
            ),
          ];
    spans.add(
      Span(
        traceID: traceId,
        spanID: 'span-$i',
        operationName: 'operation-$i',
        references: references,
        startTime: startTime + (i * 1000),
        duration: baseDuration - (i * 10),
        processID: processId,
      ),
    );
  }

  return Trace(
    traceID: traceId,
    spans: spans,
    processes: const {processId: Process(serviceName: serviceName)},
  );
}
