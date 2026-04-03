import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioEngine extends ChangeNotifier {
  final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  bool _isDisposed = false;

  AudioEngine({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _player.playerStateStream.listen((state) {
      if (_isDisposed) return;
      final playing = state.playing;
      if (playing != _isPlaying) {
        _isPlaying = playing;
        notifyListeners();
      }
    });
    _player.positionStream.listen((pos) {
      if (_isDisposed) return;
      _position = pos;
      notifyListeners();
    });
  }

  bool get isPlaying => _isPlaying;
  Duration get position => _position;

  Future<void> load(String assetPath) async {
    try {
      await _player.setAsset(assetPath);
    } catch (e) {
      debugPrint('AudioEngine.load error: $e');
    }
  }

  Future<void> play() async {
    try {
      await _player.play();
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('AudioEngine.play error: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint('AudioEngine.pause error: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
      _position = position;
      notifyListeners();
    } catch (e) {
      debugPrint('AudioEngine.seek error: $e');
    }
  }

  Future<void> disposeEngine() async {
    _isDisposed = true;
    try {
      await _player.dispose();
    } catch (e) {
      debugPrint('AudioEngine.dispose error: $e');
    }
    super.dispose();
  }
}
