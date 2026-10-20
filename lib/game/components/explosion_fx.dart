import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

class _Spark {
  _Spark(this.pos, this.vel, this.radius);
  final Vector2 pos;
  final Vector2 vel;
  final double radius;
}

/// Lightweight additive-blended particle burst (sparks + optional shockwave).
class ExplosionFx extends Component {
  ExplosionFx({
    required Vector2 position,
    required this.color,
    int count = 24,
    double speed = 220,
    double size = 3,
    this.life = 0.7,
    this.ring = false,
    this.drift,
  })  : _origin = position,
        super(priority: 20) {
    final rng = Random();
    for (var i = 0; i < count; i++) {
      final a = rng.nextDouble() * 2 * pi;
      final v = speed * (0.25 + rng.nextDouble() * 0.75);
      _sparks.add(_Spark(
        position.clone(),
        Vector2(cos(a), sin(a)) * v + (drift ?? Vector2.zero()),
        size * (0.5 + rng.nextDouble()),
      ));
    }
  }

  final Color color;
  final double life;
  final bool ring;
  final Vector2? drift;
  final Vector2 _origin;
  final List<_Spark> _sparks = [];
  double _t = 0;

  final Paint _paint = Paint()..blendMode = BlendMode.plus;
  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..blendMode = BlendMode.plus;

  @override
  void update(double dt) {
    _t += dt;
    final damp = 1 - 2.2 * dt;
    for (final s in _sparks) {
      s.pos.addScaled(s.vel, dt);
      s.vel.scale(damp);
    }
    if (_t >= life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / life).clamp(0.0, 1.0);
    final fade = 1 - p;
    _paint.color = color.withValues(alpha: fade);
    for (final s in _sparks) {
      canvas.drawCircle(Offset(s.pos.x, s.pos.y), s.radius * (0.4 + fade * 0.6), _paint);
    }
    if (ring) {
      _ringPaint.color = color.withValues(alpha: fade * 0.8);
      canvas.drawCircle(Offset(_origin.x, _origin.y), 12 + p * 110, _ringPaint);
    }
  }
}
