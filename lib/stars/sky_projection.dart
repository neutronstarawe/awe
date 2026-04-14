import 'dart:math';
import 'dart:ui';
import 'astronomy.dart';

/// Gnomonic (tangent-plane) projection of the sky onto the screen,
/// operating entirely in 3D geocentric space — no alt/az conversion needed.
///
/// Given the direction the phone is pointing ([lineOfSight]) and the "up"
/// direction on screen ([screenUp]), any star's geocentric unit vector can be
/// projected to a pixel position.
///
/// Approach mirrors the stardroid renderer: the viewport is defined by two
/// orthonormal vectors in celestial space, and stars are projected via a
/// standard perspective / gnomonic transform.
class SkyProjection {
  final Vec3   lineOfSight;  // unit vector where phone screen faces
  final Vec3   screenUp;     // unit vector pointing up along the screen
  final double fovRadians;   // half-angle field of view
  final Size   screenSize;

  SkyProjection({
    required this.lineOfSight,
    required this.screenUp,
    required this.fovRadians,
    required this.screenSize,
  });

  // Right = forward × up (points toward screen's +x / right side).
  late final Vec3   _right = lineOfSight.cross(screenUp).normalized();
  late final double _scale = (screenSize.width / 2) / tan(fovRadians);

  /// Projects a geocentric unit vector [starVec] to a screen [Offset].
  /// Returns null if the star is behind the viewer or outside the screen.
  Offset? project(Vec3 starVec) {
    final cosAngle = starVec.dot(lineOfSight);
    if (cosAngle <= 0) return null; // more than 90° away — behind us

    // Gnomonic projection: divide tangent-plane coords by cos(angle) from centre.
    final x = starVec.dot(_right)   / cosAngle * _scale;
    final y = starVec.dot(screenUp) / cosAngle * _scale;

    final sx = screenSize.width  / 2 + x;
    final sy = screenSize.height / 2 - y; // y flipped: up = smaller pixel row

    const margin = 50.0;
    if (sx < -margin || sx > screenSize.width  + margin) return null;
    if (sy < -margin || sy > screenSize.height + margin) return null;

    return Offset(sx, sy);
  }
}
