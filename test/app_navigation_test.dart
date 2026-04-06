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
      await tester.pump(); // prefs loaded → SplashScreen

      expect(find.byType(SplashScreen), findsOneWidget);

      // Drain splash timer → navigates to ExperienceScreen
      await tester.pump(const Duration(seconds: 3));
      // Drain ExperienceScreen video init (fails on stub asset → calls completion → navigates to HubScreen)
      for (int i = 0; i < 10; i++) {
        await tester.pump(Duration.zero);
      }
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

    testWidgets('initial loading shows MaterialApp', (tester) async {
      await tester.pumpWidget(const AweApp());

      expect(find.byType(MaterialApp), findsOneWidget);

      // Clean up pending timers
      await tester.pump();
      await tester.pump();
      if (tester.any(find.byType(SplashScreen))) {
        await tester.pump(const Duration(seconds: 3));
        for (int i = 0; i < 10; i++) {
          await tester.pump(Duration.zero);
        }
      }
    });
  });
}
