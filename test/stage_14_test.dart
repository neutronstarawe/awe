/// Stage 14: End-to-end integration tests covering the full user journey.
///
/// These tests exercise the complete app flow using the full widget tree.
/// Runs as widget tests (no device required) via `flutter test integration_test/stage_14_test.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awe/app.dart';
import 'package:awe/screens/splash_screen.dart';
import 'package:awe/screens/hub_screen.dart';
import 'package:awe/screens/micro_awe_screen.dart';
import 'package:awe/screens/cosmic_awe_screen.dart';
import 'package:awe/screens/power_of_nature_screen.dart';
import 'package:awe/core/app_preferences.dart';

void main() {
  group('Stage 14: End-to-end user journey', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Scenario 1: First launch shows SplashScreen', (tester) async {
      SharedPreferences.setMockInitialValues({'has_seen_intro': false});

      await tester.pumpWidget(const AweApp());
      await tester.pump();
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('awe'), findsOneWidget);

      // Drain the default 2s splash timer
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(Duration.zero);
    });

    testWidgets('Scenario 2: Returning user goes directly to HubScreen',
        (tester) async {
      SharedPreferences.setMockInitialValues({'has_seen_intro': true});

      await tester.pumpWidget(const AweApp());
      await tester.pump();
      await tester.pump();

      expect(find.byType(HubScreen), findsOneWidget);
      expect(find.text('awe'), findsOneWidget);
      expect(find.text('Micro Awe'), findsOneWidget);
      expect(find.text('Cosmic Awe'), findsOneWidget);
      expect(find.text('Power of Nature'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('Scenario 3: Hub → Micro Awe → back to Hub', (tester) async {
      SharedPreferences.setMockInitialValues({'has_seen_intro': true});

      await tester.pumpWidget(const AweApp());
      await tester.pump();
      await tester.pump();

      expect(find.byType(HubScreen), findsOneWidget);

      await tester.tap(find.text('Micro Awe'));
      await tester.pumpAndSettle();

      expect(find.byType(MicroAweScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(HubScreen), findsOneWidget);
    });

    testWidgets('Scenario 4: Hub → Cosmic Awe → back to Hub', (tester) async {
      SharedPreferences.setMockInitialValues({'has_seen_intro': true});

      await tester.pumpWidget(const AweApp());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Cosmic Awe'));
      await tester.pumpAndSettle();

      expect(find.byType(CosmicAweScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(HubScreen), findsOneWidget);
    });

    testWidgets('Scenario 5: Hub → Power of Nature → back to Hub',
        (tester) async {
      SharedPreferences.setMockInitialValues({'has_seen_intro': true});

      await tester.pumpWidget(const AweApp());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Power of Nature'));
      await tester.pumpAndSettle();

      expect(find.byType(PowerOfNatureScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(HubScreen), findsOneWidget);
    });

    testWidgets('Scenario 6: Reset replays intro from HubScreen', (tester) async {
      SharedPreferences.setMockInitialValues({'has_seen_intro': true});
      final prefs = AppPreferences();

      await tester.pumpWidget(AweApp(preferences: prefs));
      await tester.pump();
      await tester.pump();

      expect(find.byType(HubScreen), findsOneWidget);

      await tester.tap(find.text('Reset'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(await prefs.hasSeenIntro, isFalse);
      expect(await prefs.montageIndex, equals(0));

      // Drain splash timer
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(Duration.zero);
    });

    testWidgets('Scenario 7: AppPreferences hasSeenIntro persists',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = AppPreferences();
      await prefs.init();

      expect(await prefs.hasSeenIntro, isFalse);
      await prefs.setHasSeenIntro(true);
      expect(await prefs.hasSeenIntro, isTrue);

      final prefs2 = AppPreferences();
      await prefs2.init();
      expect(await prefs2.hasSeenIntro, isTrue);
    });

    testWidgets('Scenario 8: Multi-screen navigation without crash',
        (tester) async {
      SharedPreferences.setMockInitialValues({'has_seen_intro': true});

      await tester.pumpWidget(const AweApp());
      await tester.pump();
      await tester.pump();

      // Micro Awe
      await tester.tap(find.text('Micro Awe'));
      await tester.pumpAndSettle();
      expect(find.byType(MicroAweScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Cosmic Awe
      await tester.tap(find.text('Cosmic Awe'));
      await tester.pumpAndSettle();
      expect(find.byType(CosmicAweScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Power of Nature
      await tester.tap(find.text('Power of Nature'));
      await tester.pumpAndSettle();
      expect(find.byType(PowerOfNatureScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(HubScreen), findsOneWidget);
    });
  });
}
