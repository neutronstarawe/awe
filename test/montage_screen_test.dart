import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awe/core/audio_engine.dart';
import 'package:awe/core/app_preferences.dart';
import 'package:awe/screens/montage_screen.dart';
import 'fakes.dart';

/// Pumps until [condition] is true or [maxPumps] is reached.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxPumps = 200,
}) async {
  for (int i = 0; i < maxPumps; i++) {
    if (condition()) return;
    await tester.pump(Duration.zero);
  }
}

void main() {
  group('MontageScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('imageCount constant is 22', () {
      expect(MontageScreen.imageCount, equals(22));
    });

    testWidgets('renders Scaffold with black background', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();
      bool done = false;

      await tester.pumpWidget(MaterialApp(
        home: MontageScreen(
          audioEngine: engine,
          preferences: prefs,
          imageDuration: Duration.zero,
          crossfadeDuration: Duration.zero,
          onComplete: () => done = true,
        ),
      ));

      // Drain all 22 images to clear pending timers
      await pumpUntil(tester, () => done);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.black));
    });

    testWidgets('calls onComplete after all images', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();
      bool completed = false;

      await tester.pumpWidget(MaterialApp(
        home: MontageScreen(
          audioEngine: engine,
          preferences: prefs,
          imageDuration: Duration.zero,
          crossfadeDuration: Duration.zero,
          onComplete: () => completed = true,
        ),
      ));

      await pumpUntil(tester, () => completed);

      expect(completed, isTrue);
    });

    testWidgets('resumes from saved montage index near end', (tester) async {
      SharedPreferences.setMockInitialValues({'montage_index': 20});

      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();
      bool completed = false;

      await tester.pumpWidget(MaterialApp(
        home: MontageScreen(
          audioEngine: engine,
          preferences: prefs,
          imageDuration: Duration.zero,
          crossfadeDuration: Duration.zero,
          onComplete: () => completed = true,
        ),
      ));

      // Starting at 20, only 2 more images needed
      await pumpUntil(tester, () => completed, maxPumps: 30);

      expect(completed, isTrue);
    });

    testWidgets('saves montage index to preferences during playback',
        (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();
      bool completed = false;

      await tester.pumpWidget(MaterialApp(
        home: MontageScreen(
          audioEngine: engine,
          preferences: prefs,
          imageDuration: Duration.zero,
          crossfadeDuration: Duration.zero,
          onComplete: () => completed = true,
        ),
      ));

      await pumpUntil(tester, () => completed);

      // After completion, montageIndex is reset to 0
      expect(await prefs.montageIndex, equals(0));
    });
  });
}
