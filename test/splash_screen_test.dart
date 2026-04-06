import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awe/core/app_preferences.dart';
import 'package:awe/screens/splash_screen.dart';
import 'package:awe/screens/experience_screen.dart';

void main() {
  group('SplashScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders "awe" text', (tester) async {
      final prefs = AppPreferences();
      await prefs.init();

      await tester.pumpWidget(MaterialApp(
        home: SplashScreen(
          preferences: prefs,
          splashDuration: Duration.zero,
          onComplete: () {},
        ),
      ));
      await tester.pump(Duration.zero);

      expect(find.text('awe'), findsOneWidget);
    });

    testWidgets('has black background', (tester) async {
      final prefs = AppPreferences();
      await prefs.init();

      await tester.pumpWidget(MaterialApp(
        home: SplashScreen(
          preferences: prefs,
          splashDuration: Duration.zero,
          onComplete: () {},
        ),
      ));
      await tester.pump(Duration.zero);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.black));
    });

    testWidgets('calls onComplete after splashDuration elapses', (tester) async {
      final prefs = AppPreferences();
      await prefs.init();
      bool completed = false;

      await tester.pumpWidget(MaterialApp(
        home: SplashScreen(
          preferences: prefs,
          splashDuration: Duration.zero,
          onComplete: () => completed = true,
        ),
      ));

      await tester.pump(Duration.zero);
      await tester.pump();

      expect(completed, isTrue);
    });

    testWidgets('navigates to ExperienceScreen when onComplete is not provided',
        (tester) async {
      final prefs = AppPreferences();
      await prefs.init();

      await tester.pumpWidget(MaterialApp(
        home: SplashScreen(
          preferences: prefs,
          splashDuration: Duration.zero,
        ),
      ));

      await tester.pump(Duration.zero);
      await tester.pump();

      expect(find.byType(ExperienceScreen), findsOneWidget);

      // Drain ExperienceScreen video init (fails on stub asset, calls onComplete = null → navigates)
      for (int i = 0; i < 10; i++) {
        await tester.pump(Duration.zero);
      }
    });
  });
}
