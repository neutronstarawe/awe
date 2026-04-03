import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awe/core/audio_engine.dart';
import 'package:awe/core/app_preferences.dart';
import 'package:awe/screens/hub_screen.dart';
import 'package:awe/screens/micro_awe_screen.dart';
import 'package:awe/screens/cosmic_awe_screen.dart';
import 'package:awe/screens/power_of_nature_screen.dart';
import 'package:awe/screens/splash_screen.dart';
import 'fakes.dart';

void main() {
  group('HubScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders all 4 hub tiles', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();

      await tester.pumpWidget(MaterialApp(
        home: HubScreen(audioEngine: engine, preferences: prefs),
      ));

      expect(find.text('Micro Awe'), findsOneWidget);
      expect(find.text('Cosmic Awe'), findsOneWidget);
      expect(find.text('Power of Nature'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('shows "awe" title', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();

      await tester.pumpWidget(MaterialApp(
        home: HubScreen(audioEngine: engine, preferences: prefs),
      ));

      expect(find.text('awe'), findsOneWidget);
    });

    testWidgets('has black background', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();

      await tester.pumpWidget(MaterialApp(
        home: HubScreen(audioEngine: engine, preferences: prefs),
      ));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.black));
    });

    testWidgets('tapping Micro Awe navigates to MicroAweScreen', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();

      await tester.pumpWidget(MaterialApp(
        home: HubScreen(audioEngine: engine, preferences: prefs),
      ));

      await tester.tap(find.text('Micro Awe'));
      await tester.pumpAndSettle();

      expect(find.byType(MicroAweScreen), findsOneWidget);
    });

    testWidgets('tapping Cosmic Awe navigates to CosmicAweScreen',
        (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();

      await tester.pumpWidget(MaterialApp(
        home: HubScreen(audioEngine: engine, preferences: prefs),
      ));

      await tester.tap(find.text('Cosmic Awe'));
      await tester.pumpAndSettle();

      expect(find.byType(CosmicAweScreen), findsOneWidget);
    });

    testWidgets('tapping Power of Nature navigates to PowerOfNatureScreen',
        (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();

      await tester.pumpWidget(MaterialApp(
        home: HubScreen(audioEngine: engine, preferences: prefs),
      ));

      await tester.tap(find.text('Power of Nature'));
      await tester.pumpAndSettle();

      expect(find.byType(PowerOfNatureScreen), findsOneWidget);
    });

    testWidgets('tapping Reset clears hasSeenIntro and navigates to Splash',
        (tester) async {
      SharedPreferences.setMockInitialValues({'has_seen_intro': true});
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();
      await prefs.init();

      await tester.pumpWidget(MaterialApp(
        home: HubScreen(audioEngine: engine, preferences: prefs),
      ));

      await tester.tap(find.text('Reset'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(await prefs.hasSeenIntro, isFalse);

      // Drain splash timer
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(Duration.zero);
    });

    testWidgets('uses 2x2 GridView layout', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final prefs = AppPreferences();

      await tester.pumpWidget(MaterialApp(
        home: HubScreen(audioEngine: engine, preferences: prefs),
      ));

      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
