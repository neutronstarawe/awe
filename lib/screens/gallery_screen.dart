import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GalleryScreen extends StatefulWidget {
  final String title;
  final List<String> imagePaths;

  const GalleryScreen({
    super.key,
    required this.title,
    required this.imagePaths,
  });

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen>
    with TickerProviderStateMixin {
  // Phone-rotation prompt
  late final AnimationController _rotateCtrl;
  late final Animation<double> _phoneAngle;

  // Prompt fade-out
  late final AnimationController _promptFadeCtrl;
  late final Animation<double> _promptOpacity;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Phone rocks portrait (0°) → landscape (−90°) → back, 3 s per full cycle.
    // Each cycle: 1.2 s rotate → 0.6 s hold → 1.2 s rotate back.
    _rotateCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000));
    _phoneAngle = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -pi / 2)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 40),
      TweenSequenceItem(tween: ConstantTween(-pi / 2), weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: -pi / 2, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 40),
    ]).animate(_rotateCtrl);
    _rotateCtrl.repeat();

    // Prompt: fade in (0.5 s) → hold (5 s showing 1-2 full cycles) → fade out (1 s).
    _promptFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 6500));
    _promptOpacity = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 8),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 77),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 15),
    ]).animate(_promptFadeCtrl);
    _promptFadeCtrl.forward().whenComplete(_rotateCtrl.stop);
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _promptFadeCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: widget.imagePaths.isEmpty
          ? Center(
              child: Text(
                'No images yet',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            )
          : Stack(
              children: [
                // Image gallery
                PageView.builder(
                  itemCount: widget.imagePaths.length,
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: SizedBox.expand(
                        child: Image.asset(
                          widget.imagePaths[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white.withValues(alpha: 0.2),
                                size: 48,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),

                // Rotate-phone prompt — bottom-right corner
                Positioned(
                  bottom: 28,
                  right: 24,
                  child: FadeTransition(
                    opacity: _promptOpacity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _phoneAngle,
                          builder: (_, __) => Transform.rotate(
                            angle: _phoneAngle.value,
                            child: Icon(
                              Icons.stay_current_portrait,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Rotate for full\nexperience',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 10,
                            fontWeight: FontWeight.w300,
                            height: 1.5,
                            letterSpacing: 0.3,
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
