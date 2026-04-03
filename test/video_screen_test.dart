import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awe/core/audio_engine.dart';
import 'package:awe/core/app_preferences.dart';
import 'package:awe/screens/video_screen.dart';
import 'fakes.dart';

void main() {
  group('VideoScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders without crash (stub video triggers error path)',
        (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();
      bool completed = false;

      await tester.pumpWidget(MaterialApp(
        home: VideoScreen(
          audioEngine: engine,
          preferences: prefs,
          onComplete: () => completed = true,
        ),
      ));

      // Initial render shows loading indicator
      expect(find.byType(VideoScreen), findsOneWidget);

      // Let the async init run — stub MP4 will fail, triggering onComplete
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);

      // Either loading or completed (stub file fails gracefully)
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });

    testWidgets('shows CircularProgressIndicator while loading', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();

      await tester.pumpWidget(MaterialApp(
        home: VideoScreen(
          audioEngine: engine,
          preferences: prefs,
          onComplete: () {},
        ),
      ));

      // Before async init completes, shows loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('calls onComplete when video fails to load', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();
      bool completed = false;

      await tester.pumpWidget(MaterialApp(
        home: VideoScreen(
          audioEngine: engine,
          preferences: prefs,
          onComplete: () => completed = true,
        ),
      ));

      // Pump to allow async init to run and fail on stub video
      for (int i = 0; i < 10; i++) {
        await tester.pump(Duration.zero);
      }

      // Stub video fails → onComplete fires
      expect(completed, isTrue);
    });

    testWidgets('has black background', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();

      await tester.pumpWidget(MaterialApp(
        home: VideoScreen(
          audioEngine: engine,
          preferences: prefs,
          onComplete: () {},
        ),
      ));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.black));
    });
  });
}
