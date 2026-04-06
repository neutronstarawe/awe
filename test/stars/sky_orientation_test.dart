import 'dart:async';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:awe/stars/sky_orientation.dart';

void main() {
  group('SkyOrientation value', () {
    test('stores azimuth and altitude', () {
      const o = SkyOrientation(azimuth: 1.2, altitude: 0.5);
      expect(o.azimuth, 1.2);
      expect(o.altitude, 0.5);
    });
  });

  group('FakeSkyOrientationSource', () {
    test('emits values pushed via emit()', () async {
      final source = FakeSkyOrientationSource();
      const expected = SkyOrientation(azimuth: 0.3, altitude: 0.8);

      final emitted = <SkyOrientation>[];
      final sub = source.stream.listen(emitted.add);
      source.emit(expected);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      source.dispose();

      expect(emitted.length, 1);
      expect(emitted.first.azimuth, expected.azimuth);
      expect(emitted.first.altitude, expected.altitude);
    });

    test('altitude from phone face-up accel (z≈+9.8) is ~90°', () {
      // When accelerometer z ≈ +9.8 (face-up), altitude should be ≈ π/2
      final alt = SkyOrientation.altitudeFromAccel(ax: 0, ay: 0, az: 9.8);
      expect(alt, closeTo(pi / 2, 0.05));
    });

    test('altitude from phone upright (z≈0) is ~0°', () {
      final alt = SkyOrientation.altitudeFromAccel(ax: 0, ay: -9.8, az: 0);
      expect(alt, closeTo(0.0, 0.05));
    });

    test('altitude from phone face-down (z≈-9.8) is ~-90°', () {
      final alt = SkyOrientation.altitudeFromAccel(ax: 0, ay: 0, az: -9.8);
      expect(alt, closeTo(-pi / 2, 0.05));
    });
  });
}
