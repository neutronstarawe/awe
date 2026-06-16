import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AmbientSound { none, brownNoise, rain, forest, ocean }

extension AmbientSoundExt on AmbientSound {
  String get label => switch (this) {
        AmbientSound.none => 'Off',
        AmbientSound.brownNoise => 'Brown Noise',
        AmbientSound.rain => 'Rain',
        AmbientSound.forest => 'Forest',
        AmbientSound.ocean => 'Ocean',
      };

  /// Asset path — null means no file bundled yet.
  String? get assetPath => switch (this) {
        AmbientSound.none => null,
        AmbientSound.brownNoise => 'assets/audio/brown_noise.mp3',
        AmbientSound.rain => 'assets/audio/rain.mp3',
        AmbientSound.forest => 'assets/audio/forest.mp3',
        AmbientSound.ocean => 'assets/audio/ocean.mp3',
      };
}

class AmbientAudioService {
  static final AmbientAudioService _instance = AmbientAudioService._();
  factory AmbientAudioService() => _instance;
  AmbientAudioService._();

  static const _keySound = 'ambient_sound';
  static const _keyVolume = 'ambient_volume';

  final AudioPlayer _player = AudioPlayer();
  AmbientSound _current = AmbientSound.none;
  double _volume = 0.5;

  AmbientSound get current => _current;
  double get volume => _volume;
  bool get isPlaying => _player.playing;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_keySound) ?? 0;
    _volume = prefs.getDouble(_keyVolume) ?? 0.5;
    _current = AmbientSound.values[idx.clamp(0, AmbientSound.values.length - 1)];
    await _player.setVolume(_volume);
  }

  Future<void> play(AmbientSound sound) async {
    if (sound == _current && _player.playing) return;
    _current = sound;
    await _persist();

    await _player.stop();
    final path = sound.assetPath;
    if (path == null) return;

    try {
      await _player.setAsset(path);
      await _player.setLoopMode(LoopMode.one);
      await _player.play();
    } catch (_) {
      // Audio file not yet bundled — silent no-op.
    }
  }

  Future<void> stop() async {
    _current = AmbientSound.none;
    await _player.stop();
    await _persist();
  }

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyVolume, _volume);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySound, _current.index);
  }

  void dispose() => _player.dispose();
}
