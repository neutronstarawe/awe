import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_preferences.dart';
import 'hub_screen.dart';

/// End-credits screen shown after the experience video completes.
/// The text scrolls from bottom to top, cinema-style, then transitions
/// to the hub. Tap anywhere to skip.
class CreditsScreen extends StatefulWidget {
  final AppPreferences preferences;

  const CreditsScreen({super.key, required this.preferences});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeIn;
  bool _navigating = false;

  static const _creditsText =
      'What you\'re likely feeling right now is awe. It is the emotion we '
      'experience when we encounter something so vast that it transcends our '
      'current understanding of the world. In these moments, we experience the '
      '\'Small Self\'. It sounds paradoxical but the sense of smallness leads '
      'to a greater sense of connection and wholeness. By realizing how small '
      'we are in the grand scheme of things, our personal worries and daily '
      'anxieties begin to lose their power. This shift in perspective is a '
      'powerful tool for your well-being.\n\n'
      'Awe reduces activity in the default mode network, widely considered to '
      'be the seat of rumination, by pulling your focus away from the self and '
      'toward the world around you. Regular awe experiences lower stress levels, '
      'reduce anxiety, regulate the nervous system and increase prosocial '
      'behaviour.\n\n'
      'Make space for these moments of wonder in your daily life and connect '
      'with the world and yourself.';

  @override
  void initState() {
    super.initState();
    // Stay in landscape + immersive, matching the video that preceded this screen.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _scrollCtrl = ScrollController();

    // Fade the text in before scrolling starts.
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeIn =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();

    // Wait for the first frame so maxScrollExtent is available, then scroll.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
  }

  Future<void> _startScroll() async {
    if (!mounted) return;

    // Brief pause while text fades in.
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted || _navigating) return;

    final maxExtent = _scrollCtrl.position.maxScrollExtent;

    // ~40 s total scroll — comfortable reading pace for credits.
    await _scrollCtrl.animateTo(
      maxExtent,
      duration: const Duration(seconds: 40),
      curve: Curves.linear,
    );

    // Linger at the end before transitioning.
    if (!mounted || _navigating) return;
    await Future.delayed(const Duration(seconds: 3));
    _navigateToHub();
  }

  Future<void> _navigateToHub() async {
    if (_navigating) return;
    _navigating = true;
    await widget.preferences.setHasSeenIntro(true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            HubScreen(preferences: widget.preferences),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _fadeCtrl.dispose();
    SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _navigateToHub,
        behavior: HitTestBehavior.opaque,
        child: FadeTransition(
          opacity: _fadeIn,
          child: Center(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                  horizontal: 64, vertical: 100),
              child: const Text(
                _creditsText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xAAFFFFFF),
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  height: 2.0,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
