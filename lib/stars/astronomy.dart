import 'dart:math';

/// Julian Date for the given UTC instant.
double julianDate(DateTime utc) {
  var y = utc.year;
  var m = utc.month;
  final d = utc.day +
      (utc.hour + utc.minute / 60.0 + utc.second / 3600.0) / 24.0;
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  final a = y ~/ 100;
  final b = 2 - a + a ~/ 4;
  return (365.25 * (y + 4716)).floor() +
      (30.6001 * (m + 1)).floor() +
      d +
      b -
      1524.5;
}

/// Local Sidereal Time in radians.
/// [longitudeRad]: observer longitude, positive East.
double localSiderealTime(double longitudeRad, DateTime utc) {
  final jd = julianDate(utc);
  final t = (jd - 2451545.0) / 36525.0;
  // GMST in radians (IAU formula)
  final gmst = 4.894961213 +
      6.300388099 * (jd - 2451545.0) +
      t * t * (6.77e-6 - t * 4.5e-10);
  return (gmst + longitudeRad) % (2 * pi);
}

/// Converts equatorial (RA/Dec) to horizontal (Alt/Az) coordinates.
///
/// All angles in radians.
/// [ra]: right ascension.
/// [dec]: declination.
/// [latRad]: observer geodetic latitude, positive North.
/// [lst]: local sidereal time.
///
/// Returns (altitude, azimuth).
/// altitude: 0 = horizon, π/2 = zenith.
/// azimuth: 0 = North, π/2 = East (measured clockwise).
(double alt, double az) raDecToAltAz({
  required double ra,
  required double dec,
  required double latRad,
  required double lst,
}) {
  final ha = lst - ra; // hour angle

  final sinAlt =
      sin(dec) * sin(latRad) + cos(dec) * cos(latRad) * cos(ha);
  final alt = asin(sinAlt.clamp(-1.0, 1.0));

  final cosAlt = cos(alt);
  if (cosAlt.abs() < 1e-10) {
    // At zenith or nadir — azimuth is undefined, return 0
    return (alt, 0.0);
  }

  final cosAz =
      (sin(dec) - sin(alt) * sin(latRad)) / (cosAlt * cos(latRad));
  var az = acos(cosAz.clamp(-1.0, 1.0));
  // Quadrant correction: if hour angle is positive (star west of meridian),
  // azimuth is in western half (180°–360°).
  if (sin(ha) > 0) az = 2 * pi - az;

  return (alt, az);
}
