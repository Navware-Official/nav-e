import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_e/features/home/home_screen.dart';

void main() {
  testWidgets('HomeScreen has a title and a button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen()));

    // Verify the title is present
    expect(find.text('Home'), findsOneWidget);

    // Verify the button is present
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
