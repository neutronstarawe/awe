import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awe/stars/star.dart';
import 'package:awe/stars/constellation.dart';
import 'package:awe/stars/star_catalog.dart';

class _FakeBundle extends Fake implements AssetBundle {
  final String starsJson;
  final String consJson;

  _FakeBundle({required this.starsJson, required this.consJson});

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key.contains('stars')) return starsJson;
    if (key.contains('constellations')) return consJson;
    throw UnsupportedError(key);
  }
}

void main() {
  final sampleStars = jsonEncode([
    {'id': 32349, 'ra': 1.7679, 'dec': -0.2911, 'mag': -1.46, 'name': 'Sirius'},
    {'id': 11767, 'ra': 0.6637, 'dec': 1.5580, 'mag': 1.97, 'name': 'Polaris'},
    {'id': 99999, 'ra': 0.0, 'dec': 0.0, 'mag': 7.5},
  ]);

  final sampleCons = jsonEncode({
    'Orion': [[24436, 25930], [25930, 26727]],
  });

  late StarCatalog catalog;

  setUp(() async {
    catalog = await StarCatalog.load(
        _FakeBundle(starsJson: sampleStars, consJson: sampleCons));
  });

  test('loads all stars', () {
    expect(catalog.stars.length, 3);
  });

  test('parses star fields correctly', () {
    final sirius = catalog.starById(32349)!;
    expect(sirius.name, 'Sirius');
    expect(sirius.mag, closeTo(-1.46, 0.001));
    expect(sirius.ra, closeTo(1.7679, 0.0001));
    expect(sirius.dec, closeTo(-0.2911, 0.0001));
  });

  test('starById returns null for unknown id', () {
    expect(catalog.starById(0), isNull);
  });

  test('starsVisibleToNakedEye filters out dim stars', () {
    final visible = catalog.starsVisibleToNakedEye();
    expect(visible.length, 2); // Sirius and Polaris, not the 7.5-mag one
  });

  test('loads constellations', () {
    expect(catalog.constellations.length, 1);
    expect(catalog.constellations.first.name, 'Orion');
    expect(catalog.constellations.first.lines.first, [24436, 25930]);
  });
}
