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
///
/// Applies an exponential moving average (EMA) to both axes to eliminate
/// sensor noise. Near zenith (altitude > 75°) azimuth is frozen because
/// the compass becomes unreliable when the phone is nearly horizontal.
class RealSkyOrientationSource implements SkyOrientationSource {
  /// Smoothing factor: fraction of new reading blended in each update.
  /// Lower = smoother but more lag. 0.10 is a good balance.
  static const double _alpha = 0.10;

  /// Altitude above which azimuth is frozen (compass unreliable near zenith).
  static const double _zenithLockAlt = 75 * pi / 180;

  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  final _controller = StreamController<SkyOrientation>.broadcast();

  double? _rawAz;
  double? _rawAlt;
  double? _smoothAz;
  double? _smoothAlt;

  RealSkyOrientationSource() {
    _compassSub = FlutterCompass.events?.listen((e) {
      _rawAz = (e.heading ?? 0) * pi / 180;
      _tryEmit();
    });
    _accelSub = accelerometerEventStream().listen((e) {
      _rawAlt = SkyOrientation.altitudeFromAccel(ax: e.x, ay: e.y, az: e.z);
      _tryEmit();
    });
  }

  void _tryEmit() {
    final rawAz = _rawAz;
    final rawAlt = _rawAlt;
    if (rawAz == null || rawAlt == null) return;

    if (_smoothAz == null) {
      // First reading — initialise without blending
      _smoothAz = rawAz;
      _smoothAlt = rawAlt;
    } else {
      // Smooth altitude with EMA
      _smoothAlt = _smoothAlt! + _alpha * (rawAlt - _smoothAlt!);

      // Freeze azimuth near zenith — compass is unreliable face-up
      if ((_smoothAlt ?? 0) < _zenithLockAlt) {
        _smoothAz = _smoothAngle(_smoothAz!, rawAz, _alpha);
      }
    }

    _controller.add(SkyOrientation(
      azimuth: _smoothAz!,
      altitude: _smoothAlt!,
    ));
  }

  /// EMA for angles, handling the 0/2π wrap-around.
  static double _smoothAngle(double prev, double next, double alpha) {
    var diff = next - prev;
    if (diff > pi) diff -= 2 * pi;
    if (diff < -pi) diff += 2 * pi;
    return (prev + alpha * diff) % (2 * pi);
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
