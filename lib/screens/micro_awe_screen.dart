import 'package:flutter/material.dart';
import '../core/audio_engine.dart';

class MicroAweScreen extends StatefulWidget {
  final AudioEngine audioEngine;

  const MicroAweScreen({super.key, required this.audioEngine});

  @override
  State<MicroAweScreen> createState() => _MicroAweScreenState();
}

class _MicroAweScreenState extends State<MicroAweScreen> {
  double _scale = 1.0;
  double _previousScale = 1.0;

  static const _images = [
    'assets/images/montage_01.png',
    'assets/images/montage_02.png',
    'assets/images/montage_03.png',
  ];
  int _currentImage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onScaleStart: (details) {
              _previousScale = _scale;
            },
            onScaleUpdate: (details) {
              setState(() {
                _scale = (_previousScale * details.scale).clamp(0.5, 5.0);
              });
            },
            child: SizedBox.expand(
              child: Transform.scale(
                scale: _scale,
                child: Image.asset(
                  _images[_currentImage % _images.length],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(Icons.biotech, color: Colors.white24, size: 80),
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
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _images.length,
                (i) => GestureDetector(
                  onTap: () => setState(() {
                    _currentImage = i;
                    _scale = 1.0;
                  }),
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _currentImage % _images.length
                          ? Colors.white
                          : Colors.white30,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
