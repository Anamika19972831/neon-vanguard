import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/storage_service.dart';
import '../game/neon_vanguard_game.dart';
import 'widgets.dart';

class MainMenuOverlay extends StatefulWidget {
  const MainMenuOverlay({super.key, required this.game});
  final NeonVanguardGame game;

  @override
  State<MainMenuOverlay> createState() => _MainMenuOverlayState();
}

class _MainMenuOverlayState extends State<MainMenuOverlay> {
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    final storage = widget.game.storage;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: .15),
            Colors.black.withValues(alpha: .75),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _showSettings
                ? _settings(storage)
                : _main(storage),
          ),
        ),
      ),
    );
  }

  Widget _main(StorageService storage) {
    return Column(
      key: const ValueKey('main'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const NeonText('NEON', size: 56, spacing: 14),
        const NeonText('VANGUARD', size: 36, color: Palette.magenta, spacing: 10),
        const SizedBox(height: 18),
        ValueListenableBuilder<int>(
          valueListenable: storage.highScore,
          builder: (_, s, __) => Text('BEST  ${formatScore(s)}',
              style: const TextStyle(
                  color: Colors.white70, letterSpacing: 3, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 40),
        NeonButton(label: 'PLAY', onPressed: widget.game.startGame),
        const SizedBox(height: 16),
        NeonButton(
          label: 'SETTINGS',
          color: Palette.violet,
          onPressed: () => setState(() => _showSettings = true),
        ),
        const SizedBox(height: 36),
        const Text('Drag to steer  -  ship auto-fires\nWASD / arrows + Esc on desktop',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.6)),
      ],
    );
  }

  Widget _settings(StorageService storage) {
    Widget row(String label, ValueNotifier<bool> n, Future<void> Function(bool) set) {
      return SizedBox(
        width: 260,
        child: ValueListenableBuilder<bool>(
          valueListenable: n,
          builder: (_, v, __) => Row(
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 15)),
              const Spacer(),
              Switch(value: v, onChanged: set),
            ],
          ),
        ),
      );
    }

    return Column(
      key: const ValueKey('settings'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const NeonText('SETTINGS', size: 30, spacing: 6),
        const SizedBox(height: 28),
        row('SOUND', storage.soundOn, storage.setSound),
        const SizedBox(height: 8),
        row('HAPTICS', storage.hapticsOn, storage.setHaptics),
        const SizedBox(height: 32),
        NeonButton(
          label: 'BACK',
          color: Palette.violet,
          onPressed: () => setState(() => _showSettings = false),
        ),
      ],
    );
  }
}
