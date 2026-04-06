class Star {
  final int id;       // HIP catalog number
  final double ra;    // Right ascension, radians
  final double dec;   // Declination, radians
  final double mag;   // Visual magnitude (lower = brighter)
  final String? name; // Common name, e.g. "Sirius"

  const Star({
    required this.id,
    required this.ra,
    required this.dec,
    required this.mag,
    this.name,
  });

  factory Star.fromJson(Map<String, dynamic> json) => Star(
        id: json['id'] as int,
        ra: (json['ra'] as num).toDouble(),
        dec: (json['dec'] as num).toDouble(),
        mag: (json['mag'] as num).toDouble(),
        name: json['name'] as String?,
      );
}
