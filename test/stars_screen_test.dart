import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awe/screens/stars_screen.dart';
import 'package:awe/stars/star.dart';
import 'package:awe/stars/constellation.dart';
import 'package:awe/stars/star_catalog.dart';
import 'package:awe/stars/sky_orientation.dart';

void main() {
  final catalog = StarCatalog(
    stars: [
      const Star(id: 32349, ra: 1.7679, dec: -0.2911, mag: -1.46, name: 'Sirius'),
      const Star(id: 11767, ra: 0.6637, dec: 1.5580, mag: 1.97, name: 'Polaris'),
    ],
    constellations: [
      const Constellation(name: 'Test', lines: [[32349, 11767]]),
    ],
  );

  testWidgets('StarsScreen renders without crashing', (tester) async {
    final orientation = FakeSkyOrientationSource();
    await tester.pumpWidget(MaterialApp(
      home: StarsScreen(
        catalog: catalog,
        orientationSource: orientation,
        observerLat: 52.0 * pi / 180,
        observerLng: 0.0,
      ),
    ));
    await tester.pump(Duration.zero);
    expect(find.byType(StarsScreen), findsOneWidget);
    orientation.dispose();
  });

  testWidgets('StarsScreen repaints when orientation emits', (tester) async {
    final orientation = FakeSkyOrientationSource();
    await tester.pumpWidget(MaterialApp(
      home: StarsScreen(
        catalog: catalog,
        orientationSource: orientation,
        observerLat: 52.0 * pi / 180,
        observerLng: 0.0,
      ),
    ));
    orientation.emit(const SkyOrientation(azimuth: 1.0, altitude: 0.5));
    await tester.pump();
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    orientation.dispose();
  });
}
