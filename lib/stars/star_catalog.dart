import 'dart:convert';
import 'package:flutter/services.dart';
import 'star.dart';
import 'constellation.dart';

class StarCatalog {
  final List<Star> stars;
  final List<Constellation> constellations;
  final Map<int, Star> _byId;

  StarCatalog({required this.stars, required this.constellations})
      : _byId = {for (final s in stars) s.id: s};

  Map<int, Star> get byId => _byId;

  Star? starById(int id) => _byId[id];

  List<Star> starsVisibleToNakedEye() =>
      stars.where((s) => s.mag <= 6.5).toList();

  static Future<StarCatalog> load(AssetBundle bundle) async {
    final starsRaw =
        jsonDecode(await bundle.loadString('assets/data/stars.json')) as List;
    final consRaw =
        jsonDecode(await bundle.loadString('assets/data/constellations.json'))
            as Map<String, dynamic>;

    return StarCatalog(
      stars: starsRaw
          .map((j) => Star.fromJson(j as Map<String, dynamic>))
          .toList(),
      constellations: consRaw.entries
          .map((e) => Constellation.fromJson(e.key, e.value as List))
          .toList(),
    );
  }
}
