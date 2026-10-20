import 'package:flutter/material.dart';

abstract final class Palette {
  static const Color bgTop = Color(0xFF04010D);
  static const Color bgBottom = Color(0xFF140640);
  static const Color cyan = Color(0xFF00F0FF);
  static const Color magenta = Color(0xFFFF2E93);
  static const Color amber = Color(0xFFFFB020);
  static const Color lime = Color(0xFF7CFF4F);
  static const Color violet = Color(0xFF9B6BFF);
  static const Color red = Color(0xFFFF4040);
}

/// Central place to tweak game feel.
abstract final class Tuning {
  static const double playerMaxHp = 100;
  static const double dragSensitivity = 1.15;
  static const double comboWindow = 2.2; // seconds to keep a combo alive
  static const int maxCombo = 8;
  static const double powerDuration = 8; // seconds
  static const double powerDropChance = 0.10;
  static const int bossEveryNWaves = 5;
}
