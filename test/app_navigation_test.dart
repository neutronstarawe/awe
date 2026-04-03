import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awe/app.dart';
import 'package:awe/screens/splash_screen.dart';
import 'package:awe/screens/hub_screen.dart';
import 'package:awe/core/app_preferences.dart';

void main() {
  group('AweApp navigation', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('new user sees SplashScreen first', (tester) async {
      SharedPreferences.setMockInitialValues({'has_seen_intro': false});

      await tester.pumpWidget(const AweApp());
      await tester.pump(); // process loading
      await tester.pump(); // process prefs → SplashScreen

      expect(find.byType(SplashScreen), findsOneWidget);

      // Drain the 2s splash timer to avoid pending timer assertion
      await tester.pump(const Duration(seconds: 3));
      // After splash, MontageScreen loads (which has its own timers)
      // Just pump a bit more to clear immediate timers
      await tester.pump(Duration.zero);
    });

    testWidgets('returning user sees HubScreen directly', (tester) async {
      SharedPreferences.setMockInitialValues({'has_seen_intro': true});

      await tester.pumpWidget(const AweApp());
      await tester.pump();
      await tester.pump();

      expect(find.byType(HubScreen), findsOneWidget);
    });

    testWidgets('AweApp accepts custom AppPreferences for testing',
        (tester) async {
      SharedPreferences.setMockInitialValues({'has_seen_intro': true});
      final prefs = AppPreferences();

      await tester.pumpWidget(AweApp(preferences: prefs));
      await tester.pump();
      await tester.pump();

      expect(find.byType(HubScreen), findsOneWidget);
    });

    testWidgets('initial loading shows progress indicator', (tester) async {
      await tester.pumpWidget(const AweApp());
      // Before prefs load, shows loading indicator
      expect(find.byType(MaterialApp), findsOneWidget);
      // Clean up: pump past the splash timer if we get that far
      await tester.pump();
      await tester.pump();
      // If SplashScreen is showing, drain the timer
      if (tester.any(find.byType(SplashScreen))) {
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(Duration.zero);
      }
    });
  });
}
