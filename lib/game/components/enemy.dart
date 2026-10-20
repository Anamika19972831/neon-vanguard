import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/neon.dart';
import '../neon_vanguard_game.dart';
import 'explosion_fx.dart';
import 'player.dart';

/// Base class: shared rendering, damage, death and collision behaviour.
abstract class Enemy extends PositionComponent
    with HasGameReference<NeonVanguardGame>, CollisionCallbacks {
  Enemy({
    required Vector2 position,
    required Vector2 size,
    required this.maxHp,
    required this.points,
    required this.color,
  })  : hp = maxHp,
        super(position: position, size: size, anchor: Anchor.center, priority: 5);

  final int maxHp;
  int hp;
  final int points;
  final Color color;

  double age = 0;
  double _flash = 0;
  bool _dead = false;

  bool get isBoss => false;
  double get hitRadius => size.x * .38;

  Path buildPath(Vector2 s);
  void move(double dt);
  void think(double dt) {}

  late final Path _path = buildPath(size);
  late final Paint _glow = Neon.glow(color, width: 8, blur: 9);
  late final Paint _line = Neon.line(color, width: 2.4);
  late final Paint _dark = Neon.fill(Color.lerp(Colors.black, color, .18)!);
  late final Paint _core = Neon.fill(color);
  final Paint _white = Neon.fill(Colors.white);

  @override
  Future<void> onLoad() async {
    final hb = CircleHitbox(
        radius: hitRadius, position: size / 2, anchor: Anchor.center)
      ..collisionType = CollisionType.passive;
    add(hb);
  }

  @override
  void update(double dt) {
    super.update(dt);
    age += dt;
    if (_flash > 0) _flash -= dt;
    move(dt);
    if (game.isPlaying && position.y > 10) think(dt);
    if (position.y > game.size.y + size.y) removeFromParent();
  }

  void takeDamage(int d) {
    if (_dead) return;
    hp -= d;
    _flash = .07;
    if (hp <= 0) die();
  }

  void die() {
    if (_dead) return;
    _dead = true;
    game.registerKill(points);
    game.spawn(ExplosionFx(
      position: position.clone(),
      color: color,
      count: isBoss ? 140 : 26,
      speed: isBoss ? 420 : 240,
      size: isBoss ? 5 : 3.2,
      life: isBoss ? 1.2 : .7,
      ring: size.x > 60,
    ));
    game.shake(isBoss ? 22 : 4);
    game.audio.play('explosion.wav', volume: isBoss ? 1 : .55, minGapMs: 50);
    game.maybeDropPower(position, always: isBoss);
    removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    super.onCollisionStart(points, other);
    if (other is Player) {
      other.takeHit(isBoss ? 35 : 20);
      if (!isBoss) die();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawPath(_path, _glow);
    canvas.drawPath(_path, _flash > 0 ? _white : _dark);
    canvas.drawPath(_path, _line);
    canvas.drawCircle(Offset(size.x / 2, size.y * .45), size.x * .07, _core);
  }
}

/// Fast, fragile, flies straight down with a slight wobble.
class Drone extends Enemy {
  Drone({required Vector2 position, required this.speed})
      : _phase = Random().nextDouble() * 6,
        super(
          position: position,
          size: Vector2.all(38),
          maxHp: 1,
          points: 10,
          color: Palette.magenta,
        );

  final double speed;
  final double _phase;

  @override
  Path buildPath(Vector2 s) => Path()
    ..moveTo(s.x / 2, s.y)
    ..lineTo(s.x, s.y * .12)
    ..lineTo(s.x / 2, s.y * .34)
    ..lineTo(0, s.y * .12)
    ..close();

  @override
  void move(double dt) {
    position.y += speed * dt;
    position.x += sin(age * 3 + _phase) * 50 * dt;
  }
}

/// Weaves side to side and fires aimed shots.
class Weaver extends Enemy {
  Weaver({required Vector2 position, required this.speed, required this.wave})
      : _baseX = position.x,
        _fireCd = 1 + Random().nextDouble() * 1.5,
        super(
          position: position,
          size: Vector2(46, 42),
          maxHp: 3,
          points: 25,
          color: Palette.amber,
        );

  final double speed;
  final int wave;
  final double _baseX;
  double _fireCd;

  @override
  Path buildPath(Vector2 s) => Path()
    ..moveTo(s.x / 2, s.y)
    ..lineTo(s.x, s.y * .5)
    ..lineTo(s.x * .8, 0)
    ..lineTo(s.x / 2, s.y * .25)
    ..lineTo(s.x * .2, 0)
    ..lineTo(0, s.y * .5)
    ..close();

  @override
  void move(double dt) {
    position.y += speed * dt;
    position.x = clampDouble(_baseX + sin(age * 2.2) * 70, 30, game.size.x - 30);
  }

  @override
  void think(double dt) {
    _fireCd -= dt;
    if (_fireCd <= 0) {
      _fireCd = max(1.1, 2.4 - wave * .08);
      game.fireEnemy(position, game.angleToPlayer(position));
    }
  }
}

/// Slow armoured gunship with a 3-way fan.
class Tank extends Enemy {
  Tank({required Vector2 position, required this.wave})
      : _fireCd = 1.2,
        super(
          position: position,
          size: Vector2(70, 64),
          maxHp: 10,
          points: 60,
          color: Palette.violet,
        );

  final int wave;
  double _fireCd;

  @override
  Path buildPath(Vector2 s) => Path()
    ..moveTo(s.x * .25, 0)
    ..lineTo(s.x * .75, 0)
    ..lineTo(s.x, s.y * .5)
    ..lineTo(s.x * .75, s.y)
    ..lineTo(s.x * .25, s.y)
    ..lineTo(0, s.y * .5)
    ..close();

  @override
  void move(double dt) {
    position.y += (position.y < game.size.y * .22 ? 70 : 28) * dt;
    position.x += sin(age * .8) * 22 * dt;
  }

  @override
  void think(double dt) {
    _fireCd -= dt;
    if (_fireCd <= 0) {
      _fireCd = max(1.4, 2.5 - wave * .05);
      final base = game.angleToPlayer(position);
      for (final a in const [-.35, 0.0, .35]) {
        game.fireEnemy(position, base + a, speed: game.bulletSpeed * .9);
      }
    }
  }
}
