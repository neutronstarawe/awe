import 'dart:async';
import 'dart:math';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Represents where the phone camera is pointing in the sky.
class SkyOrientation {
  /// Compass bearing in radians (0=North, π/2=East, π=South, 3π/2=West).
  final double azimuth;

  /// Altitude above horizon in radians (0=horizon, π/2=zenith).
  final double altitude;

  const SkyOrientation({required this.azimuth, required this.altitude});

  /// Computes altitude from raw accelerometer values (m/s²).
  /// Face-up (z≈+9.81) → altitude ≈ π/2 (zenith).
  /// Upright (z≈0, y≈-9.81) → altitude ≈ 0 (horizon).
  static double altitudeFromAccel({
    required double ax,
    required double ay,
    required double az,
  }) {
    const g = 9.81;
    return asin((az / g).clamp(-1.0, 1.0));
  }
}

/// Abstract source — allows injection of a fake in tests.
abstract class SkyOrientationSource {
  Stream<SkyOrientation> get stream;
  void dispose();
}

/// Fake implementation for widget tests.
class FakeSkyOrientationSource implements SkyOrientationSource {
  final _controller = StreamController<SkyOrientation>.broadcast();

  void emit(SkyOrientation o) => _controller.add(o);

  @override
  Stream<SkyOrientation> get stream => _controller.stream;

  @override
  void dispose() => _controller.close();
}

/// Production implementation combining flutter_compass + accelerometer.
class RealSkyOrientationSource implements SkyOrientationSource {
  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  final _controller = StreamController<SkyOrientation>.broadcast();

  double? _azimuth;
  double? _altitude;

  RealSkyOrientationSource() {
    _compassSub = FlutterCompass.events?.listen((e) {
      _azimuth = (e.heading ?? 0) * pi / 180;
      _tryEmit();
    });
    _accelSub = accelerometerEventStream().listen((e) {
      _altitude = SkyOrientation.altitudeFromAccel(ax: e.x, ay: e.y, az: e.z);
      _tryEmit();
    });
  }

  void _tryEmit() {
    final az = _azimuth;
    final alt = _altitude;
    if (az != null && alt != null) {
      _controller.add(SkyOrientation(azimuth: az, altitude: alt));
    }
  }

  @override
  Stream<SkyOrientation> get stream => _controller.stream;

  @override
  void dispose() {
    _compassSub?.cancel();
    _accelSub?.cancel();
    _controller.close();
  }
}
