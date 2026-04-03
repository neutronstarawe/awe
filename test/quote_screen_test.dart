import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awe/core/audio_engine.dart';
import 'package:awe/core/app_preferences.dart';
import 'package:awe/screens/quote_screen.dart';
import 'fakes.dart';

void main() {
  group('QuoteScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders Carl Sagan quote text', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();

      await tester.pumpWidget(MaterialApp(
        home: QuoteScreen(
          audioEngine: engine,
          preferences: prefs,
          quoteDuration: Duration.zero,
          onComplete: () {},
        ),
      ));

      await tester.pump(Duration.zero);

      // The quote should contain key words
      expect(find.textContaining('dot'), findsOneWidget);
    });

    testWidgets('renders attribution', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();

      await tester.pumpWidget(MaterialApp(
        home: QuoteScreen(
          audioEngine: engine,
          preferences: prefs,
          quoteDuration: Duration.zero,
          onComplete: () {},
        ),
      ));

      await tester.pump(Duration.zero);

      expect(find.textContaining('Sagan'), findsOneWidget);
    });

    testWidgets('has black background', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();

      await tester.pumpWidget(MaterialApp(
        home: QuoteScreen(
          audioEngine: engine,
          preferences: prefs,
          quoteDuration: Duration.zero,
          onComplete: () {},
        ),
      ));

      await tester.pump(Duration.zero);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.black));
    });

    testWidgets('calls onComplete after quoteDuration', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();
      bool completed = false;

      await tester.pumpWidget(MaterialApp(
        home: QuoteScreen(
          audioEngine: engine,
          preferences: prefs,
          quoteDuration: Duration.zero,
          onComplete: () => completed = true,
        ),
      ));

      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);

      expect(completed, isTrue);
    });

    testWidgets('sets hasSeenIntro=true before calling onComplete',
        (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();
      await prefs.init();
      bool completed = false;

      await tester.pumpWidget(MaterialApp(
        home: QuoteScreen(
          audioEngine: engine,
          preferences: prefs,
          quoteDuration: Duration.zero,
          onComplete: () => completed = true,
        ),
      ));

      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);

      expect(completed, isTrue);
      expect(await prefs.hasSeenIntro, isTrue);
    });
  });
}
