import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:awe/core/audio_engine.dart';

/// A fake AudioPlayer that records calls without actually playing audio.
class _FakePlayer extends Fake implements AudioPlayer {
  bool _playing = false;
  Duration _position = Duration.zero;
  final _playerStateController = Stream<PlayerState>.empty();
  final _positionController = Stream<Duration>.empty();

  @override
  Stream<PlayerState> get playerStateStream => _playerStateController;

  @override
  Stream<Duration> get positionStream => _positionController;

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

void main() {
  group('AudioEngine', () {
    test('initial isPlaying is false', () {
      final engine = AudioEngine(player: _FakePlayer());
      expect(engine.isPlaying, isFalse);
    });

    test('initial position is Duration.zero', () {
      final engine = AudioEngine(player: _FakePlayer());
      expect(engine.position, equals(Duration.zero));
    });

    test('play() sets isPlaying to true', () async {
      final engine = AudioEngine(player: _FakePlayer());
      await engine.play();
      expect(engine.isPlaying, isTrue);
    });

    test('pause() sets isPlaying to false', () async {
      final engine = AudioEngine(player: _FakePlayer());
      await engine.play();
      await engine.pause();
      expect(engine.isPlaying, isFalse);
    });

    test('seek() updates position', () async {
      final engine = AudioEngine(player: _FakePlayer());
      const target = Duration(seconds: 30);
      await engine.seek(target);
      expect(engine.position, equals(target));
    });

    test('load() does not throw on error', () async {
      // Uses a fake player that quietly handles load
      final engine = AudioEngine(player: _FakePlayer());
      expect(() async => await engine.load('assets/audio/ambient.mp3'),
          returnsNormally);
    });

    test('play() notifies listeners', () async {
      final engine = AudioEngine(player: _FakePlayer());
      int notifyCount = 0;
      engine.addListener(() => notifyCount++);
      await engine.play();
      expect(notifyCount, greaterThan(0));
    });

    test('pause() notifies listeners', () async {
      final engine = AudioEngine(player: _FakePlayer());
      int notifyCount = 0;
      await engine.play();
      engine.addListener(() => notifyCount++);
      await engine.pause();
      expect(notifyCount, greaterThan(0));
    });

    test('disposeEngine() does not throw', () async {
      final engine = AudioEngine(player: _FakePlayer());
      expect(() async => await engine.disposeEngine(), returnsNormally);
    });
  });
}
