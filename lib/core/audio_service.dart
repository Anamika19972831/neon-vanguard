import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';

/// Thin, failure-tolerant wrapper around flame_audio.
/// If audio cannot initialise (some desktop setups), the game still runs silently.
class AudioService {
  AudioService(this._storage);

  final StorageService _storage;
  static const _sfx = [
    'shoot.wav',
    'explosion.wav',
    'hit.wav',
    'powerup.wav',
    'boss.wav',
  ];

  bool _ready = false;
  bool _musicWanted = false;
  final Map<String, int> _lastPlayedMs = {};

  Future<void> init() async {
    try {
      await FlameAudio.audioCache.loadAll([..._sfx, 'bgm.wav']);
      await FlameAudio.bgm.initialize();
      _ready = true;
    } catch (e) {
      debugPrint('Audio disabled: $e');
    }
    _storage.soundOn.addListener(_applyMusic);
  }

  void play(String name, {double volume = 1, int minGapMs = 0}) {
    if (!_ready || !_storage.soundOn.value) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastPlayedMs[name] ?? 0;
    if (now - last < minGapMs) return;
    _lastPlayedMs[name] = now;
    unawaited(_safe(() => FlameAudio.play(name, volume: volume)));
  }

  void playMusic() {
    _musicWanted = true;
    _applyMusic();
  }

  void stopMusic() {
    _musicWanted = false;
    _applyMusic();
  }

  void pauseMusic() {
    if (_ready) unawaited(_safe(() => FlameAudio.bgm.pause()));
  }

  void resumeMusic() {
    if (_ready && _musicWanted && _storage.soundOn.value) {
      unawaited(_safe(() => FlameAudio.bgm.resume()));
    }
  }

  void _applyMusic() {
    if (!_ready) return;
    if (_musicWanted && _storage.soundOn.value) {
      unawaited(_safe(() => FlameAudio.bgm.play('bgm.wav', volume: 0.4)));
    } else {
      unawaited(_safe(() => FlameAudio.bgm.stop()));
    }
  }

  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }
}
