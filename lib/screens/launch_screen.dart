import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_preferences.dart';
import 'hub_screen.dart';
import 'splash_screen.dart';

/// Shown every time the app opens — "awe — allow yourself to breathe".
/// Fades in, holds, fades out over 3 seconds, then routes to the
/// appropriate screen based on whether the user has seen the intro.
class LaunchScreen extends StatefulWidget {
  final AppPreferences preferences;
  final bool hasSeenIntro;

  const LaunchScreen({
    super.key,
    required this.preferences,
    required this.hasSeenIntro,
  });

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // fade in (1 s) → hold (1 s) → fade out (1 s) = 3 s total
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3));
    _fade = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 33),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 34),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 33),
    ]).animate(_ctrl);

    _ctrl.forward().whenComplete(_navigate);
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget.hasSeenIntro
            ? HubScreen(preferences: widget.preferences)
            : SplashScreen(preferences: widget.preferences),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'awe',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w100,
                  letterSpacing: 14,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'allow yourself to breathe',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 4.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
