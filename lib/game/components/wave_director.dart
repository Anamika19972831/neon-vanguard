import 'dart:math';

import 'package:flame/components.dart';

import '../../core/constants.dart';
import '../neon_vanguard_game.dart';
import 'boss.dart';
import 'enemy.dart';

/// Spawns waves, escalates difficulty, and triggers a boss every N waves.
class WaveDirector extends Component with HasGameReference<NeonVanguardGame> {
  final Random _rng = Random();

  bool _waveActive = false;
  int _toSpawn = 0;
  double _spawnCd = 0;
  double _intermission = 1.4;
  double _checkCd = 0;

  @override
  void update(double dt) {
    if (!game.isPlaying) return;

    if (!_waveActive) {
      _intermission -= dt;
      if (_intermission <= 0) _startWave();
      return;
    }

    if (_toSpawn > 0) {
      _spawnCd -= dt;
      if (_spawnCd <= 0) {
        _spawnOne();
        _toSpawn--;
        final w = game.wave.value;
        _spawnCd = max(.35, 1.1 - w * .05) + _rng.nextDouble() * .3;
      }
      return;
    }

    _checkCd -= dt;
    if (_checkCd <= 0) {
      _checkCd = .3;
      if (game.enemyCount == 0) {
        game.score.value += 100 * game.wave.value; // wave clear bonus
        game.wave.value++;
        _waveActive = false;
        _intermission = 2.0;
      }
    }
  }

  void _startWave() {
    final w = game.wave.value;
    final isBossWave = w % Tuning.bossEveryNWaves == 0;
    _waveActive = true;
    _spawnCd = 0;
    if (isBossWave) {
      _toSpawn = 4;
      game.showBanner('WARNING  -  BOSS');
      game.audio.play('boss.wav');
      game.spawn(Boss(position: Vector2(game.size.x / 2, -100), wave: w));
    } else {
      _toSpawn = 6 + w * 2;
      game.showBanner('WAVE $w');
    }
  }

  void _spawnOne() {
    final w = game.wave.value;
    const margin = 40.0;
    final x = margin + _rng.nextDouble() * (game.size.x - margin * 2);
    final pos = Vector2(x, -50);
    final roll = _rng.nextDouble();
    final speed = 110 + w * 7.0;

    final Enemy e;
    if (w >= 4 && roll < .18) {
      e = Tank(position: pos, wave: w);
    } else if (w >= 2 && roll < .5) {
      e = Weaver(position: pos, speed: speed * .8, wave: w);
    } else {
      e = Drone(position: pos, speed: speed);
    }
    game.spawn(e);
  }
}
