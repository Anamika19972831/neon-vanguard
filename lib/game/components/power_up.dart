import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/neon.dart';
import '../neon_vanguard_game.dart';
import 'explosion_fx.dart';
import 'player.dart';

enum PowerType {
  shield(Palette.cyan, 'S'),
  rapid(Palette.amber, 'R'),
  spread(Palette.lime, 'W'),
  repair(Palette.red, '+');

  const PowerType(this.color, this.letter);
  final Color color;
  final String letter;
}

class PowerUp extends PositionComponent
    with HasGameReference<NeonVanguardGame>, CollisionCallbacks {
  PowerUp({required Vector2 position, required this.type})
      : super(
            position: position,
            size: Vector2.all(36),
            anchor: Anchor.center,
            priority: 6);

  final PowerType type;
  double _t = 0;

  late final Paint _glow = Neon.glow(type.color, width: 8, blur: 8);
  late final Paint _ring = Neon.line(type.color, width: 2.5);
  late final Paint _bg = Neon.fill(Colors.black.withValues(alpha: .6));
  late final TextPainter _label = TextPainter(
    text: TextSpan(
      text: type.letter,
      style: TextStyle(
          color: type.color, fontSize: 18, fontWeight: FontWeight.w900),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  Future<void> onLoad() async {
    final hb = CircleHitbox(radius: 18, position: size / 2, anchor: Anchor.center)
      ..collisionType = CollisionType.passive;
    add(hb);
  }

  @override
  void update(double dt) {
    _t += dt;
    position.y += 110 * dt;
    position.x += sin(_t * 3) * 25 * dt;
    if (position.y > game.size.y + 40) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    final r = 16 + sin(_t * 6) * 1.5;
    canvas.drawCircle(c, r, _bg);
    canvas.drawCircle(c, r, _glow);
    canvas.drawCircle(c, r, _ring);
    _label.paint(canvas, Offset(c.dx - _label.width / 2, c.dy - _label.height / 2));
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    super.onCollisionStart(points, other);
    if (other is Player) {
      other.collect(type);
      game.spawn(ExplosionFx(
          position: position.clone(),
          color: type.color,
          count: 18,
          speed: 220,
          size: 2.6,
          life: .5,
          ring: true));
      removeFromParent();
    }
  }
}
