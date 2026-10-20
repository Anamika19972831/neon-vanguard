import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists high score and user settings.
class StorageService {
  StorageService._(SharedPreferences prefs)
      : _prefs = prefs,
        highScore = ValueNotifier(prefs.getInt(_kHigh) ?? 0),
        soundOn = ValueNotifier(prefs.getBool(_kSound) ?? true),
        hapticsOn = ValueNotifier(prefs.getBool(_kHaptics) ?? true);

  static const _kHigh = 'high_score';
  static const _kSound = 'sound_on';
  static const _kHaptics = 'haptics_on';

  final SharedPreferences _prefs;
  final ValueNotifier<int> highScore;
  final ValueNotifier<bool> soundOn;
  final ValueNotifier<bool> hapticsOn;

  static Future<StorageService> load() async =>
      StorageService._(await SharedPreferences.getInstance());

  Future<void> submitScore(int score) async {
    if (score > highScore.value) {
      highScore.value = score;
      await _prefs.setInt(_kHigh, score);
    }
  }

  Future<void> setSound(bool v) async {
    soundOn.value = v;
    await _prefs.setBool(_kSound, v);
  }

  Future<void> setHaptics(bool v) async {
    hapticsOn.value = v;
    await _prefs.setBool(_kHaptics, v);
  }
}
