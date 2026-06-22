import 'package:flutter/material.dart';

enum AppThemeMode { dark, midnight, candy }

class AppTheme {
  final AppThemeMode mode;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color cellEmpty;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final List<Color> pieceColors;

  const AppTheme._({
    required this.mode,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.cellEmpty,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.pieceColors,
  });

  static const dark = AppTheme._(
    mode: AppThemeMode.dark,
    background: Color(0xFF0F0F1E),
    surface: Color(0xFF1E1E32),
    surfaceAlt: Color(0xFF1A1A2E),
    cellEmpty: Color(0xFF252540),
    textPrimary: Colors.white,
    textSecondary: Color(0xFF888899),
    accent: Color(0xFFBA7517),
    pieceColors: [
      Color(0xFF378ADD),
      Color(0xFFE24B4A),
      Color(0xFF1D9E75),
      Color(0xFFBA7517),
      Color(0xFF7F77DD),
      Color(0xFFD85A30),
      Color(0xFFD4537E),
    ],
  );

  static const midnight = AppTheme._(
    mode: AppThemeMode.midnight,
    background: Color(0xFF050816),
    surface: Color(0xFF101730),
    surfaceAlt: Color(0xFF0A1024),
    cellEmpty: Color(0xFF1A2348),
    textPrimary: Colors.white,
    textSecondary: Color(0xFF7080A0),
    accent: Color(0xFF4FC3F7),
    pieceColors: [
      Color(0xFF4FC3F7),
      Color(0xFFFF6B9D),
      Color(0xFF42E695),
      Color(0xFFFFD93D),
      Color(0xFFA78BFA),
      Color(0xFFFF8A65),
      Color(0xFF26C6DA),
    ],
  );

  static const candy = AppTheme._(
    mode: AppThemeMode.candy,
    background: Color(0xFFFFF0F5),
    surface: Color(0xFFFFD6E8),
    surfaceAlt: Color(0xFFFFE5EE),
    cellEmpty: Color(0xFFFAC2D8),
    textPrimary: Color(0xFF4A1F36),
    textSecondary: Color(0xFF8B5A75),
    accent: Color(0xFFD81B60),
    pieceColors: [
      Color(0xFFE91E63),
      Color(0xFF9C27B0),
      Color(0xFF03A9F4),
      Color(0xFFFFB300),
      Color(0xFF4CAF50),
      Color(0xFFFF5722),
      Color(0xFF7E57C2),
    ],
  );

  static AppTheme fromMode(AppThemeMode m) => switch (m) {
        AppThemeMode.dark => dark,
        AppThemeMode.midnight => midnight,
        AppThemeMode.candy => candy,
      };

  static List<AppTheme> get all => const [dark, midnight, candy];

  String get displayName => switch (mode) {
        AppThemeMode.dark => 'Dark',
        AppThemeMode.midnight => 'Midnight',
        AppThemeMode.candy => 'Candy',
      };
}
