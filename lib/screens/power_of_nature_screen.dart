import 'package:flutter/material.dart';
import '../core/audio_engine.dart';

class PowerOfNatureScreen extends StatefulWidget {
  final AudioEngine audioEngine;

  const PowerOfNatureScreen({super.key, required this.audioEngine});

  @override
  State<PowerOfNatureScreen> createState() => _PowerOfNatureScreenState();
}

class _PowerOfNatureScreenState extends State<PowerOfNatureScreen> {
  final ScrollController _scrollController = ScrollController();

  static const _images = [
    'assets/images/montage_04.png',
    'assets/images/montage_05.png',
    'assets/images/montage_06.png',
    'assets/images/montage_07.png',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Image.asset(
                  _images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.black,
                    child: Center(
                      child: Icon(
                        Icons.landscape,
                        color: Colors.white.withValues(alpha: 0.2),
                        size: 80,
                      ),
                    ),
                  ),
                ),
              );
            },
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
