import 'package:flutter/material.dart';
import '../core/app_preferences.dart';
import 'experience_screen.dart';

class SplashScreen extends StatefulWidget {
  final AppPreferences preferences;
  final Duration splashDuration;
  final VoidCallback? onComplete;

  const SplashScreen({
    super.key,
    required this.preferences,
    this.splashDuration = const Duration(seconds: 2),
    this.onComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    Future.delayed(widget.splashDuration, () {
      if (!mounted) return;
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ExperienceScreen(preferences: widget.preferences),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: const Text(
            'awe',
            style: TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w100,
              letterSpacing: 16,
            ),
          ),
        ),
      ),
    );
  }
}
