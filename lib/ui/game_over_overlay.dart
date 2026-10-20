import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../game/neon_vanguard_game.dart';
import 'widgets.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});
  final NeonVanguardGame game;

  @override
  Widget build(BuildContext context) {
    return PanelBackdrop(
      opacity: .8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NeonText('GAME OVER', size: 36, color: Palette.red),
          const SizedBox(height: 24),
          Text(formatScore(game.score.value),
              style: const TextStyle(
                  fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: 3)),
          const SizedBox(height: 4),
          if (game.newHighScore)
            const Text('NEW BEST!',
                style: TextStyle(
                    color: Palette.amber,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4))
          else
            Text('BEST  ${formatScore(game.storage.highScore.value)}',
                style: const TextStyle(color: Colors.white60, letterSpacing: 3)),
          const SizedBox(height: 8),
          Text('Reached wave ${game.wave.value}',
              style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 36),
          NeonButton(label: 'RETRY', onPressed: game.startGame),
          const SizedBox(height: 14),
          NeonButton(
            label: 'MAIN MENU',
            color: Palette.violet,
            onPressed: game.quitToMenu,
          ),
        ],
      ),
    );
  }
}
