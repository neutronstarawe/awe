import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart' show Color, CustomPainter;
import '../stars/star.dart';
import '../stars/constellation.dart';
import '../stars/sky_projection.dart';
import '../stars/astronomy.dart';

class SkyPainter extends CustomPainter {
  final List<Star> stars;
  final List<Constellation> constellations;
  final Map<int, Star> starById;
  final double observerLat;   // radians
  final double lst;           // Local Sidereal Time, radians
  final SkyProjection projection;

  const SkyPainter({
    required this.stars,
    required this.constellations,
    required this.starById,
    required this.observerLat,
    required this.lst,
    required this.projection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF000000),
    );

    // Pre-compute alt/az for all visible stars
    final projected = <Star, Offset>{};
    for (final star in stars) {
      final (alt, az) = raDecToAltAz(
        ra: star.ra, dec: star.dec, latRad: observerLat, lst: lst,
      );
      if (alt < -0.1) continue; // below horizon
      final pos = projection.project(alt, az);
      if (pos != null) projected[star] = pos;
    }

    // Constellation lines
    final linePaint = Paint()
      ..color = const Color(0x26FFFFFF) // ~15% white
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;

    for (final con in constellations) {
      for (final line in con.lines) {
        if (line.length < 2) continue;
        final s1 = starById[line[0]];
        final s2 = starById[line[1]];
        if (s1 == null || s2 == null) continue;
        final p1 = projected[s1];
        final p2 = projected[s2];
        if (p1 != null && p2 != null) {
          canvas.drawLine(p1, p2, linePaint);
        }
      }
    }

    // Stars
    for (final entry in projected.entries) {
      final star = entry.key;
      final pos = entry.value;
      final radius = _radius(star.mag);
      final opacity = _opacity(star.mag);

      // Glow for bright stars (mag < 1.5)
      if (star.mag < 1.5) {
        canvas.drawCircle(
          pos,
          radius * 2.5,
          Paint()
            ..color = Color.fromRGBO(255, 255, 255, opacity * 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }

      canvas.drawCircle(
        pos,
        radius,
        Paint()..color = Color.fromRGBO(255, 255, 255, opacity),
      );
    }
  }

  /// Star dot radius in logical pixels. Brighter (lower mag) → larger.
  double _radius(double mag) => max(0.5, 3.0 - mag * 0.35);

  /// Star opacity. Brighter (lower mag) → more opaque.
  double _opacity(double mag) => (1.0 - mag / 8.0).clamp(0.15, 1.0);

  @override
  bool shouldRepaint(SkyPainter old) =>
      old.lst != lst ||
      old.projection.centerAz != projection.centerAz ||
      old.projection.centerAlt != projection.centerAlt;
}
