import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const _keyHasSeenIntro = 'has_seen_intro';
  static const _keyMontageIndex = 'montage_index';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool> get hasSeenIntro async {
    return _prefs.getBool(_keyHasSeenIntro) ?? false;
  }

  Future<void> setHasSeenIntro(bool value) async {
    await _prefs.setBool(_keyHasSeenIntro, value);
  }

  Future<int> get montageIndex async {
    return _prefs.getInt(_keyMontageIndex) ?? 0;
  }

  Future<void> setMontageIndex(int value) async {
    await _prefs.setInt(_keyMontageIndex, value);
  }
}
