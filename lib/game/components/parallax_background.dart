import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show RadialGradient, LinearGradient, Alignment;

import '../../core/constants.dart';
import '../neon_vanguard_game.dart';

class _Star {
  _Star(this.x, this.y, this.depth);
  final double x; // 0..1
  double y; // 0..1
  final double depth; // 0..1
}

class _Nebula {
  _Nebula(this.cx, this.cy, this.r, this.color, this.phase);
  final double cx, cy, r, phase;
  final Color color;
}

/// Layered starfield, drifting nebulae and a faint synthwave grid.
class ParallaxBackground extends Component with HasGameReference<NeonVanguardGame> {
  ParallaxBackground() : super(priority: -100);

  final Random _rng = Random(7);
  final List<_Star> _stars = [];
  late final List<_Nebula> _nebulae;
  double _t = 0;
  double _gridOffset = 0;

  final Paint _starPaint = Paint();
  final Paint _bgPaint = Paint();
  final Paint _nebPaint = Paint();
  final Paint _gridPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < 90; i++) {
      _stars.add(_Star(_rng.nextDouble(), _rng.nextDouble(), _rng.nextDouble()));
    }
    _nebulae = [
      _Nebula(.2, .25, .55, Palette.violet, 0),
      _Nebula(.85, .55, .5, Palette.magenta, 2),
      _Nebula(.4, .85, .6, Palette.cyan, 4),
    ];
  }

  @override
  void update(double dt) {
    _t += dt;
    final h = game.size.y;
    // Slightly faster scroll while playing for a sense of speed.
    final boost = game.isPlaying ? 1.6 : 1.0;
    for (final s in _stars) {
      s.y += (18 + s.depth * 150) * boost * dt / h;
      if (s.y > 1) s.y -= 1;
    }
    _gridOffset = (_gridOffset + dt * .35 * boost) % 1;
  }

  @override
  void render(Canvas canvas) {
    final w = game.size.x;
    final h = game.size.y;
    final rect = Rect.fromLTWH(-24, -24, w + 48, h + 48);

    _bgPaint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Palette.bgTop, Palette.bgBottom],
    ).createShader(rect);
    canvas.drawRect(rect, _bgPaint);

    for (final n in _nebulae) {
      final cx = (n.cx + sin(_t * .08 + n.phase) * .06) * w;
      final cy = (n.cy + cos(_t * .06 + n.phase) * .05) * h;
      final r = n.r * w;
      _nebPaint.shader = RadialGradient(colors: [
        n.color.withValues(alpha: .22),
        n.color.withValues(alpha: 0),
      ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, _nebPaint);
    }

    _drawGrid(canvas, w, h);

    for (final s in _stars) {
      final tw = .65 + .35 * sin(_t * 2 + s.x * 40);
      _starPaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: (.25 + s.depth * .75) * tw);
      canvas.drawCircle(Offset(s.x * w, s.y * h), .5 + s.depth * 1.6, _starPaint);
    }
  }

  void _drawGrid(Canvas canvas, double w, double h) {
    final horizon = h * .58;
    final gridColor = Palette.magenta;
    // horizontal lines (perspective spacing)
    for (var i = 0; i < 10; i++) {
      final t = ((i + _gridOffset) / 10);
      final y = horizon + (h - horizon) * t * t;
      _gridPaint.color = gridColor.withValues(alpha: .05 + .13 * t);
      canvas.drawLine(Offset(0, y), Offset(w, y), _gridPaint);
    }
    // converging vertical lines
    for (var i = -6; i <= 6; i++) {
      final topX = w / 2 + i * w * .03;
      final botX = w / 2 + i * w * .22;
      _gridPaint.color = gridColor.withValues(alpha: .10);
      canvas.drawLine(Offset(topX, horizon), Offset(botX, h), _gridPaint);
    }
  }
}
