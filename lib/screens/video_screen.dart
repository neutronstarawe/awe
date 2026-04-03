import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../core/audio_engine.dart';
import '../core/app_preferences.dart';
import 'quote_screen.dart';

class VideoScreen extends StatefulWidget {
  final AudioEngine audioEngine;
  final AppPreferences preferences;
  final VoidCallback? onComplete;

  const VideoScreen({
    super.key,
    required this.audioEngine,
    required this.preferences,
    this.onComplete,
  });

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/video/milky_way.mp4');
      await _controller!.initialize();
      await _controller!.setPlaybackSpeed(2.0);
      await _controller!.setLooping(false);
      _controller!.addListener(_onVideoProgress);
      setState(() => _initialized = true);
      await _controller!.play();
    } catch (e) {
      debugPrint('VideoScreen init error: $e');
      setState(() => _hasError = true);
      _onComplete();
    }
  }

  void _onVideoProgress() {
    if (_controller == null) return;
    final pos = _controller!.value.position;
    final dur = _controller!.value.duration;
    if (dur > Duration.zero && pos >= dur) {
      _onComplete();
    }
  }

  void _onComplete() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuoteScreen(
            audioEngine: widget.audioEngine,
            preferences: widget.preferences,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoProgress);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white24),
        ),
      );
    }

    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
