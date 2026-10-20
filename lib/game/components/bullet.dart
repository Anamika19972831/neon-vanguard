import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/neon.dart';
import '../neon_vanguard_game.dart';
import 'enemy.dart';
import 'explosion_fx.dart';
import 'player.dart';

class Bullet extends PositionComponent
    with HasGameReference<NeonVanguardGame>, CollisionCallbacks {
  Bullet({
    required Vector2 position,
    required this.velocity,
    required this.fromPlayer,
    this.damage = 1,
    this.color = Palette.cyan,
  }) : super(
          position: position,
          size: fromPlayer ? Vector2(6, 22) : Vector2.all(12),
          anchor: Anchor.center,
          priority: 8,
        ) {
    angle = atan2(velocity.x, -velocity.y); // point sprite along travel
  }

  final Vector2 velocity;
  final bool fromPlayer;
  final int damage;
  final Color color;
  bool _spent = false;

  late final Paint _glow = Neon.glow(color, width: 10, blur: 7, alpha: .8);
  final Paint _core = Neon.fill(Colors.white);

  @override
  Future<void> onLoad() async {
    final hb = fromPlayer ? RectangleHitbox() : CircleHitbox();
    add(hb);
  }

  @override
  void update(double dt) {
    position.addScaled(velocity, dt);
    final s = game.size;
    if (position.y < -40 ||
        position.y > s.y + 40 ||
        position.x < -40 ||
        position.x > s.x + 40) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (fromPlayer) {
      final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(3));
      canvas.drawRRect(r, _glow);
      canvas.drawRRect(r, _core);
    } else {
      final c = Offset(size.x / 2, size.y / 2);
      canvas.drawCircle(c, size.x * .5, _glow);
      canvas.drawCircle(c, size.x * .3, _core);
    }
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    super.onCollisionStart(points, other);
    if (_spent) return;
    if (fromPlayer && other is Enemy) {
      other.takeDamage(damage);
      _impact();
    } else if (!fromPlayer && other is Player) {
      other.takeHit(damage.toDouble() * 10);
      _impact();
    }
  }

  void _impact() {
    _spent = true;
    game.spawn(ExplosionFx(
      position: position.clone(),
      color: color,
      count: 6,
      speed: 130,
      size: 2.2,
      life: .25,
    ));
    removeFromParent();
  }
}
