# Neon Vanguard

A polished arcade space shooter built with **Flutter + Flame**.

## Run it

```bash
cd neon_vanguard
flutter create .          # generates android/ ios/ web/ windows/ ... (keeps lib/, assets/, pubspec.yaml)
flutter pub get
flutter run               # pick a device; add -d chrome / -d windows for desktop & web
```

Requires Flutter 3.27+ (Dart 3.6+).

## Controls

| Platform | Steer | Fire | Pause |
|----------|-------|------|-------|
| Mobile   | Drag anywhere | Automatic | Pause button / app switch |
| Desktop / Web | WASD or arrows (mouse drag works too) | Automatic | Esc |

## Features

- Main menu, settings (sound / haptics), pause, game-over with persistent best score
- Wave system with escalating difficulty and a 3-phase boss every 5th wave
- 3 enemy types (Drone, Weaver, Tank) with distinct movement and firing patterns
- Power-ups: Shield, Rapid fire, Spread shot, Repair
- Combo multiplier (up to x8), wave-clear bonuses
- Neon glow rendering, additive particle explosions, screen shake, parallax nebula/star/grid background
- Synthesised SFX + looping music, haptic feedback, auto-pause on app switch

## Project layout

```
lib/
  main.dart                    app entry, overlay wiring
  core/                        constants (tuning!), audio, storage, neon paints
  game/
    neon_vanguard_game.dart    game state machine, scoring, input, helpers
    components/                player, enemies, boss, bullets, power-ups, fx, background, wave director
  ui/                          Flutter overlays: menu, HUD, pause, game over
assets/audio/                  generated .wav files
tools/generate_audio.py        regenerates all audio (or drop in your own files, same names)
```

## Tweaking

Everything gameplay-related lives in `lib/core/constants.dart` (`Tuning`) and the
enemy classes in `lib/game/components/enemy.dart` / `boss.dart`.

## Ideas for next steps

- Swap vector art for sprite sheets (`flame` `SpriteAnimationComponent`)
- Online leaderboard (Firebase / Supabase) using `StorageService.submitScore`
- Ship upgrades / currency shop persisted via `shared_preferences`
- Gamepad support, localisation, achievements
