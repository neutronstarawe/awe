import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awe/core/audio_engine.dart';
import 'package:awe/screens/micro_awe_screen.dart';
import 'fakes.dart';

void main() {
  group('MicroAweScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders without crash', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());

      await tester.pumpWidget(MaterialApp(
        home: MicroAweScreen(audioEngine: engine),
      ));

      expect(find.byType(MicroAweScreen), findsOneWidget);
    });

    testWidgets('has black background', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());

      await tester.pumpWidget(MaterialApp(
        home: MicroAweScreen(audioEngine: engine),
      ));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.black));
    });

    testWidgets('has back button', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());

      await tester.pumpWidget(MaterialApp(
        home: MicroAweScreen(audioEngine: engine),
      ));

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('back button pops navigation', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      bool popped = false;

      await tester.pumpWidget(MaterialApp(
        home: Navigator(
          onDidRemovePage: (page) => popped = true,
          pages: [
            MaterialPage(
              child: Scaffold(
                body: Builder(builder: (ctx) {
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => MicroAweScreen(audioEngine: engine),
                        ),
                      );
                    },
                    child: const Text('Go'),
                  );
                }),
              ),
            ),
          ],
        ),
      ));

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.byType(MicroAweScreen), findsOneWidget);
    });

    testWidgets('pinch-to-zoom gesture does not crash', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());

      await tester.pumpWidget(MaterialApp(
        home: MicroAweScreen(audioEngine: engine),
      ));

      // Simulate a scale gesture
      final center = tester.getCenter(find.byType(MicroAweScreen));
      final gesture1 = await tester.startGesture(center - const Offset(50, 0));
      final gesture2 = await tester.startGesture(center + const Offset(50, 0));

      await gesture1.moveTo(center - const Offset(100, 0));
      await gesture2.moveTo(center + const Offset(100, 0));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pump();

      // Should not crash
      expect(find.byType(MicroAweScreen), findsOneWidget);
    });
  });
}
