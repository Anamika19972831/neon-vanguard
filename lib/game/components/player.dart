import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/neon.dart';
import '../neon_vanguard_game.dart';
import 'bullet.dart';
import 'explosion_fx.dart';
import 'power_up.dart';

class Player extends PositionComponent
    with HasGameReference<NeonVanguardGame>, CollisionCallbacks {
  Player() : super(size: Vector2(54, 64), anchor: Anchor.center, priority: 10);

  double hp = Tuning.playerMaxHp;
  double rapidT = 0, spreadT = 0, shieldT = 0;
  final Vector2 keyDir = Vector2.zero();

  double _fireCd = 0, _invuln = 0, _trailCd = 0, _t = 0;

  late final Paint _glow = Neon.glow(Palette.cyan, width: 10, blur: 10);
  late final Paint _outline = Neon.line(Palette.cyan, width: 2.5);
  final Paint _hull = Neon.fill(const Color(0xFF06222B));
  final Paint _cockpit = Neon.fill(Palette.cyan);
  final Paint _engine = Neon.fill(Palette.amber);
  late final Paint _shieldGlow = Neon.glow(Palette.cyan, width: 6, blur: 8);
  late final Paint _shieldLine =
      Neon.line(Palette.cyan.withValues(alpha: .85), width: 2);

  late final Path _hullPath = Path()
    ..moveTo(size.x / 2, 0)
    ..lineTo(size.x, size.y * .9)
    ..lineTo(size.x * .68, size.y * .74)
    ..lineTo(size.x / 2, size.y * .86)
    ..lineTo(size.x * .32, size.y * .74)
    ..lineTo(0, size.y * .9)
    ..close();

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox(
      size: Vector2(26, 40),
      position: size / 2,
      anchor: Anchor.center,
    ));
  }

  void moveBy(Vector2 delta) {
    final s = game.size;
    position.x = clampDouble(position.x + delta.x, 28, s.x - 28);
    position.y = clampDouble(position.y + delta.y, s.y * .25, s.y - 50);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (!game.isPlaying) return;

    if (!keyDir.isZero()) moveBy(keyDir.normalized() * 460 * dt);

    if (_invuln > 0) _invuln -= dt;
    rapidT = max(0.0, rapidT - dt);
    spreadT = max(0.0, spreadT - dt);
    shieldT = max(0.0, shieldT - dt);

    _fireCd -= dt;
    if (_fireCd <= 0) {
      _fire();
      _fireCd = rapidT > 0 ? .085 : .17;
    }

    _trailCd -= dt;
    if (_trailCd <= 0) {
      _trailCd = .04;
      game.spawn(ExplosionFx(
        position: position + Vector2(0, size.y * .45),
        color: Palette.amber,
        count: 2,
        speed: 40,
        size: 2.6,
        life: .3,
        drift: Vector2(0, 170),
      ));
    }

    final parts = <String>[
      if (shieldT > 0) 'SHIELD ${shieldT.ceil()}',
      if (rapidT > 0) 'RAPID ${rapidT.ceil()}',
      if (spreadT > 0) 'SPREAD ${spreadT.ceil()}',
    ];
    game.powerLabel.value = parts.isEmpty ? null : parts.join('   ');
  }

  void _fire() {
    final muzzle = position + Vector2(0, -size.y / 2);
    if (spreadT > 0) {
      for (final a in const [-0.22, 0.0, 0.22]) {
        game.spawn(Bullet(
          position: muzzle.clone(),
          velocity: Vector2(sin(a), -cos(a)) * 900,
          fromPlayer: true,
          color: Palette.lime,
        ));
      }
    } else {
      for (final dx in const [-9.0, 9.0]) {
        game.spawn(Bullet(
          position: muzzle + Vector2(dx, 4),
          velocity: Vector2(0, -900),
          fromPlayer: true,
        ));
      }
    }
    game.audio.play('shoot.wav', volume: .3, minGapMs: 110);
  }

  void takeHit(double dmg) {
    if (!game.isPlaying || _invuln > 0) return;
    if (shieldT > 0) {
      game.shake(4);
      game.spawn(ExplosionFx(
          position: position.clone(),
          color: Palette.cyan,
          count: 10,
          speed: 200,
          size: 2.5,
          life: .3));
      return;
    }
    hp -= dmg;
    _invuln = .9;
    game.health.value = max(0.0, hp / Tuning.playerMaxHp);
    game.resetCombo();
    game.shake(9);
    game.vibrate(heavy: true);
    game.audio.play('hit.wav');
    if (hp <= 0) {
      game.onPlayerDestroyed(position.clone());
      removeFromParent();
    }
  }

  void collect(PowerType type) {
    switch (type) {
      case PowerType.shield:
        shieldT = Tuning.powerDuration;
      case PowerType.rapid:
        rapidT = Tuning.powerDuration;
      case PowerType.spread:
        spreadT = Tuning.powerDuration;
      case PowerType.repair:
        hp = min(Tuning.playerMaxHp, hp + 35);
        game.health.value = hp / Tuning.playerMaxHp;
    }
    game.audio.play('powerup.wav');
    game.vibrate();
  }

  @override
  void render(Canvas canvas) {
    final blink = _invuln > 0 && (_invuln * 14).floor().isEven;
    if (!blink) {
      canvas.drawPath(_hullPath, _glow);
      canvas.drawPath(_hullPath, _hull);
      canvas.drawPath(_hullPath, _outline);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(size.x / 2, size.y * .5), width: 8, height: 18),
          _cockpit);
      final flame = 10 + sin(_t * 40) * 4;
      canvas.drawOval(
          Rect.fromLTWH(size.x / 2 - 5, size.y * .84, 10, flame), _engine);
    }
    if (shieldT > 0) {
      final r = 46 * (1 + sin(_t * 8) * .04);
      final c = Offset(size.x / 2, size.y / 2);
      canvas.drawCircle(c, r, _shieldGlow);
      canvas.drawCircle(c, r, _shieldLine);
    }
  }
}
