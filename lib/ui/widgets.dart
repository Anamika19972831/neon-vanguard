import 'package:flutter/material.dart';

import '../core/constants.dart';

class NeonButton extends StatelessWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = Palette.cyan,
    this.width = 250,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: color.withValues(alpha: .12),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: .45), blurRadius: 18),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }
}

class NeonText extends StatelessWidget {
  const NeonText(this.text,
      {super.key, this.size = 40, this.color = Palette.cyan, this.spacing = 6});

  final String text;
  final double size;
  final Color color;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: spacing,
        color: Colors.white,
        shadows: [
          Shadow(color: color, blurRadius: 12),
          Shadow(color: color.withValues(alpha: .6), blurRadius: 28),
        ],
      ),
    );
  }
}

class NeonBar extends StatelessWidget {
  const NeonBar({super.key, required this.value, required this.color, this.height = 10});

  final double value; // 0..1
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height),
        color: Colors.white12,
        border: Border.all(color: color.withValues(alpha: .6)),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height),
              color: color,
              boxShadow: [BoxShadow(color: color.withValues(alpha: .7), blurRadius: 8)],
            ),
          ),
        ),
      ),
    );
  }
}

String formatScore(int n) => n.toString().padLeft(6, '0');

class PanelBackdrop extends StatelessWidget {
  const PanelBackdrop({super.key, required this.child, this.opacity = .72});
  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: opacity),
      child: SafeArea(child: Center(child: child)),
    );
  }
}
