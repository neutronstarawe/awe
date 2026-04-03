import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awe/core/app_preferences.dart';

void main() {
  group('AppPreferences', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('hasSeenIntro defaults to false', () async {
      final prefs = AppPreferences();
      await prefs.init();
      expect(await prefs.hasSeenIntro, isFalse);
    });

    test('setHasSeenIntro persists true', () async {
      final prefs = AppPreferences();
      await prefs.init();
      await prefs.setHasSeenIntro(true);
      expect(await prefs.hasSeenIntro, isTrue);
    });

    test('setHasSeenIntro can be reset to false', () async {
      final prefs = AppPreferences();
      await prefs.init();
      await prefs.setHasSeenIntro(true);
      await prefs.setHasSeenIntro(false);
      expect(await prefs.hasSeenIntro, isFalse);
    });

    test('montageIndex defaults to 0', () async {
      final prefs = AppPreferences();
      await prefs.init();
      expect(await prefs.montageIndex, equals(0));
    });

    test('setMontageIndex persists value', () async {
      final prefs = AppPreferences();
      await prefs.init();
      await prefs.setMontageIndex(7);
      expect(await prefs.montageIndex, equals(7));
    });

    test('audioPositionMs defaults to 0', () async {
      final prefs = AppPreferences();
      await prefs.init();
      expect(await prefs.audioPositionMs, equals(0));
    });

    test('setAudioPositionMs persists value', () async {
      final prefs = AppPreferences();
      await prefs.init();
      await prefs.setAudioPositionMs(45000);
      expect(await prefs.audioPositionMs, equals(45000));
    });

    test('clear resets all values', () async {
      final prefs = AppPreferences();
      await prefs.init();
      await prefs.setHasSeenIntro(true);
      await prefs.setMontageIndex(5);
      await prefs.setAudioPositionMs(12000);
      await prefs.clear();
      expect(await prefs.hasSeenIntro, isFalse);
      expect(await prefs.montageIndex, equals(0));
      expect(await prefs.audioPositionMs, equals(0));
    });
  });
}
