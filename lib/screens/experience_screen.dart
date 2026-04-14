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
  bool _initialized = false;
  bool _completeCalled = false;

  // Headphones / volume prompt
  late final AnimationController _promptCtrl;
  late final Animation<double> _promptFade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Prompt: fade in (0.8 s) → hold (3.5 s) → fade out (0.7 s) = 5 s total
    _promptCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 5000));
    _promptFade = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 16),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 14),
    ]).animate(_promptCtrl);

    _controller =
        VideoPlayerController.asset('assets/video/the_experience.mp4');
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      await _controller.initialize();
      _controller.addListener(_onVideoUpdate);
      if (mounted) setState(() => _initialized = true);
      await _controller.play();
      // Start the headphones prompt once playback begins.
      if (mounted) _promptCtrl.forward();
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
      body: _initialized
          ? Stack(
              children: [
                // Video — covers the full screen.
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
                // Headphones prompt — bottom-centre, fades after 5 s.
                Positioned(
                  bottom: 28,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _promptFade,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.headphones,
                          color: Colors.white.withValues(alpha: 0.55),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Increase volume for the full experience',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.white24)),
    );
  }
}
