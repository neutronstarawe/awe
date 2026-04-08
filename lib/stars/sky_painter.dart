import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart' show Color, CustomPainter, RadialGradient, Alignment;
import '../stars/star.dart';
import '../stars/constellation.dart';
import '../stars/sky_projection.dart';
import '../stars/astronomy.dart';
import '../stars/star_color.dart';

class SkyPainter extends CustomPainter {
  final List<Star> stars;
  final List<Constellation> constellations;
  final Map<int, Star> starById;
  final double observerLat;   // radians
  final double lst;           // Local Sidereal Time, radians
  final SkyProjection projection;
  final double twinklePhase;  // 0–2π, drives subtle shimmer on dim stars

  const SkyPainter({
    required this.stars,
    required this.constellations,
    required this.starById,
    required this.observerLat,
    required this.lst,
    required this.projection,
    this.twinklePhase = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawAtmosphere(canvas, size);
    _drawStarsAndLines(canvas, size);
  }

  // ── Atmosphere gradient ───────────────────────────────────────────────────

  void _drawAtmosphere(Canvas canvas, Size size) {
    // Pure black at zenith → very dark navy at horizon
    final gradient = RadialGradient(
      center: Alignment.bottomCenter,
      radius: 1.4,
      colors: const [
        Color(0xFF0a0d1a), // deep navy at horizon
        Color(0xFF000000), // pure black at zenith
      ],
      stops: const [0.0, 1.0],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = gradient.createShader(Offset.zero & size),
    );
  }

  // ── Stars + constellation lines ──────────────────────────────────────────

  void _drawStarsAndLines(Canvas canvas, Size size) {
    // Pre-compute projected positions for all visible stars
    final projected = <Star, Offset>{};
    for (final star in stars) {
      final (alt, az) = raDecToAltAz(
        ra: star.ra, dec: star.dec, latRad: observerLat, lst: lst,
      );
      if (alt < -0.05) continue; // below horizon
      final pos = projection.project(alt, az);
      if (pos != null) projected[star] = pos;
    }

    // Constellation lines (drawn beneath stars)
    final linePaint = Paint()
      ..color = const Color(0x20AACCFF) // faint blue-white
      ..strokeWidth = 0.5
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
      _drawStar(canvas, entry.value, entry.key);
    }
  }

  void _drawStar(Canvas canvas, Offset pos, Star star) {
    final baseColor = starColor(star.bv);
    final radius = _radius(star.mag);
    final opacity = _opacity(star.mag);

    // Twinkle: dim stars shimmer slightly based on animated phase
    final twinkle = star.mag > 3.0
        ? 0.85 + 0.15 * sin(twinklePhase + star.id * 1.618)
        : 1.0;
    final effectiveOpacity = (opacity * twinkle).clamp(0.0, 1.0);

    // Wide soft glow for bright stars (mag < 2)
    if (star.mag < 2.0) {
      final glowRadius = radius * 4.0;
      canvas.drawCircle(
        pos,
        glowRadius,
        Paint()
          ..color = Color.fromARGB(
            (effectiveOpacity * 0.12 * 255).round(),
            baseColor.red, baseColor.green, baseColor.blue,
          )
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius * 0.6),
      );
    }

    // Radial gradient halo (glowing corona)
    final gradientRect = Rect.fromCircle(center: pos, radius: radius * 1.8);
    canvas.drawCircle(
      pos,
      radius * 1.8,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromARGB(
              (effectiveOpacity * 255).round(),
              baseColor.red, baseColor.green, baseColor.blue,
            ),
            Color.fromARGB(0, baseColor.red, baseColor.green, baseColor.blue),
          ],
        ).createShader(gradientRect),
    );

    // Solid bright core
    canvas.drawCircle(
      pos,
      radius * 0.45,
      Paint()
        ..color = Color.fromARGB(
          (effectiveOpacity * 255).round(),
          baseColor.red, baseColor.green, baseColor.blue,
        ),
    );
  }

  // ── Sizing helpers ────────────────────────────────────────────────────────

  double _radius(double mag) => max(0.6, 3.2 - mag * 0.38);

  double _opacity(double mag) => (1.0 - mag / 8.0).clamp(0.12, 1.0);

  @override
  bool shouldRepaint(SkyPainter old) =>
      old.lst != lst ||
      old.twinklePhase != twinklePhase ||
      old.projection.centerAz != projection.centerAz ||
      old.projection.centerAlt != projection.centerAlt;
}
