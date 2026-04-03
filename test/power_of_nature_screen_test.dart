import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awe/core/audio_engine.dart';
import 'package:awe/screens/power_of_nature_screen.dart';
import 'fakes.dart';

void main() {
  group('PowerOfNatureScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders without crash', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());

      await tester.pumpWidget(MaterialApp(
        home: PowerOfNatureScreen(audioEngine: engine),
      ));

      expect(find.byType(PowerOfNatureScreen), findsOneWidget);
    });

    testWidgets('has black background', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());

      await tester.pumpWidget(MaterialApp(
        home: PowerOfNatureScreen(audioEngine: engine),
      ));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.black));
    });

    testWidgets('has back button', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());

      await tester.pumpWidget(MaterialApp(
        home: PowerOfNatureScreen(audioEngine: engine),
      ));

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('has scrollable list', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());

      await tester.pumpWidget(MaterialApp(
        home: PowerOfNatureScreen(audioEngine: engine),
      ));

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('scroll gesture does not crash', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());

      await tester.pumpWidget(MaterialApp(
        home: PowerOfNatureScreen(audioEngine: engine),
      ));

      await tester.drag(
          find.byType(ListView), const Offset(0, -200));
      await tester.pump();

      expect(find.byType(PowerOfNatureScreen), findsOneWidget);
    });
  });
}
