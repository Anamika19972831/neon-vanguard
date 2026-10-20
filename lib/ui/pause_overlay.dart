import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../game/neon_vanguard_game.dart';
import 'widgets.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.game});
  final NeonVanguardGame game;

  @override
  Widget build(BuildContext context) {
    return PanelBackdrop(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NeonText('PAUSED', size: 38),
          const SizedBox(height: 36),
          NeonButton(label: 'RESUME', onPressed: game.resumeGame),
          const SizedBox(height: 14),
          NeonButton(
            label: 'RESTART',
            color: Palette.amber,
            onPressed: game.startGame,
          ),
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
