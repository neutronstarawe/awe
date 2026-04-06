import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../stars/star_catalog.dart';
import '../stars/sky_orientation.dart';
import '../stars/sky_projection.dart';
import '../stars/sky_painter.dart';
import '../stars/astronomy.dart';

class StarsScreen extends StatefulWidget {
  final StarCatalog catalog;
  final SkyOrientationSource orientationSource;
  final double? observerLat; // radians; if provided, skips GPS
  final double? observerLng; // radians; if provided, skips GPS

  const StarsScreen({
    super.key,
    required this.catalog,
    required this.orientationSource,
    this.observerLat,
    this.observerLng,
  });

  @override
  State<StarsScreen> createState() => _StarsScreenState();
}

class _StarsScreenState extends State<StarsScreen> {
  SkyOrientation _orientation = const SkyOrientation(azimuth: 0, altitude: 0);
  double _latRad = 0.0;
  double _lngRad = 0.0;
  bool _locationReady = false;
  String? _error;
  StreamSubscription<SkyOrientation>? _orientationSub;

  @override
  void initState() {
    super.initState();
    _orientationSub = widget.orientationSource.stream.listen(_onOrientation);
    _initLocation();
  }

  void _onOrientation(SkyOrientation o) {
    if (mounted) setState(() => _orientation = o);
  }

  Future<void> _initLocation() async {
    if (widget.observerLat != null && widget.observerLng != null) {
      setState(() {
        _latRad = widget.observerLat!;
        _lngRad = widget.observerLng!;
        _locationReady = true;
      });
      return;
    }

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Location permission required.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _latRad = pos.latitude * pi / 180;
          _lngRad = pos.longitude * pi / 180;
          _locationReady = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not get location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.white70)),
        ),
      );
    }

    if (!_locationReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white24)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final lst = localSiderealTime(_lngRad, DateTime.now().toUtc());
          final projection = SkyProjection(
            centerAz: _orientation.azimuth,
            centerAlt: _orientation.altitude,
            fovRadians: 35 * pi / 180, // 35° half-FOV
            screenSize: size,
          );
          final painter = SkyPainter(
            stars: widget.catalog.starsVisibleToNakedEye(),
            constellations: widget.catalog.constellations,
            starById: widget.catalog.byId,
            observerLat: _latRad,
            lst: lst,
            projection: projection,
          );
          return CustomPaint(painter: painter, size: size);
        },
      ),
    );
  }

  @override
  void dispose() {
    _orientationSub?.cancel();
    widget.orientationSource.dispose();
    super.dispose();
  }
}
