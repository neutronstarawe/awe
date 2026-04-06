import 'dart:math';
import 'dart:ui';

/// Gnomonic (tangent-plane) projection of the sky onto the screen.
///
/// The center of the screen corresponds to (centerAlt, centerAz).
/// Stars within [fovRadians] half-angle of center are projected to screen pixels.
class SkyProjection {
  final double centerAz;    // radians, 0=North clockwise
  final double centerAlt;   // radians, 0=horizon, π/2=zenith
  final double fovRadians;  // half-angle field of view in radians
  final Size screenSize;

  const SkyProjection({
    required this.centerAz,
    required this.centerAlt,
    required this.fovRadians,
    required this.screenSize,
  });

  /// Projects (alt, az) → screen [Offset]. Returns null if not on screen.
  Offset? project(double alt, double az) {
    // Angular distance from center (dot product of unit vectors)
    final cosD = sin(centerAlt) * sin(alt) +
        cos(centerAlt) * cos(alt) * cos(az - centerAz);

    // cosD <= 0 means behind us (> 90° away)
    if (cosD <= 0) return null;

    // Gnomonic projection: tangent-plane coords
    final dAz = az - centerAz;
    final x = cos(alt) * sin(dAz) / cosD;
    final y = (cos(centerAlt) * sin(alt) -
            sin(centerAlt) * cos(alt) * cos(dAz)) /
        cosD;

    // Scale: pixels per radian at center
    final scale = (screenSize.width / 2) / tan(fovRadians);

    final sx = screenSize.width / 2 + x * scale;
    final sy = screenSize.height / 2 - y * scale; // y flipped: up = smaller dy

    // Off-screen guard (50px margin)
    const margin = 50.0;
    if (sx < -margin || sx > screenSize.width + margin) return null;
    if (sy < -margin || sy > screenSize.height + margin) return null;

    return Offset(sx, sy);
  }
}
