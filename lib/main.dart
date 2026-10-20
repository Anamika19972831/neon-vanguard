import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/audio_service.dart';
import 'core/constants.dart';
import 'core/storage_service.dart';
import 'game/neon_vanguard_game.dart';
import 'ui/game_over_overlay.dart';
import 'ui/hud_overlay.dart';
import 'ui/main_menu_overlay.dart';
import 'ui/pause_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final storage = await StorageService.load();
  final audio = AudioService(storage);
  await audio.init();

  runApp(NeonVanguardApp(storage: storage, audio: audio));
}

class NeonVanguardApp extends StatefulWidget {
  const NeonVanguardApp({super.key, required this.storage, required this.audio});

  final StorageService storage;
  final AudioService audio;

  @override
  State<NeonVanguardApp> createState() => _NeonVanguardAppState();
}

class _NeonVanguardAppState extends State<NeonVanguardApp> {
  late final NeonVanguardGame _game =
      NeonVanguardGame(storage: widget.storage, audio: widget.audio);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Vanguard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(primary: Palette.cyan),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          // Keeps the playfield phone-shaped on web / desktop / tablets.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: GameWidget<NeonVanguardGame>(
              game: _game,
              initialActiveOverlays: const ['menu'],
              overlayBuilderMap: {
                'menu': (_, g) => MainMenuOverlay(game: g),
                'hud': (_, g) => HudOverlay(game: g),
                'pause': (_, g) => PauseOverlay(game: g),
                'gameOver': (_, g) => GameOverOverlay(game: g),
              },
            ),
          ),
        ),
      ),
    );
  }
}
