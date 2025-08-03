import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/bloc/app_state_bloc.dart';
import 'package:nav_e/features/home/home_screen.dart';

void main() {
  testWidgets('Navigation app shows home and navigates to active route screen', (WidgetTester tester) async {
    // Build the app with the BLoC provider
    await tester.pumpWidget(
      BlocProvider<AppStateBloc>(
        create: (_) => AppStateBloc(),
        child: const MaterialApp(
          home: HomeScreen()
        ),
      ),
    );

    // Verify home screen shows a button to navigate
    expect(find.text('Navigate to Central Park'), findsOneWidget);

    // Tap the navigation button
    await tester.tap(find.text('Navigate to Central Park'));
    await tester.pumpAndSettle(); // wait for navigation

    // Expect something from the next screen (e.g. turn-by-turn)
    expect(find.text('Turn left in 200m...'), findsOneWidget); // or use `ActiveRouteScreen` text
  });
}
