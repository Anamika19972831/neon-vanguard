import 'dart:ui';

/// Paint factories for the glowing neon look.
abstract final class Neon {
  static Paint glow(Color c,
          {double width = 8, double blur = 8, double alpha = 0.6}) =>
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = c.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

  static Paint line(Color c, {double width = 2}) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..color = c;

  static Paint fill(Color c) => Paint()..color = c;
}
