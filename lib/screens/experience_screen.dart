import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../core/app_preferences.dart';
import 'credits_screen.dart';

class ExperienceScreen extends StatefulWidget {
  final AppPreferences preferences;
  final VoidCallback? onVideoComplete;

  const ExperienceScreen({
    super.key,
    required this.preferences,
    this.onVideoComplete,
  });

  @override
  State<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends State<ExperienceScreen>
    with SingleTickerProviderStateMixin {
  late final VideoPlayerController _controller;
  bool _videoReady = false;
  bool _completeCalled = false;

  // Headphones prompt shown on black for 1.5 s, then fades out over 0.5 s.
  late final AnimationController _promptCtrl;
  late final Animation<double> _promptFade;
  bool _promptVisible = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Prompt: hold (1.5 s) → fade out (0.5 s) = 2 s total.
    _promptCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _promptFade = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 75),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 25),
    ]).animate(_promptCtrl);
    _promptCtrl.forward().whenComplete(() {
      if (mounted) setState(() => _promptVisible = false);
    });

    // Load the video in parallel — it will be hidden behind the prompt overlay.
    _controller =
        VideoPlayerController.asset('assets/video/the_experience.mp4');
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      await _controller.initialize();
      _controller.addListener(_onVideoUpdate);
      if (mounted) {
        setState(() => _videoReady = true);
        await _controller.play();
      }
    } catch (_) {
      _onComplete();
    }
  }

  void _onVideoUpdate() {
    if (!mounted) return;
    final value = _controller.value;
    if (!value.isPlaying &&
        value.duration > Duration.zero &&
        value.position >= value.duration) {
      _controller.removeListener(_onVideoUpdate);
      _onComplete();
    }
  }

  void _onComplete() {
    if (_completeCalled) return;
    _completeCalled = true;
    if (widget.onVideoComplete != null) {
      widget.onVideoComplete!();
      return;
    }
    _navigateToCredits();
  }

  void _navigateToCredits() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            CreditsScreen(preferences: widget.preferences),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    _promptCtrl.dispose();
    SystemChrome.setPreferredOrientations([]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Video layer ────────────────────────────────────────────────
          if (_videoReady)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),

          // ── Headphones prompt — black overlay shown before video ───────
          // Stays on top until the 2 s animation completes.
          if (_promptVisible)
            AnimatedBuilder(
              animation: _promptFade,
              builder: (_, child) => Opacity(
                opacity: _promptFade.value,
                child: child,
              ),
              child: Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.headphones,
                      color: Colors.white.withValues(alpha: 0.65),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Increase volume for the full experience',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
