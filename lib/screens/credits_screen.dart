import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_preferences.dart';
import 'hub_screen.dart';
import 'journal_entry_screen.dart';

/// Cinema-style end-credits screen.
///
/// Starts with a pure black screen. The text is placed entirely below the
/// visible area and scrolls upward at a steady pace until the last line
/// exits from the top of the screen — then the app navigates to the hub.
/// Tap anywhere to skip.
class CreditsScreen extends StatefulWidget {
  final AppPreferences preferences;

  const CreditsScreen({super.key, required this.preferences});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  late final ScrollController _scrollCtrl;
  bool _navigating = false;

  // ~17 px / s → slow cinematic credits pace.
  static const double _scrollSpeed = 17.0;

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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _scrollCtrl = ScrollController();

    // After layout the scroll position is available; kick off the animation.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
  }

  Future<void> _startScroll() async {
    if (!mounted) return;

    // maxScrollExtent == screenHeight (top spacer) + textHeight + screenHeight
    //                    (bottom spacer) − viewportHeight
    //                 == screenHeight + textHeight
    // Scrolling all the way to maxScrollExtent means:
    //   • At 0: black screen (top spacer fills viewport — text is below).
    //   • At maxExtent: black screen (bottom spacer — text has fully exited top).
    final maxExtent = _scrollCtrl.position.maxScrollExtent;
    final durationMs = (maxExtent / _scrollSpeed * 1000).round();

    await _scrollCtrl.animateTo(
      maxExtent,
      duration: Duration(milliseconds: durationMs),
      curve: Curves.linear,
    );

    if (!mounted || _navigating) return;
    _navigateToHub();
  }

  Future<void> _navigateToHub() async {
    if (_navigating) return;
    _navigating = true;
    await widget.preferences.setHasSeenIntro(true);
    if (!mounted) return;
    await _showJournalPrompt();
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

  Future<void> _showJournalPrompt() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'How are you feeling?',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w300,
            fontSize: 17,
            letterSpacing: 0.5,
          ),
        ),
        content: Text(
          'Take a moment to capture what this experience stirred in you.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontWeight: FontWeight.w300,
            fontSize: 13,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Explore the app',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontWeight: FontWeight.w300,
                letterSpacing: 0.5,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const JournalEntryScreen(),
                ),
              );
            },
            child: Text(
              'Journal about it',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w300,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The screen height drives the two spacers so that:
    //   • scroll = 0   → only the top spacer is visible (pure black).
    //   • scroll = max → only the bottom spacer is visible (pure black).
    // Text enters from the bottom and exits through the top.
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _navigateToHub,
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          controller: _scrollCtrl,
          // NeverScrollableScrollPhysics blocks touch-driven scrolling;
          // programmatic animateTo() still works.
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: [
              // ── Top spacer: fills the viewport so the screen starts black ──
              SizedBox(height: screenH),

              // ── Credits text ───────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 52),
                child: Text(
                  _creditsText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xAAFFFFFF),
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    height: 2.1,
                    letterSpacing: 0.4,
                  ),
                ),
              ),

              // ── Bottom spacer: gives the last line room to scroll off-screen ──
              SizedBox(height: screenH),
            ],
          ),
        ),
      ),
    );
  }
}
