import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kagema_school/main.dart';

void main() {
  testWidgets('Counter feather test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KagemaSchoolApp());

    // Verify that our splash screen or login screen is shown.
    expect(find.text('Kagema school'), findsOneWidget);
  });
}
