// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:ai_scn/main.dart';

void main() {
  testWidgets('App launches and shows home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartIngredientScannerApp());

    // Verify that the home screen title is displayed.
    expect(find.text('Smart Ingredient Scanner'), findsOneWidget);
    expect(find.text('Smart Food Product Analysis'), findsOneWidget);
    expect(find.text('Scan new product'), findsOneWidget);
  });
}
