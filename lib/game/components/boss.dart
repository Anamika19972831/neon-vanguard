import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import 'enemy.dart';

/// Three-phase boss: aimed bursts -> radial rings -> spiral barrage.
class Boss extends Enemy {
  Boss({required Vector2 position, required int wave})
      : _cx = position.x,
        super(
          position: position,
          size: Vector2(150, 108),
          maxHp: 70 + wave * 14,
          points: 1000 + wave * 100,
          color: Palette.red,
        );

  final double _cx;
  bool _entered = false;
  double _fireCd = 1.2;
  double _spiralCd = 0;
  double _spiral = 0;
  bool _ringToggle = false;

  @override
  bool get isBoss => true;

  @override
  double get hitRadius => size.x * .34;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    game.bossHealth.value = 1;
  }

  @override
  void onRemove() {
    game.bossHealth.value = null;
    super.onRemove();
  }

  @override
  void die() {
    game.showBanner('BOSS DESTROYED');
    super.die();
  }

  @override
  Path buildPath(Vector2 s) => Path()
    ..moveTo(s.x / 2, s.y)
    ..lineTo(s.x * .78, s.y * .72)
    ..lineTo(s.x, s.y * .2)
    ..lineTo(s.x * .72, 0)
    ..lineTo(s.x * .5, s.y * .22)
    ..lineTo(s.x * .28, 0)
    ..lineTo(0, s.y * .2)
    ..lineTo(s.x * .22, s.y * .72)
    ..close();

  @override
  void move(double dt) {
    if (!_entered) {
      position.y += 80 * dt;
      if (position.y >= game.size.y * .17) _entered = true;
    } else {
      position.x = _cx + sin(age * .8) * game.size.x * .28;
      position.y = game.size.y * .17 + sin(age * 1.3) * 14;
    }
  }

  @override
  void think(double dt) {
    if (!_entered) return;
    final ratio = hp / maxHp;
    game.bossHealth.value = ratio;
    _fireCd -= dt;

    if (ratio > .6) {
      if (_fireCd <= 0) {
        _fireCd = 1.3;
        final base = game.angleToPlayer(position);
        for (final a in const [-.2, 0.0, .2]) {
          game.fireEnemy(position, base + a);
        }
      }
    } else if (ratio > .3) {
      if (_fireCd <= 0) {
        _fireCd = 1.8;
        _ringToggle = !_ringToggle;
        const n = 14;
        for (var i = 0; i < n; i++) {
          final a = (i / n) * pi * 2 + (_ringToggle ? pi / n : 0);
          game.fireEnemy(position, a, speed: 210);
        }
        game.fireEnemy(position, game.angleToPlayer(position),
            speed: game.bulletSpeed * 1.2);
      }
    } else {
      _spiralCd -= dt;
      if (_spiralCd <= 0) {
        _spiralCd = .09;
        _spiral += .45;
        game.fireEnemy(position, _spiral, speed: 240);
        game.fireEnemy(position, _spiral + pi, speed: 240);
      }
      if (_fireCd <= 0) {
        _fireCd = 1.6;
        final base = game.angleToPlayer(position);
        for (final a in const [-.25, 0.0, .25]) {
          game.fireEnemy(position, base + a, speed: game.bulletSpeed * 1.1);
        }
      }
    }
  }
}
