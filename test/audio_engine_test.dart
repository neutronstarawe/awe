import 'package:flutter_test/flutter_test.dart';
import 'package:awe/core/audio_engine.dart';
import 'fakes.dart';

void main() {
  group('AudioEngine', () {
    test('initial isPlaying is false', () {
      final engine = AudioEngine(player: FakeAudioPlayer());
      expect(engine.isPlaying, isFalse);
    });

    test('initial position is Duration.zero', () {
      final engine = AudioEngine(player: FakeAudioPlayer());
      expect(engine.position, equals(Duration.zero));
    });

    test('play() sets isPlaying to true', () async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      await engine.play();
      expect(engine.isPlaying, isTrue);
    });

    test('pause() sets isPlaying to false', () async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      await engine.play();
      await engine.pause();
      expect(engine.isPlaying, isFalse);
    });

    test('seek() updates position', () async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      const target = Duration(seconds: 30);
      await engine.seek(target);
      expect(engine.position, equals(target));
    });

    test('load() does not throw on error', () async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      expect(() async => await engine.load('assets/audio/ambient.mp3'),
          returnsNormally);
    });

    test('play() notifies listeners', () async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      int notifyCount = 0;
      engine.addListener(() => notifyCount++);
      await engine.play();
      expect(notifyCount, greaterThan(0));
    });

    test('pause() notifies listeners', () async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      int notifyCount = 0;
      await engine.play();
      engine.addListener(() => notifyCount++);
      await engine.pause();
      expect(notifyCount, greaterThan(0));
    });

    test('disposeEngine() does not throw', () async {
      final engine = AudioEngine(player: FakeAudioPlayer());
      expect(() async => await engine.disposeEngine(), returnsNormally);
    });
  });
}
