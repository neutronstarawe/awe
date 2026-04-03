import 'package:flutter/material.dart';
import '../core/audio_engine.dart';
import '../core/app_preferences.dart';
import 'hub_screen.dart';

class QuoteScreen extends StatefulWidget {
  final AudioEngine audioEngine;
  final AppPreferences preferences;
  final Duration quoteDuration;
  final VoidCallback? onComplete;

  const QuoteScreen({
    super.key,
    required this.audioEngine,
    required this.preferences,
    this.quoteDuration = const Duration(seconds: 4),
    this.onComplete,
  });

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const String _quote =
      '\u201cLook again at that dot. That\u2019s here. That\u2019s home. That\u2019s us.\u201d';
  static const String _attribution = '\u2014 Carl Sagan';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    Future.delayed(widget.quoteDuration, () {
      if (!mounted) return;
      _markIntroSeen();
    });
  }

  Future<void> _markIntroSeen() async {
    await widget.preferences.setHasSeenIntro(true);
    if (!mounted) return;
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HubScreen(
            audioEngine: widget.audioEngine,
            preferences: widget.preferences,
          ),
        ),
      );
    }
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _quote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _attribution,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
