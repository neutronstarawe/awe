import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart'
    show Animation, Color, CustomPainter, RadialGradient, Alignment;
import 'star.dart';
import 'constellation.dart';
import 'sky_projection.dart';
import 'astronomy.dart';
import 'star_color.dart';

class SkyPainter extends CustomPainter {
  final List<Star>            stars;
  final List<Constellation>   constellations;
  final Map<int, Star>        starById;
  final SkyProjection         projection;

  /// Drives twinkle repaints directly on the canvas (no setState needed).
  final Animation<double>?    twinkle;

  SkyPainter({
    required this.stars,
    required this.constellations,
    required this.starById,
    required this.projection,
    this.twinkle,
  }) : super(repaint: twinkle);

  double get _twinklePhase => (twinkle?.value ?? 0) * 2 * pi;

  @override
  void paint(Canvas canvas, Size size) {
    _drawAtmosphere(canvas, size);
    _drawStarsAndLines(canvas, size);
  }

  // ── Atmosphere gradient ───────────────────────────────────────────────────

  void _drawAtmosphere(Canvas canvas, Size size) {
    const gradient = RadialGradient(
      center: Alignment.bottomCenter,
      radius: 1.4,
      colors: [
        Color(0xFF0a0d1a), // deep navy at horizon
        Color(0xFF000000), // pure black at zenith
      ],
      stops: [0.0, 1.0],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = gradient.createShader(Offset.zero & size),
    );
  }

  // ── Stars + constellation lines ──────────────────────────────────────────

  void _drawStarsAndLines(Canvas canvas, Size size) {
    // Project every visible star from its geocentric unit vector.
    // No alt/az conversion needed — the projection works directly in
    // celestial space using the phone's 3D pointing vectors.
    final projected = <Star, Offset>{};
    for (final star in stars) {
      final vec = raDecToVec(star.ra, star.dec);
      final pos = projection.project(vec);
      if (pos != null) projected[star] = pos;
    }

    // Constellation lines (below stars)
    final linePaint = Paint()
      ..color      = const Color(0x20AACCFF)
      ..strokeWidth = 0.5
      ..strokeCap  = StrokeCap.round;

    for (final con in constellations) {
      for (final line in con.lines) {
        if (line.length < 2) continue;
        final s1 = starById[line[0]];
        final s2 = starById[line[1]];
        if (s1 == null || s2 == null) continue;
        final p1 = projected[s1];
        final p2 = projected[s2];
        if (p1 != null && p2 != null) canvas.drawLine(p1, p2, linePaint);
      }
    }

    // Stars
    for (final entry in projected.entries) {
      _drawStar(canvas, entry.value, entry.key);
    }
  }

  void _drawStar(Canvas canvas, Offset pos, Star star) {
    final baseColor       = starColor(star.bv);
    final radius          = _radius(star.mag);
    final opacity         = _opacity(star.mag);

    // Dim stars shimmer slightly based on animated phase.
    final twinkleFactor   = star.mag > 3.0
        ? 0.85 + 0.15 * sin(_twinklePhase + star.id * 1.618)
        : 1.0;
    final effectiveOpacity = (opacity * twinkleFactor).clamp(0.0, 1.0);

    // Wide soft glow for bright stars (mag < 2).
    if (star.mag < 2.0) {
      final glowRadius = radius * 4.0;
      canvas.drawCircle(
        pos,
        glowRadius,
        Paint()
          ..color = Color.fromARGB(
            (effectiveOpacity * 0.12 * 255).round(),
            (baseColor.r * 255).round().clamp(0, 255),
            (baseColor.g * 255).round().clamp(0, 255),
            (baseColor.b * 255).round().clamp(0, 255),
          )
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius * 0.6),
      );
    }

    // Radial gradient corona.
    final gradientRect = Rect.fromCircle(center: pos, radius: radius * 1.8);
    canvas.drawCircle(
      pos,
      radius * 1.8,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromARGB(
              (effectiveOpacity * 255).round(),
              (baseColor.r * 255).round().clamp(0, 255),
              (baseColor.g * 255).round().clamp(0, 255),
              (baseColor.b * 255).round().clamp(0, 255),
            ),
            Color.fromARGB(
              0,
              (baseColor.r * 255).round().clamp(0, 255),
              (baseColor.g * 255).round().clamp(0, 255),
              (baseColor.b * 255).round().clamp(0, 255),
            ),
          ],
        ).createShader(gradientRect),
    );

    // Solid bright core.
    canvas.drawCircle(
      pos,
      radius * 0.45,
      Paint()
        ..color = Color.fromARGB(
          (effectiveOpacity * 255).round(),
          (baseColor.r * 255).round().clamp(0, 255),
          (baseColor.g * 255).round().clamp(0, 255),
          (baseColor.b * 255).round().clamp(0, 255),
        ),
    );
  }

  // ── Sizing helpers ────────────────────────────────────────────────────────

  double _radius(double mag) => max(0.6, 3.2 - mag * 0.38);
  double _opacity(double mag) => (1.0 - mag / 8.0).clamp(0.12, 1.0);

  @override
  bool shouldRepaint(SkyPainter old) => true; // sensor-driven setState always changes pointing
}
