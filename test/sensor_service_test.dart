import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:awe/core/sensor_service.dart';
import 'package:awe/core/audio_engine.dart';
import 'package:awe/screens/cosmic_awe_screen.dart';
import 'fakes.dart';

void main() {
  group('FakeSensorService', () {
    test('emits gyroscope events', () async {
      final fake = FakeSensorService();
      final events = <GyroscopeEvent>[];

      final subscription = fake.gyroscopeStream.listen(events.add);

      fake.emit(1.0, 2.0, 3.0);
      fake.emit(0.5, -0.5, 0.0);

      await Future.delayed(Duration.zero);

      expect(events.length, equals(2));
      expect(events[0].x, closeTo(1.0, 0.001));
      expect(events[0].y, closeTo(2.0, 0.001));
      expect(events[1].x, closeTo(0.5, 0.001));

      await subscription.cancel();
      fake.dispose();
    });

    test('dispose closes stream', () async {
      final fake = FakeSensorService();
      bool streamDone = false;

      fake.gyroscopeStream.listen(
        (_) {},
        onDone: () => streamDone = true,
      );

      fake.dispose();
      await Future.delayed(Duration.zero);

      expect(streamDone, isTrue);
    });

    test('is a SensorService', () {
      final fake = FakeSensorService();
      expect(fake, isA<SensorService>());
      fake.dispose();
    });
  });

  group('CosmicAweScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders without crash using FakeSensorService', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final sensorService = FakeSensorService();

      await tester.pumpWidget(MaterialApp(
        home: CosmicAweScreen(
          audioEngine: engine,
          sensorService: sensorService,
        ),
      ));

      expect(find.byType(CosmicAweScreen), findsOneWidget);
      sensorService.dispose();
    });

    testWidgets('has black background', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final sensorService = FakeSensorService();

      await tester.pumpWidget(MaterialApp(
        home: CosmicAweScreen(
          audioEngine: engine,
          sensorService: sensorService,
        ),
      ));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.black));
      sensorService.dispose();
    });

    testWidgets('has back button', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final sensorService = FakeSensorService();

      await tester.pumpWidget(MaterialApp(
        home: CosmicAweScreen(
          audioEngine: engine,
          sensorService: sensorService,
        ),
      ));

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      sensorService.dispose();
    });

    testWidgets('responds to gyroscope events', (tester) async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      final sensorService = FakeSensorService();

      await tester.pumpWidget(MaterialApp(
        home: CosmicAweScreen(
          audioEngine: engine,
          sensorService: sensorService,
        ),
      ));

      // Emit gyro event and verify widget rebuilds without crash
      sensorService.emit(0.1, 0.2, 0.0);
      await tester.pump(Duration.zero);

      expect(find.byType(CosmicAweScreen), findsOneWidget);
      sensorService.dispose();
    });
  });
}
