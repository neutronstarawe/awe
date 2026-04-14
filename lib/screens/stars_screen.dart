import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../stars/star_catalog.dart';
import '../stars/sky_orientation.dart';
import '../stars/sky_projection.dart';
import '../stars/sky_painter.dart';

class StarsScreen extends StatefulWidget {
  final StarCatalog             catalog;
  final SkyOrientationSource    orientationSource;

  /// Optional override for testing — skips GPS when both are provided.
  final double? observerLat; // radians
  final double? observerLng; // radians

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

class _StarsScreenState extends State<StarsScreen>
    with SingleTickerProviderStateMixin {

  PhonePointing _pointing = PhonePointing.defaultPointing;
  bool _locationReady = false;
  String? _error;

  StreamSubscription<PhonePointing>? _orientationSub;
  late final AnimationController _twinkleController;

  // FOV controlled by pinch-to-zoom (half-angle, radians).
  double  _fovRadians = 35 * pi / 180;
  static const _minFov = 10 * pi / 180;
  static const _maxFov = 70 * pi / 180;
  double? _pinchStartFov;

  @override
  void initState() {
    super.initState();
    _orientationSub = widget.orientationSource.stream.listen(_onPointing);
    _initLocation();

    // Twinkle: drives shimmer via CustomPainter repaint Listenable.
    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  void _onPointing(PhonePointing p) {
    if (mounted) setState(() => _pointing = p);
  }

  Future<void> _initLocation() async {
    if (widget.observerLat != null && widget.observerLng != null) {
      widget.orientationSource.setLocation(
          widget.observerLat!, widget.observerLng!);
      if (mounted) setState(() => _locationReady = true);
      return;
    }

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _error = 'Location permission required.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        widget.orientationSource.setLocation(
          pos.latitude  * pi / 180,
          pos.longitude * pi / 180,
        );
        setState(() => _locationReady = true);
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
      body: GestureDetector(
        onScaleStart: (_) => _pinchStartFov = _fovRadians,
        onScaleUpdate: (details) {
          if (details.pointerCount < 2) return;
          final newFov = (_pinchStartFov! / details.scale).clamp(_minFov, _maxFov);
          if (mounted) setState(() => _fovRadians = newFov);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final projection = SkyProjection(
              lineOfSight: _pointing.lineOfSight,
              screenUp:    _pointing.screenUp,
              fovRadians:  _fovRadians,
              screenSize:  size,
            );
            final painter = SkyPainter(
              stars:          widget.catalog.starsVisibleToNakedEye(),
              constellations: widget.catalog.constellations,
              starById:       widget.catalog.byId,
              projection:     projection,
              twinkle:        _twinkleController,
            );
            return CustomPaint(painter: painter, size: size);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _twinkleController.dispose();
    _orientationSub?.cancel();
    widget.orientationSource.dispose();
    super.dispose();
  }
}
