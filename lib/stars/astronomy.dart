import 'dart:math';

// ─── Vec3 ────────────────────────────────────────────────────────────────────

/// Immutable 3-component double-precision vector.
class Vec3 {
  final double x, y, z;

  const Vec3(this.x, this.y, this.z);

  static const zero  = Vec3(0, 0, 0);
  static const unitX = Vec3(1, 0, 0);
  static const unitY = Vec3(0, 1, 0);
  static const unitZ = Vec3(0, 0, 1);

  double get length2 => x * x + y * y + z * z;
  double get length  => sqrt(length2);

  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);
  Vec3 operator -() => Vec3(-x, -y, -z);

  double dot(Vec3 o) => x * o.x + y * o.y + z * o.z;

  Vec3 cross(Vec3 o) => Vec3(
    y * o.z - z * o.y,
    z * o.x - x * o.z,
    x * o.y - y * o.x,
  );

  Vec3 normalized() {
    final l = length;
    if (l < 1e-10) return unitZ;
    return Vec3(x / l, y / l, z / l);
  }

  @override
  String toString() => 'Vec3($x, $y, $z)';
}

// ─── Mat3 ────────────────────────────────────────────────────────────────────

/// Row-major 3×3 matrix.
class Mat3 {
  final double xx, xy, xz;
  final double yx, yy, yz;
  final double zx, zy, zz;

  const Mat3(
    this.xx, this.xy, this.xz,
    this.yx, this.yy, this.yz,
    this.zx, this.zy, this.zz,
  );

  static const identity = Mat3(1, 0, 0,  0, 1, 0,  0, 0, 1);

  /// Build from three column vectors.
  factory Mat3.fromColumns(Vec3 c0, Vec3 c1, Vec3 c2) => Mat3(
    c0.x, c1.x, c2.x,
    c0.y, c1.y, c2.y,
    c0.z, c1.z, c2.z,
  );

  /// Build from three row vectors (transpose of column form).
  factory Mat3.fromRows(Vec3 r0, Vec3 r1, Vec3 r2) => Mat3(
    r0.x, r0.y, r0.z,
    r1.x, r1.y, r1.z,
    r2.x, r2.y, r2.z,
  );

  Vec3 operator *(Vec3 v) => Vec3(
    xx * v.x + xy * v.y + xz * v.z,
    yx * v.x + yy * v.y + yz * v.z,
    zx * v.x + zy * v.y + zz * v.z,
  );

  Mat3 matMul(Mat3 m) => Mat3(
    xx*m.xx + xy*m.yx + xz*m.zx,  xx*m.xy + xy*m.yy + xz*m.zy,  xx*m.xz + xy*m.yz + xz*m.zz,
    yx*m.xx + yy*m.yx + yz*m.zx,  yx*m.xy + yy*m.yy + yz*m.zy,  yx*m.xz + yy*m.yz + yz*m.zz,
    zx*m.xx + zy*m.yx + zz*m.zx,  zx*m.xy + zy*m.yy + zz*m.zy,  zx*m.xz + zy*m.yz + zz*m.zz,
  );
}

// ─── Astronomical math ───────────────────────────────────────────────────────

/// Julian Date for the given UTC instant.
double julianDate(DateTime utc) {
  var y = utc.year;
  var m = utc.month;
  final d = utc.day +
      (utc.hour + utc.minute / 60.0 + utc.second / 3600.0) / 24.0;
  if (m <= 2) { y -= 1; m += 12; }
  final a = y ~/ 100;
  final b = 2 - a + a ~/ 4;
  return (365.25 * (y + 4716)).floor() +
      (30.6001 * (m + 1)).floor() +
      d + b - 1524.5;
}

/// Local Sidereal Time in radians.
/// [longitudeRad]: observer longitude, positive East.
double localSiderealTime(double longitudeRad, DateTime utc) {
  final jd = julianDate(utc);
  final t  = (jd - 2451545.0) / 36525.0;
  // GMST in radians (IAU formula)
  final gmst = 4.894961213 +
      6.300388099 * (jd - 2451545.0) +
      t * t * (6.77e-6 - t * 4.5e-10);
  return (gmst + longitudeRad) % (2 * pi);
}

/// Converts RA/Dec (both in radians) to a geocentric unit vector.
///
/// Celestial frame axes:
///   x = (RA=0, Dec=0)   — vernal equinox direction
///   y = (RA=π/2, Dec=0)
///   z = (Dec=π/2)       — Earth's north pole
Vec3 raDecToVec(double ra, double dec) => Vec3(
  cos(ra) * cos(dec),
  sin(ra) * cos(dec),
  sin(dec),
);

/// Geocentric unit vector pointing at the observer's zenith.
/// Zenith: RA = LST, Dec = observer latitude.
Vec3 zenithVector(double latRad, double lst) => raDecToVec(lst, latRad);

/// Rodrigues rotation matrix: rotates [angle] radians around unit [axis].
Mat3 rotationAround(Vec3 axis, double angle) {
  final c = cos(angle), s = sin(angle), t = 1.0 - c;
  final Vec3(:x, :y, :z) = axis.normalized();
  return Mat3(
    t*x*x + c,    t*x*y - s*z,  t*x*z + s*y,
    t*x*y + s*z,  t*y*y + c,    t*y*z - s*x,
    t*x*z - s*y,  t*y*z + s*x,  t*z*z + c,
  );
}
