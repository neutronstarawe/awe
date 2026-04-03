import 'package:flutter/material.dart';
import '../core/audio_engine.dart';
import '../core/sensor_service.dart';

class CosmicAweScreen extends StatefulWidget {
  final AudioEngine audioEngine;
  final SensorService? sensorService;

  const CosmicAweScreen({
    super.key,
    required this.audioEngine,
    this.sensorService,
  });

  @override
  State<CosmicAweScreen> createState() => _CosmicAweScreenState();
}

class _CosmicAweScreenState extends State<CosmicAweScreen> {
  late final SensorService _sensorService;
  double _offsetX = 0;
  double _offsetY = 0;

  @override
  void initState() {
    super.initState();
    _sensorService = widget.sensorService ?? RealSensorService();
    _sensorService.gyroscopeStream.listen((event) {
      if (!mounted) return;
      setState(() {
        _offsetX = (_offsetX + event.y * 2).clamp(-40.0, 40.0);
        _offsetY = (_offsetY + event.x * 2).clamp(-40.0, 40.0);
      });
    });
  }

  @override
  void dispose() {
    _sensorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(
            child: Transform.translate(
              offset: Offset(_offsetX, _offsetY),
              child: Image.asset(
                'assets/images/montage_22.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black,
                  child: Center(
                    child: CustomPaint(
                      size: MediaQuery.of(context).size,
                      painter: _StarfieldPainter(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 48,
            left: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    // Simple static starfield placeholder
    final stars = [
      const Offset(0.1, 0.2), const Offset(0.3, 0.5), const Offset(0.6, 0.1),
      const Offset(0.8, 0.7), const Offset(0.4, 0.9), const Offset(0.9, 0.3),
      const Offset(0.2, 0.8), const Offset(0.7, 0.4), const Offset(0.5, 0.6),
      const Offset(0.15, 0.45), const Offset(0.65, 0.85), const Offset(0.35, 0.15),
    ];
    for (final s in stars) {
      canvas.drawCircle(Offset(s.dx * size.width, s.dy * size.height), 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
