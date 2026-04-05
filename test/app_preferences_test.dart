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
  });
}
