import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const _keyHasSeenIntro = 'has_seen_intro';
  static const _keyMontageIndex = 'montage_index';
  static const _keyAudioPositionMs = 'audio_position_ms';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool> get hasSeenIntro async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getBool(_keyHasSeenIntro) ?? false;
  }

  Future<void> setHasSeenIntro(bool value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_keyHasSeenIntro, value);
  }

  Future<int> get montageIndex async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getInt(_keyMontageIndex) ?? 0;
  }

  Future<void> setMontageIndex(int index) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt(_keyMontageIndex, index);
  }

  Future<int> get audioPositionMs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getInt(_keyAudioPositionMs) ?? 0;
  }

  Future<void> setAudioPositionMs(int ms) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt(_keyAudioPositionMs, ms);
  }

  Future<void> clear() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.clear();
  }
}
