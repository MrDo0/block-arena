import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class Storage {
  static const _kHiScore = 'hi_score';
  static const _kGamesPlayed = 'games_played';
  static const _kTotalCleared = 'total_cleared';
  static const _kBestCombo = 'best_combo';
  static const _kSavedBoard = 'saved_board';
  static const _kSavedPieces = 'saved_pieces';
  static const _kSavedUsed = 'saved_used';
  static const _kSavedScore = 'saved_score';
  static const _kSoundOn = 'sound_on';
  static const _kHapticOn = 'haptic_on';
  static const _kThemeMode = 'theme_mode';
  static const _kAchievements = 'achievements';

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  int get hiScore => _prefs.getInt(_kHiScore) ?? 0;
  Future<void> setHiScore(int v) => _prefs.setInt(_kHiScore, v);

  int get gamesPlayed => _prefs.getInt(_kGamesPlayed) ?? 0;
  Future<void> setGamesPlayed(int v) => _prefs.setInt(_kGamesPlayed, v);

  int get totalCleared => _prefs.getInt(_kTotalCleared) ?? 0;
  Future<void> setTotalCleared(int v) => _prefs.setInt(_kTotalCleared, v);

  int get bestCombo => _prefs.getInt(_kBestCombo) ?? 0;
  Future<void> setBestCombo(int v) => _prefs.setInt(_kBestCombo, v);

  bool get soundOn => _prefs.getBool(_kSoundOn) ?? true;
  Future<void> setSoundOn(bool v) => _prefs.setBool(_kSoundOn, v);

  bool get hapticOn => _prefs.getBool(_kHapticOn) ?? true;
  Future<void> setHapticOn(bool v) => _prefs.setBool(_kHapticOn, v);

  AppThemeMode get themeMode {
    final s = _prefs.getString(_kThemeMode);
    return AppThemeMode.values.firstWhere(
      (m) => m.name == s,
      orElse: () => AppThemeMode.dark,
    );
  }

  Future<void> setThemeMode(AppThemeMode m) =>
      _prefs.setString(_kThemeMode, m.name);

  Set<String> get achievements =>
      (_prefs.getStringList(_kAchievements) ?? []).toSet();
  Future<void> setAchievements(Set<String> v) =>
      _prefs.setStringList(_kAchievements, v.toList());

  Future<void> saveGame({
    required List<List<int?>> boardColors,
    required List<int?> pieceShapeIdx,
    required List<int?> pieceColors,
    required List<bool> used,
    required int score,
  }) async {
    final boardStr = jsonEncode(boardColors);
    final piecesStr = jsonEncode({
      'shapes': pieceShapeIdx,
      'colors': pieceColors,
    });
    final usedStr = jsonEncode(used);
    await _prefs.setString(_kSavedBoard, boardStr);
    await _prefs.setString(_kSavedPieces, piecesStr);
    await _prefs.setString(_kSavedUsed, usedStr);
    await _prefs.setInt(_kSavedScore, score);
  }

  Map<String, dynamic>? loadGame() {
    final boardStr = _prefs.getString(_kSavedBoard);
    final piecesStr = _prefs.getString(_kSavedPieces);
    final usedStr = _prefs.getString(_kSavedUsed);
    final score = _prefs.getInt(_kSavedScore);
    if (boardStr == null ||
        piecesStr == null ||
        usedStr == null ||
        score == null) {
      return null;
    }
    try {
      return {
        'board': jsonDecode(boardStr),
        'pieces': jsonDecode(piecesStr),
        'used': jsonDecode(usedStr),
        'score': score,
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSavedGame() async {
    await _prefs.remove(_kSavedBoard);
    await _prefs.remove(_kSavedPieces);
    await _prefs.remove(_kSavedUsed);
    await _prefs.remove(_kSavedScore);
  }
}
