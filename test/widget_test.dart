import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sari_app/main.dart';

void main() {
  testWidgets('SARI app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SariApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(Image), findsWidgets);
    expect(find.text('Access SARI Dashboard'), findsOneWidget);
  });
}
