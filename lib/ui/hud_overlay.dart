import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../game/neon_vanguard_game.dart';
import 'widgets.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.game});
  final NeonVanguardGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Everything except the pause button ignores touches so the
          // drag gesture reaches the game underneath.
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 64, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable: game.score,
                        builder: (_, s, __) => Text(
                          formatScore(s),
                          style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ValueListenableBuilder<int>(
                        valueListenable: game.combo,
                        builder: (_, c, __) => AnimatedOpacity(
                          opacity: c > 1 ? 1 : 0,
                          duration: const Duration(milliseconds: 150),
                          child: Text('x$c',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Palette.amber)),
                        ),
                      ),
                      const Spacer(),
                      ValueListenableBuilder<int>(
                        valueListenable: game.wave,
                        builder: (_, w, __) => Text('WAVE $w',
                            style: const TextStyle(
                                color: Palette.cyan,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<double>(
                    valueListenable: game.health,
                    builder: (_, h, __) => NeonBar(
                      value: h,
                      color: h > .35 ? Palette.lime : Palette.red,
                    ),
                  ),
                  ValueListenableBuilder<double?>(
                    valueListenable: game.bossHealth,
                    builder: (_, b, __) => b == null
                        ? const SizedBox(height: 12)
                        : Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('BOSS',
                                    style: TextStyle(
                                        color: Palette.red,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 3,
                                        fontSize: 12)),
                                const SizedBox(height: 3),
                                NeonBar(value: b, color: Palette.red, height: 8),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<String?>(
                    valueListenable: game.powerLabel,
                    builder: (_, p, __) => p == null
                        ? const SizedBox.shrink()
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Palette.cyan.withValues(alpha: .15),
                              border: Border.all(color: Palette.cyan),
                            ),
                            child: Text(p,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5)),
                          ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 2,
            child: IconButton(
              onPressed: game.pauseGame,
              icon: const Icon(Icons.pause_circle_outline_rounded, size: 34),
              color: Colors.white,
            ),
          ),
          Center(
            child: IgnorePointer(
              child: ValueListenableBuilder<String?>(
                valueListenable: game.banner,
                builder: (_, text, __) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: text == null
                      ? const SizedBox.shrink(key: ValueKey('none'))
                      : NeonText(text,
                          key: ValueKey(text),
                          size: 30,
                          spacing: 5,
                          color: text.contains('BOSS') ? Palette.red : Palette.cyan),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
