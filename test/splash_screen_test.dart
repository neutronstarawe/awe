import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awe/core/audio_engine.dart';
import 'package:awe/core/app_preferences.dart';
import 'package:awe/screens/splash_screen.dart';
import 'fakes.dart';

void main() {
  group('SplashScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders "awe" text', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();

      await tester.pumpWidget(MaterialApp(
        home: SplashScreen(
          audioEngine: engine,
          preferences: prefs,
          splashDuration: Duration.zero,
          onComplete: () {}, // prevent navigation, drain timer
        ),
      ));
      await tester.pump(Duration.zero);

      expect(find.text('awe'), findsOneWidget);
    });

    testWidgets('has black background', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();

      await tester.pumpWidget(MaterialApp(
        home: SplashScreen(
          audioEngine: engine,
          preferences: prefs,
          splashDuration: Duration.zero,
          onComplete: () {},
        ),
      ));
      await tester.pump(Duration.zero);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.black));
    });

    testWidgets('calls onComplete after splashDuration elapses',
        (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();
      bool completed = false;

      await tester.pumpWidget(MaterialApp(
        home: SplashScreen(
          audioEngine: engine,
          preferences: prefs,
          splashDuration: Duration.zero,
          onComplete: () => completed = true,
        ),
      ));

      await tester.pump(Duration.zero);
      await tester.pump();

      expect(completed, isTrue);
    });

    testWidgets('onComplete called exactly once', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();
      int completedCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: SplashScreen(
          audioEngine: engine,
          preferences: prefs,
          splashDuration: Duration.zero,
          onComplete: () => completedCount++,
        ),
      ));

      await tester.pump(Duration.zero);
      await tester.pump();

      expect(completedCount, equals(1));
    });
  });
}
