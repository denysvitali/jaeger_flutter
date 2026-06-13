import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jaeger_flutter/main.dart';

void main() {
  testWidgets('App renders home shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: JaegerApp()));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
