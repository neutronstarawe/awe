import 'package:flutter/material.dart';

class OrientationGateScreen extends StatelessWidget {
  final Widget child;

  const OrientationGateScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          return child;
        }
        return const _RotatePrompt();
      },
    );
  }
}

class _RotatePrompt extends StatefulWidget {
  const _RotatePrompt();

  @override
  State<_RotatePrompt> createState() => _RotatePromptState();
}

class _RotatePromptState extends State<_RotatePrompt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Rotates portrait → landscape (−90°), holds, snaps back, holds
    _rotation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.25)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(-0.25),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.25, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 15,
      ),
    ]).animate(_controller);

    _fade = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.2));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _rotation,
              child: const Icon(
                key: ValueKey('rotate_animation'),
                Icons.stay_current_portrait,
                color: Colors.white,
                size: 72,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Rotate your phone',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'landscape mode for the full experience',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
