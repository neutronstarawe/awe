import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'astronomy.dart';

/// Where the phone is pointing, expressed as two orthonormal unit vectors
/// in the celestial coordinate frame (x=RA0/Dec0, y=RA90/Dec0, z=north pole).
class PhonePointing {
  /// Direction the phone screen faces, in celestial coords.
  final Vec3 lineOfSight;

  /// "Up" direction on the screen, in celestial coords.
  final Vec3 screenUp;

  const PhonePointing({required this.lineOfSight, required this.screenUp});

  /// Default: phone pointing toward the vernal equinox on the horizon.
  static const defaultPointing = PhonePointing(
    lineOfSight: Vec3(1, 0, 0),
    screenUp: Vec3(0, 0, 1),
  );
}

// ─── Abstract source ─────────────────────────────────────────────────────────

abstract class SkyOrientationSource {
  Stream<PhonePointing> get stream;
  void setLocation(double latRad, double lngRad);
  void dispose();
}

// ─── Fake (for tests) ────────────────────────────────────────────────────────

class FakeSkyOrientationSource implements SkyOrientationSource {
  final _controller = StreamController<PhonePointing>.broadcast();

  void emit(PhonePointing p) => _controller.add(p);

  @override
  Stream<PhonePointing> get stream => _controller.stream;

  @override
  void setLocation(double latRad, double lngRad) {}

  @override
  void dispose() => _controller.close();
}

// ─── Real (stardroid-style matrix sensor fusion) ─────────────────────────────

/// Production orientation source, based on the approach used by Google Sky Map
/// (sky-map-team/stardroid, Apache 2.0).
///
/// Algorithm:
///   1. Accelerometer → "up" direction in phone space (gravity is down).
///   2. Magnetometer → magnetic north on the horizontal plane (vector rejection).
///   3. Both give an orthonormal basis for phone space: [north, up, east].
///      The inverse of that matrix (= its transpose, since it's orthonormal)
///      maps phone coords → a "neutral" frame aligned with magnetic north.
///   4. From the observer's GPS position + current LST we compute the same
///      [north, up, east] basis in the celestial frame, corrected for magnetic
///      declination.
///   5. Multiplying: axesCelestial × axesPhoneInverse gives the full
///      phone-space → celestial-space transform.
///   6. Apply to the phone's canonical forward/up vectors to get PhonePointing.
///
/// This approach handles all phone orientations without gimbal lock and does
/// not require a separate compass package.
class RealSkyOrientationSource implements SkyOrientationSource {
  /// EMA smoothing factors. Lower = smoother but more lag.
  static const double _accelAlpha = 0.12;
  static const double _magAlpha   = 0.12;

  double _latRad = 0;
  double _lngRad = 0;

  /// Magnetic declination (true − magnetic north) in radians.
  /// Defaults to 0. Set via [setDeclination] for better accuracy.
  double _declination = 0;

  Vec3? _smoothAccel;
  Vec3? _smoothMag;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<MagnetometerEvent>?  _magSub;

  final _controller = StreamController<PhonePointing>.broadcast();

  RealSkyOrientationSource() {
    _accelSub = accelerometerEventStream().listen(_onAccel);
    _magSub   = magnetometerEventStream().listen(_onMag);
  }

  @override
  void setLocation(double latRad, double lngRad) {
    _latRad = latRad;
    _lngRad = lngRad;
  }

  void setDeclination(double radians) => _declination = radians;

  void _onAccel(AccelerometerEvent e) {
    final raw = Vec3(e.x, e.y, e.z);
    _smoothAccel = _smoothAccel == null ? raw : _emaVec(_smoothAccel!, raw, _accelAlpha);
    _tryEmit();
  }

  void _onMag(MagnetometerEvent e) {
    final raw = Vec3(e.x, e.y, e.z);
    _smoothMag = _smoothMag == null ? raw : _emaVec(_smoothMag!, raw, _magAlpha);
    _tryEmit();
  }

  void _tryEmit() {
    final accel = _smoothAccel;
    final mag   = _smoothMag;
    if (accel == null || mag == null) return;
    if (accel.length2 < 0.01 || mag.length2 < 0.01) return;

    _controller.add(_computePointing(accel, mag));
  }

  PhonePointing _computePointing(Vec3 accel, Vec3 mag) {
    // ── Phone-space orthonormal basis ────────────────────────────────────────
    // Accelerometer reads apparent gravity (points opposite to gravitational
    // acceleration), so negating gives "up" in phone space.
    final upPhone    = (-accel).normalized();
    final magNorm    = mag.normalized();
    // Project magnetometer onto the horizontal plane to get magnetic north.
    final northPhone = (magNorm - upPhone * magNorm.dot(upPhone)).normalized();
    final eastPhone  = northPhone.cross(upPhone).normalized();

    // The phone basis is orthonormal, so its inverse is its transpose.
    // Construct as row vectors = transpose of column form.
    final axesPhoneInv = Mat3.fromRows(northPhone, upPhone, eastPhone);

    // ── Celestial-space orthonormal basis ────────────────────────────────────
    final lst         = localSiderealTime(_lngRad, DateTime.now().toUtc());
    final upCelestial = zenithVector(_latRad, lst);

    // True north: project Earth's rotation axis (z) onto the plane ⊥ zenith.
    const earthPole      = Vec3.unitZ;
    final trueNorth      = (earthPole - upCelestial * earthPole.dot(upCelestial)).normalized();

    // Rotate true north around zenith by magnetic declination.
    final magNorthCelestial = _declination == 0
        ? trueNorth
        : (rotationAround(upCelestial, _declination) * trueNorth).normalized();
    final magEastCelestial  = magNorthCelestial.cross(upCelestial).normalized();

    // Column vectors: [magNorth | up | magEast]
    final axesCelestial = Mat3.fromColumns(
        magNorthCelestial, upCelestial, magEastCelestial);

    // ── Phone → celestial transform ──────────────────────────────────────────
    final transform = axesCelestial.matMul(axesPhoneInv);

    // Phone canonical axes: screen faces −z, long axis is +y.
    return PhonePointing(
      lineOfSight: (transform * const Vec3(0, 0, -1)).normalized(),
      screenUp:    (transform * const Vec3(0, 1,  0)).normalized(),
    );
  }

  static Vec3 _emaVec(Vec3 prev, Vec3 next, double alpha) => Vec3(
    prev.x + alpha * (next.x - prev.x),
    prev.y + alpha * (next.y - prev.y),
    prev.z + alpha * (next.z - prev.z),
  );

  @override
  Stream<PhonePointing> get stream => _controller.stream;

  @override
  void dispose() {
    _accelSub?.cancel();
    _magSub?.cancel();
    _controller.close();
  }
}
