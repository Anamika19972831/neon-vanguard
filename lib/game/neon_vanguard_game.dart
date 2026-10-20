import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/audio_service.dart';
import '../core/constants.dart';
import '../core/storage_service.dart';
import 'components/bullet.dart';
import 'components/enemy.dart';
import 'components/explosion_fx.dart';
import 'components/parallax_background.dart';
import 'components/player.dart';
import 'components/power_up.dart';
import 'components/wave_director.dart';

enum GameStatus { menu, playing, paused, gameOver }

class NeonVanguardGame extends FlameGame
    with HasCollisionDetection, DragCallbacks, KeyboardEvents {
  NeonVanguardGame({required this.storage, required this.audio});

  final StorageService storage;
  final AudioService audio;
  final Random rng = Random();

  // ---- Observable state consumed by Flutter HUD overlays ----
  final ValueNotifier<int> score = ValueNotifier(0);
  final ValueNotifier<double> health = ValueNotifier(1);
  final ValueNotifier<int> wave = ValueNotifier(1);
  final ValueNotifier<int> combo = ValueNotifier(1);
  final ValueNotifier<double?> bossHealth = ValueNotifier(null);
  final ValueNotifier<String?> powerLabel = ValueNotifier(null);
  final ValueNotifier<String?> banner = ValueNotifier(null);

  GameStatus status = GameStatus.menu;
  bool newHighScore = false;
  Player? player;

  Component? _root; // parent of every gameplay entity; removed on reset
  double _shake = 0;
  double _comboTimer = 0;
  int _streak = 0;

  bool get isPlaying => status == GameStatus.playing;

  int get enemyCount => _root?.children.whereType<Enemy>().length ?? 0;

  double get bulletSpeed => min(420.0, 240.0 + wave.value * 9.0);

  @override
  Color backgroundColor() => Palette.bgTop;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(ParallaxBackground());
  }

  // ------------------------------------------------------------------
  // Run lifecycle
  // ------------------------------------------------------------------
  void startGame() {
    _clearRun();
    score.value = 0;
    health.value = 1;
    wave.value = 1;
    combo.value = 1;
    bossHealth.value = null;
    powerLabel.value = null;
    banner.value = null;
    newHighScore = false;
    _streak = 0;
    _comboTimer = 0;

    _root = Component();
    world.add(_root!);
    player = Player()..position = Vector2(size.x / 2, size.y * 0.82);
    _root!.add(player!);
    _root!.add(WaveDirector());

    overlays
      ..remove('menu')
      ..remove('gameOver')
      ..remove('pause')
      ..add('hud');
    status = GameStatus.playing;
    resumeEngine();
    audio.playMusic();
  }

  void pauseGame() {
    if (!isPlaying) return;
    status = GameStatus.paused;
    pauseEngine();
    overlays.add('pause');
    audio.pauseMusic();
  }

  void resumeGame() {
    if (status != GameStatus.paused) return;
    overlays.remove('pause');
    status = GameStatus.playing;
    resumeEngine();
    audio.resumeMusic();
  }

  void quitToMenu() {
    _clearRun();
    overlays
      ..remove('pause')
      ..remove('hud')
      ..remove('gameOver')
      ..add('menu');
    status = GameStatus.menu;
    resumeEngine();
    audio.stopMusic();
  }

  void _clearRun() {
    _root?.removeFromParent();
    _root = null;
    player = null;
    _shake = 0;
    camera.viewfinder.position = Vector2.zero();
  }

  void onPlayerDestroyed(Vector2 at) {
    if (!isPlaying) return;
    status = GameStatus.gameOver;
    spawn(ExplosionFx(position: at.clone(), color: Palette.cyan, count: 90, speed: 380, size: 4.5, life: 1.1, ring: true));
    shake(20);
    vibrate(heavy: true);
    audio.play('explosion.wav');
    audio.stopMusic();
    newHighScore = score.value > storage.highScore.value;
    storage.submitScore(score.value);
    overlays.remove('hud');
    _root?.add(TimerComponent(
      period: 1.2,
      removeOnFinish: true,
      onTick: () {
        if (status == GameStatus.gameOver) overlays.add('gameOver');
      },
    ));
  }

  // ------------------------------------------------------------------
  // Gameplay helpers used by components
  // ------------------------------------------------------------------
  void spawn(Component c) => _root?.add(c);

  void registerKill(int basePoints) {
    _streak++;
    combo.value = min(Tuning.maxCombo, 1 + _streak ~/ 3);
    _comboTimer = Tuning.comboWindow;
    score.value += basePoints * combo.value;
  }

  void resetCombo() {
    _streak = 0;
    combo.value = 1;
  }

  void maybeDropPower(Vector2 at, {bool always = false}) {
    if (!always && rng.nextDouble() > Tuning.powerDropChance) return;
    final type = PowerType.values[rng.nextInt(PowerType.values.length)];
    spawn(PowerUp(position: at.clone(), type: type));
  }

  void fireEnemy(Vector2 from, double angle, {double? speed}) {
    spawn(Bullet(
      position: from.clone(),
      velocity: Vector2(sin(angle), cos(angle)) * (speed ?? bulletSpeed),
      fromPlayer: false,
      color: Palette.red,
    ));
  }

  /// Angle measured from straight-down, so direction = (sin a, cos a).
  double angleToPlayer(Vector2 from) {
    final p = player;
    if (p == null) return 0;
    return atan2(p.position.x - from.x, p.position.y - from.y);
  }

  void showBanner(String text) {
    banner.value = text;
    _root?.add(TimerComponent(
      period: 1.8,
      removeOnFinish: true,
      onTick: () {
        if (banner.value == text) banner.value = null;
      },
    ));
  }

  void shake(double intensity) => _shake = max(_shake, intensity);

  void vibrate({bool heavy = false}) {
    if (!storage.hapticsOn.value) return;
    heavy ? HapticFeedback.heavyImpact() : HapticFeedback.selectionClick();
  }

  // ------------------------------------------------------------------
  // Engine hooks
  // ------------------------------------------------------------------
  @override
  void update(double dt) {
    super.update(dt);

    if (_streak > 0 && isPlaying) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) resetCombo();
    }

    if (_shake > 0) {
      camera.viewfinder.position = Vector2(
        (rng.nextDouble() - 0.5) * _shake,
        (rng.nextDouble() - 0.5) * _shake,
      );
      _shake -= 45 * dt;
      if (_shake <= 0) {
        _shake = 0;
        camera.viewfinder.position = Vector2.zero();
      }
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (isPlaying) {
      player?.moveBy(event.localDelta * Tuning.dragSensitivity);
    }
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keys) {
    final dir = Vector2.zero();
    if (keys.contains(LogicalKeyboardKey.arrowLeft) ||
        keys.contains(LogicalKeyboardKey.keyA)) {
      dir.x -= 1;
    }
    if (keys.contains(LogicalKeyboardKey.arrowRight) ||
        keys.contains(LogicalKeyboardKey.keyD)) {
      dir.x += 1;
    }
    if (keys.contains(LogicalKeyboardKey.arrowUp) ||
        keys.contains(LogicalKeyboardKey.keyW)) {
      dir.y -= 1;
    }
    if (keys.contains(LogicalKeyboardKey.arrowDown) ||
        keys.contains(LogicalKeyboardKey.keyS)) {
      dir.y += 1;
    }
    player?.keyDir.setFrom(dir);

    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      if (isPlaying) {
        pauseGame();
      } else if (status == GameStatus.paused) {
        resumeGame();
      }
    }
    return KeyEventResult.handled;
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    // Auto-pause when the app loses focus (we deliberately don't call super,
    // which would resume the engine behind our pause menu).
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      pauseGame();
    }
  }
}
