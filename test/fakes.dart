import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

/// Fake AudioPlayer for unit/widget tests — records calls without real playback.
class FakeAudioPlayer extends Fake implements AudioPlayer {
  bool _playing = false;
  Duration _position = Duration.zero;

  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Future<Duration?> setAsset(String assetPath,
      {String? package,
      bool preload = true,
      Duration? initialPosition,
      dynamic tag}) async {
    return null;
  }

  @override
  Future<void> play() async {
    _playing = true;
  }

  @override
  Future<void> pause() async {
    _playing = false;
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    _position = position ?? Duration.zero;
  }

  @override
  Future<void> dispose() async {}

  bool get isActuallyPlaying => _playing;
  Duration get actualPosition => _position;
}
