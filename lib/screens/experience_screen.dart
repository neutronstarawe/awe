import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../core/app_preferences.dart';
import '../core/audio_engine.dart';
import 'hub_screen.dart';

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

class _ExperienceScreenState extends State<ExperienceScreen> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _completeCalled = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/video/the_experience.mp4');
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      await _controller.initialize();
      _controller.addListener(_onVideoUpdate);
      if (mounted) {
        setState(() => _initialized = true);
      }
      await _controller.play();
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

    _completeNavigation();
  }

  Future<void> _completeNavigation() async {
    await widget.preferences.setHasSeenIntro(true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HubScreen(
          audioEngine: AudioEngine(),
          preferences: widget.preferences,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _initialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
