import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:awe/core/sensor_service.dart';

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
}
