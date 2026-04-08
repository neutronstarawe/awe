import 'dart:ui';

/// Maps a B-V color index to an RGB color, derived from Stellarium's
/// 128-entry color table (src/core/StelUtils.cpp).
///
/// B-V ranges from ~-0.5 (hot blue-white O/B stars) to ~3.5 (cool red M stars).
/// White stars (e.g. Vega, Sirius) have B-V ≈ 0.0.
Color starColor(double? bv) {
  if (bv == null) return const Color(0xFFFFFFFF);

  // Clamp to table range
  final t = ((bv + 0.5) / 4.0).clamp(0.0, 1.0); // 0=blue, 1=deep red
  final i = (t * (_table.length - 1)).toInt();
  final frac = t * (_table.length - 1) - i;

  final c0 = _table[i];
  final c1 = _table[(i + 1).clamp(0, _table.length - 1)];

  final r = (c0[0] + (c1[0] - c0[0]) * frac).clamp(0.0, 1.0);
  final g = (c0[1] + (c1[1] - c0[1]) * frac).clamp(0.0, 1.0);
  final b = (c0[2] + (c1[2] - c0[2]) * frac).clamp(0.0, 1.0);

  return Color.fromARGB(255, (r * 255).round(), (g * 255).round(), (b * 255).round());
}

/// Stellarium-derived B-V → linear RGB table (16 key points, linearly interpolated).
/// Source: Stellarium src/core/StelUtils.cpp colorTable[]
/// Columns: [R, G, B] normalised 0–1.
const _table = <List<double>>[
  [0.603, 0.714, 1.000], // B-V = -0.5  (O-type, deep blue)
  [0.624, 0.737, 1.000], // -0.27
  [0.692, 0.792, 1.000], // -0.05
  [0.780, 0.843, 1.000], // B-type, blue-white
  [0.896, 0.926, 1.000], // A-type (Vega)
  [1.000, 1.000, 1.000], // B-V ≈ 0.0  white (Sirius)
  [1.000, 1.000, 0.984], // F-type, warm white
  [1.000, 0.984, 0.922], //
  [1.000, 0.967, 0.851], // G-type (Sun ~0.65)
  [1.000, 0.930, 0.755], //
  [1.000, 0.889, 0.635], // K-type, orange
  [1.000, 0.840, 0.510], //
  [1.000, 0.783, 0.380], // K5
  [1.000, 0.710, 0.250], // M-type, orange-red
  [1.000, 0.620, 0.150], //
  [1.000, 0.500, 0.050], // M5, deep red (B-V ≈ 3.5)
];
