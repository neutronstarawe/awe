import 'dart:math';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:awe/stars/sky_projection.dart';

void main() {
  const size = Size(800, 600);
  const fov = 40.0 * pi / 180; // 40° half-angle FOV

  group('SkyProjection', () {
    test('center point projects to screen center', () {
      const centerAz = 1.0;
      const centerAlt = 0.5;
      final proj = SkyProjection(
        centerAz: centerAz, centerAlt: centerAlt,
        fovRadians: fov, screenSize: size,
      );
      final pos = proj.project(centerAlt, centerAz);
      expect(pos, isNotNull);
      expect(pos!.dx, closeTo(size.width / 2, 0.5));
      expect(pos.dy, closeTo(size.height / 2, 0.5));
    });

    test('star directly behind (opposite hemisphere) returns null', () {
      final proj = SkyProjection(
        centerAz: 0.0, centerAlt: 0.0,
        fovRadians: fov, screenSize: size,
      );
      // Directly behind: alt=0, az=pi (180° away)
      expect(proj.project(0.0, pi), isNull);
    });

    test('star far off-screen returns null', () {
      final proj = SkyProjection(
        centerAz: 0.0, centerAlt: 0.0,
        fovRadians: fov, screenSize: size,
      );
      // 90° away in azimuth — well outside 40° FOV
      expect(proj.project(0.0, pi / 2), isNull);
    });

    test('star slightly left of center projects left of screen center', () {
      const centerAz = 1.0;
      const centerAlt = 0.0;
      final proj = SkyProjection(
        centerAz: centerAz, centerAlt: centerAlt,
        fovRadians: fov, screenSize: size,
      );
      // 5° to the left (smaller az)
      final pos = proj.project(centerAlt, centerAz - 5 * pi / 180);
      expect(pos, isNotNull);
      expect(pos!.dx, lessThan(size.width / 2));
    });

    test('star slightly above center projects above screen center', () {
      const centerAz = 1.0;
      const centerAlt = 0.2;
      final proj = SkyProjection(
        centerAz: centerAz, centerAlt: centerAlt,
        fovRadians: fov, screenSize: size,
      );
      // 5° higher altitude
      final pos = proj.project(centerAlt + 5 * pi / 180, centerAz);
      expect(pos, isNotNull);
      expect(pos!.dy, lessThan(size.height / 2)); // higher alt = smaller dy
    });
  });
}
