import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awe/core/app_preferences.dart';
import 'package:awe/screens/experience_screen.dart';

void main() {
  group('ExperienceScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders without crash', (tester) async {
      final prefs = AppPreferences();
      await prefs.init();

      await tester.pumpWidget(MaterialApp(
        home: ExperienceScreen(
          preferences: prefs,
          onVideoComplete: () {},
        ),
      ));

      expect(find.byType(ExperienceScreen), findsOneWidget);
    });

    testWidgets('has black background', (tester) async {
      final prefs = AppPreferences();
      await prefs.init();

      await tester.pumpWidget(MaterialApp(
        home: ExperienceScreen(
          preferences: prefs,
          onVideoComplete: () {},
        ),
      ));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.black));
    });

    testWidgets('shows CircularProgressIndicator while loading', (tester) async {
      final prefs = AppPreferences();
      await prefs.init();

      await tester.pumpWidget(MaterialApp(
        home: ExperienceScreen(
          preferences: prefs,
          onVideoComplete: () {},
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('calls onVideoComplete when video fails to load', (tester) async {
      final prefs = AppPreferences();
      await prefs.init();
      bool completed = false;

      await tester.pumpWidget(MaterialApp(
        home: ExperienceScreen(
          preferences: prefs,
          onVideoComplete: () => completed = true,
        ),
      ));

      // Pump to let async init run and fail (stub asset in test environment)
      for (int i = 0; i < 10; i++) {
        await tester.pump(Duration.zero);
      }

      expect(completed, isTrue);
    });
  });
}
