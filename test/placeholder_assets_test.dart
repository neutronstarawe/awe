import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Placeholder assets exist', () {
    test('22 montage images exist', () {
      for (int i = 1; i <= 22; i++) {
        final num = i.toString().padLeft(2, '0');
        final file = File('assets/images/montage_$num.png');
        expect(file.existsSync(), isTrue,
            reason: 'montage_$num.png should exist');
      }
    });

    test('closing_bg.png exists', () {
      expect(File('assets/images/closing_bg.png').existsSync(), isTrue);
    });

    test('ambient.mp3 stub exists', () {
      expect(File('assets/audio/ambient.mp3').existsSync(), isTrue);
    });

    test('milky_way.mp4 stub exists', () {
      expect(File('assets/video/milky_way.mp4').existsSync(), isTrue);
    });
  });
}
