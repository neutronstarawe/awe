import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:awe/stars/astronomy.dart';

void main() {
  group('julianDate', () {
    test('J2000.0 epoch is JD 2451545.0', () {
      // 2000 Jan 1, 12:00:00 UTC = J2000.0
      final jd = julianDate(DateTime.utc(2000, 1, 1, 12, 0, 0));
      expect(jd, closeTo(2451545.0, 0.001));
    });

    test('1999 Jan 1.0 UTC is JD 2451179.5', () {
      final jd = julianDate(DateTime.utc(1999, 1, 1, 0, 0, 0));
      expect(jd, closeTo(2451179.5, 0.001));
    });
  });

  group('raDecToAltAz', () {
    // Polaris: HIP 11767, RA=2.5303h → 0.6637 rad, Dec=89.2641° → 1.5580 rad
    // Key property: altitude of Polaris ≈ observer latitude (within ~1°)
    const polarisRa = 0.6637;  // radians
    const polarisDec = 1.5580; // radians

    test('Polaris altitude ≈ latitude at 52°N', () {
      const latRad = 52.0 * pi / 180;
      // At transit (ha=0): LST = RA
      final lst = polarisRa;
      final (alt, _) = raDecToAltAz(
        ra: polarisRa, dec: polarisDec, latRad: latRad, lst: lst,
      );
      expect(alt * 180 / pi, closeTo(52.0, 1.0)); // within 1°
    });

    test('Polaris altitude ≈ 0° at equator', () {
      const latRad = 0.0;
      final lst = polarisRa;
      final (alt, _) = raDecToAltAz(
        ra: polarisRa, dec: polarisDec, latRad: latRad, lst: lst,
      );
      expect(alt * 180 / pi, closeTo(0.0, 1.0));
    });

    test('Star on equator transiting meridian is at altitude = 90° - lat', () {
      // dec=0, ha=0 → alt = 90° - lat
      const latDeg = 40.0;
      const latRad = latDeg * pi / 180;
      const ra = 1.0;
      final lst = ra; // ha = 0 at transit
      final (alt, _) = raDecToAltAz(
        ra: ra, dec: 0.0, latRad: latRad, lst: lst,
      );
      expect(alt * 180 / pi, closeTo(90.0 - latDeg, 0.1));
    });

    test('Star on meridian has azimuth ≈ 0° (North) or 180° (South)', () {
      // Polaris transiting at 52°N should be roughly North (az ≈ 0 or 2π)
      const latRad = 52.0 * pi / 180;
      final lst = polarisRa;
      final (_, az) = raDecToAltAz(
        ra: polarisRa, dec: polarisDec, latRad: latRad, lst: lst,
      );
      final azDeg = az * 180 / pi;
      // az should be near 0° or near 360°
      expect(azDeg < 5.0 || azDeg > 355.0, isTrue);
    });

    test('altitude clamps to valid range', () {
      // Sanity: no NaN, no values outside [-90°, 90°]
      final (alt, az) = raDecToAltAz(
        ra: 0.0, dec: 0.0, latRad: 0.0, lst: pi,
      );
      expect(alt, isNot(isNaN));
      expect(az, isNot(isNaN));
      expect(alt * 180 / pi, inInclusiveRange(-90.0, 90.0));
    });
  });
}
