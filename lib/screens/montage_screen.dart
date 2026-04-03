import 'package:flutter/material.dart';
import '../core/audio_engine.dart';
import '../core/app_preferences.dart';
import 'video_screen.dart';

class MontageScreen extends StatefulWidget {
  final AudioEngine audioEngine;
  final AppPreferences preferences;
  final Duration imageDuration;
  final Duration crossfadeDuration;
  final VoidCallback? onComplete;

  static const int imageCount = 22;

  const MontageScreen({
    super.key,
    required this.audioEngine,
    required this.preferences,
    this.imageDuration = const Duration(seconds: 3),
    this.crossfadeDuration = const Duration(milliseconds: 800),
    this.onComplete,
  });

  @override
  State<MontageScreen> createState() => _MontageScreenState();
}

class _MontageScreenState extends State<MontageScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _crossfadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _crossfadeController = AnimationController(
      vsync: this,
      duration: widget.crossfadeDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _crossfadeController,
      curve: Curves.easeInOut,
    );
    _loadResumeIndex();
  }

  Future<void> _loadResumeIndex() async {
    final savedIndex = await widget.preferences.montageIndex;
    if (mounted && savedIndex < MontageScreen.imageCount) {
      setState(() => _currentIndex = savedIndex);
    }
    _startMontage();
  }

  void _startMontage() {
    _advanceImage();
  }

  void _advanceImage() {
    if (!mounted) return;
    _crossfadeController.forward(from: 0).then((_) {
      if (!mounted) return;
      widget.preferences.setMontageIndex(_currentIndex);
      Future.delayed(widget.imageDuration, () {
        if (!mounted) return;
        if (_currentIndex >= MontageScreen.imageCount - 1) {
          _onMontageComplete();
        } else {
          setState(() => _currentIndex++);
          _advanceImage();
        }
      });
    });
  }

  void _onMontageComplete() {
    widget.preferences.setMontageIndex(0);
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VideoScreen(
            audioEngine: widget.audioEngine,
            preferences: widget.preferences,
          ),
        ),
      );
    }
  }

  String _imagePath(int index) {
    final number = (index + 1).toString().padLeft(2, '0');
    return 'assets/images/montage_$number.png';
  }

  @override
  void dispose() {
    _crossfadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SizedBox.expand(
          child: Image.asset(
            _imagePath(_currentIndex),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.black,
              child: Center(
                child: Text(
                  '${_currentIndex + 1}',
                  style: const TextStyle(color: Colors.white30, fontSize: 48),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
