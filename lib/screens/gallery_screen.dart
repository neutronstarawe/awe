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
    with SingleTickerProviderStateMixin {
  // Phone-rotation animation controller — 3 s per portrait→landscape→portrait cycle.
  late final AnimationController _rotateCtrl;
  late final Animation<double> _phoneAngle;

  // Driven by Future.delayed — much more reliable than chaining AnimationControllers.
  double _promptOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Rotation: 1.2 s rotate to landscape → 0.6 s hold → 1.2 s rotate back.
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

    // Fade in on the first frame, then hold, then fade out.
    // Using post-frame callback + Future.delayed avoids the
    // AnimationController chaining issues that were causing early dismissal.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _promptOpacity = 1.0); // triggers 600 ms fade-in

      // After 8 s visible, start the fade-out.
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) setState(() => _promptOpacity = 0.0); // triggers 800 ms fade-out
      });

      // Stop the rotation after the fade-out completes.
      Future.delayed(const Duration(milliseconds: 8800), () {
        if (mounted) _rotateCtrl.stop();
      });
    });
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
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
                // ── Image gallery ─────────────────────────────────────────
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
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white.withValues(alpha: 0.2),
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // ── Rotate-phone prompt — bottom-right corner ─────────────
                // AnimatedOpacity is driven by _promptOpacity toggled via
                // Future.delayed so the timing is guaranteed by the Dart event
                // loop, not by animation controller chaining.
                Positioned(
                  bottom: 28,
                  right: 24,
                  child: AnimatedOpacity(
                    opacity: _promptOpacity,
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeInOut,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _phoneAngle,
                          builder: (_, __) => Transform.rotate(
                            angle: _phoneAngle.value,
                            child: Icon(
                              Icons.stay_current_portrait,
                              color: Colors.white.withValues(alpha: 0.65),
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Rotate for full\nexperience',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
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
