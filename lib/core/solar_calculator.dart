import 'dart:math' as math;

/// NOAA Solar Calculator — returns UTC sunrise/sunset for a given date and
/// coordinates. Returns null when the sun never rises/sets (polar day/night).
class SolarCalculator {
  static DateTime? sunrise(double lat, double lon, DateTime date) =>
      _calc(lat, lon, date, rise: true);

  static DateTime? sunset(double lat, double lon, DateTime date) =>
      _calc(lat, lon, date, rise: false);

  static DateTime? _calc(double lat, double lon, DateTime date,
      {required bool rise}) {
    final jd = _julianDay(date);
    final t = _jcentury(jd);
    final eqTime = _equationOfTime(t);
    final decl = _sunDeclination(t);

    final latR = lat * math.pi / 180;
    final declR = decl * math.pi / 180;

    final cosHA = (math.cos(90.833 * math.pi / 180) /
            (math.cos(latR) * math.cos(declR)) -
        math.tan(latR) * math.tan(declR));

    if (cosHA < -1 || cosHA > 1) return null; // polar day or night

    final ha = math.acos(cosHA) * 180 / math.pi;
    final noon = 720 - 4 * lon - eqTime; // solar noon in minutes from midnight UTC

    final offset = rise ? -ha * 4 : ha * 4;
    final minutesUtc = noon + offset;

    final h = minutesUtc ~/ 60;
    final m = (minutesUtc % 60).round();
    return DateTime.utc(date.year, date.month, date.day, h, m);
  }

  static double _julianDay(DateTime d) {
    final y = d.year;
    final mo = d.month;
    final day = d.day + 0.5;
    int a = (14 - mo) ~/ 12;
    int yr = y + 4800 - a;
    int mn = mo + 12 * a - 3;
    return day +
        (153 * mn + 2) ~/ 5 +
        365 * yr +
        yr ~/ 4 -
        yr ~/ 100 +
        yr ~/ 400 -
        32045;
  }

  static double _jcentury(double jd) => (jd - 2451545) / 36525;

  static double _sunDeclination(double t) {
    final e = 23.439 - 0.013 * t;
    final l = 280.46646 + t * (36000.76983 + t * 0.0003032);
    final g = (357.52911 + t * (35999.05029 - 0.0001537 * t)) * math.pi / 180;
    final c = math.sin(g) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
        math.sin(2 * g) * (0.019993 - 0.000101 * t) +
        math.sin(3 * g) * 0.000289;
    final sunLon = (l + c) * math.pi / 180;
    return math.asin(math.sin(e * math.pi / 180) * math.sin(sunLon)) *
        180 /
        math.pi;
  }

  static double _equationOfTime(double t) {
    final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
    final l0 = (280.46646 + t * (36000.76983 + t * 0.0003032)) % 360;
    final m = (357.52911 + t * (35999.05029 - 0.0001537 * t)) * math.pi / 180;
    final y =
        math.pow(math.tan((23.439 - 0.013 * t) * math.pi / 360), 2).toDouble();
    final sinM = math.sin(m);
    final eot = y * math.sin(2 * l0 * math.pi / 180) -
        2 * e * sinM +
        4 * e * y * sinM * math.cos(2 * l0 * math.pi / 180) -
        0.5 * y * y * math.sin(4 * l0 * math.pi / 180) -
        1.25 * e * e * math.sin(2 * m);
    return eot * 4 * 180 / math.pi;
  }
}
