import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const _keyHasSeenIntro = 'has_seen_intro';

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
}
