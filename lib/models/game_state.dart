import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage.dart';
import '../theme/app_theme.dart';
import 'achievement.dart';
import 'piece.dart';

typedef LineClearCallback = void Function(
  List<int> rows,
  List<int> cols,
  List<List<Color?>> boardSnapshot,
);

class GameState extends ChangeNotifier {
  final Storage storage;
  AppTheme theme;

  List<List<Color?>> board =
      List.generate(kGrid, (_) => List.filled(kGrid, null));
  List<Piece?> pieces = [null, null, null];
  List<bool> used = [false, false, false];

  int score = 0;
  int hiScore = 0;
  int combo = 0;

  bool isOver = false;
  bool adUsed = false;
  String? comboText;

  // Stats
  int gamesPlayed = 0;
  int totalCleared = 0;
  int bestCombo = 0;
  Set<String> achievements = {};

  // Last placement metadata (for animations)
  int lastClearedLines = 0;
  int lastScoreDelta = 0;
  List<int> lastClearedRows = const [];
  List<int> lastClearedCols = const [];

  // Newly unlocked achievement (consumed by UI)
  Achievement? pendingAchievement;

  // Undo snapshot (one-step). Cleared when consumed or on restart.
  _UndoSnapshot? _undoSnap;
  bool get canUndo => _undoSnap != null && !isOver;

  GameState({required this.storage, required this.theme});

  void load() {
    hiScore = storage.hiScore;
    gamesPlayed = storage.gamesPlayed;
    totalCleared = storage.totalCleared;
    bestCombo = storage.bestCombo;
    achievements = storage.achievements;

    final saved = storage.loadGame();
    if (saved != null && _restoreFromSaved(saved)) {
      // restored
    } else {
      _newPieces();
    }
    notifyListeners();
  }

  bool _restoreFromSaved(Map<String, dynamic> s) {
    try {
      final boardData = (s['board'] as List)
          .map<List<int?>>((row) => (row as List).map((e) => e as int?).toList())
          .toList();
      board = List.generate(kGrid, (r) {
        return List.generate(kGrid, (c) {
          final v = boardData[r][c];
          return v == null ? null : Color(v);
        });
      });

      final p = s['pieces'] as Map<String, dynamic>;
      final shapes = (p['shapes'] as List).map((e) => e as int?).toList();
      final colors = (p['colors'] as List).map((e) => e as int?).toList();
      pieces = List.generate(3, (i) {
        if (shapes[i] == null || colors[i] == null) return null;
        return Piece(
          shape: kShapes[shapes[i]!],
          color: Color(colors[i]!),
        );
      });

      used = (s['used'] as List).map((e) => e as bool).toList();
      score = s['score'] as int;
      return pieces.any((p) => p != null);
    } catch (_) {
      return false;
    }
  }

  Future<void> persist() async {
    final boardColors = List.generate(
      kGrid,
      (r) => List.generate(kGrid, (c) {
        final v = board[r][c];
        return v?.toARGB32();
      }),
    );

    final shapeIdx = pieces.map((p) {
      if (p == null) return null;
      final i = kShapes.indexOf(p.shape);
      return i >= 0 ? i : null;
    }).toList();
    final pieceColorVals = pieces.map((p) => p?.color.toARGB32()).toList();

    await storage.saveGame(
      boardColors: boardColors,
      pieceShapeIdx: shapeIdx,
      pieceColors: pieceColorVals,
      used: used,
      score: score,
    );
  }

  void _newPieces() {
    pieces = [
      Piece.random(theme.pieceColors),
      Piece.random(theme.pieceColors),
      Piece.random(theme.pieceColors),
    ];
    used = [false, false, false];
  }

  bool canPlace(Piece piece, int r, int c) {
    for (int dr = 0; dr < piece.rows; dr++) {
      final row = piece.shape[dr];
      for (int dc = 0; dc < row.length; dc++) {
        if (row[dc] == 0) continue;
        final nr = r + dr, nc = c + dc;
        if (nr < 0 || nr >= kGrid || nc < 0 || nc >= kGrid) return false;
        if (board[nr][nc] != null) return false;
      }
    }
    return true;
  }

  void placePiece(int slotIdx, int r, int c) {
    final piece = pieces[slotIdx]!;
    if (!canPlace(piece, r, c)) return;

    _saveSnapshot();

    for (int dr = 0; dr < piece.rows; dr++) {
      final row = piece.shape[dr];
      for (int dc = 0; dc < row.length; dc++) {
        if (row[dc] == 1) board[r + dr][c + dc] = piece.color;
      }
    }

    used[slotIdx] = true;

    final rowsToClear = <int>[];
    final colsToClear = <int>[];
    for (int i = 0; i < kGrid; i++) {
      if (board[i].every((v) => v != null)) rowsToClear.add(i);
      if (board.every((row) => row[i] != null)) colsToClear.add(i);
    }
    final cleared = rowsToClear.length + colsToClear.length;
    lastClearedRows = rowsToClear;
    lastClearedCols = colsToClear;
    lastClearedLines = cleared;

    for (final row in rowsToClear) {
      for (int c = 0; c < kGrid; c++) {
        board[row][c] = null;
      }
    }
    for (final col in colsToClear) {
      for (int r = 0; r < kGrid; r++) {
        board[r][col] = null;
      }
    }

    int delta;
    if (cleared > 0) {
      combo++;
      delta = cleared * 10 * (combo > 1 ? combo : 1) * 8;
      score += delta;
      comboText = combo > 1 ? 'COMBO x$combo  +$delta' : '+$delta';
      totalCleared += cleared;
      if (combo > bestCombo) {
        bestCombo = combo;
        storage.setBestCombo(bestCombo);
      }
      storage.setTotalCleared(totalCleared);
    } else {
      combo = 0;
      delta = piece.cellCount * 2;
      score += delta;
      comboText = null;
    }
    lastScoreDelta = delta;

    if (score > hiScore) {
      hiScore = score;
      storage.setHiScore(hiScore);
    }

    if (used.every((u) => u)) _newPieces();

    _checkAchievements();
    persist();

    notifyListeners();
    _checkGameOver();
  }

  bool _hasMoveForPiece(Piece p) {
    for (int r = 0; r < kGrid; r++) {
      for (int c = 0; c < kGrid; c++) {
        if (canPlace(p, r, c)) return true;
      }
    }
    return false;
  }

  void _checkGameOver() {
    final hasMove = pieces
        .asMap()
        .entries
        .where((e) => !used[e.key] && e.value != null)
        .any((e) => _hasMoveForPiece(e.value!));
    if (!hasMove) {
      isOver = true;
      gamesPlayed++;
      storage.setGamesPlayed(gamesPlayed);
      _checkAchievements();
      notifyListeners();
    }
  }

  void useRewardedAd() {
    adUsed = true;
    isOver = false;
    pieces = [
      _randomPieceThatFits(),
      _randomPieceThatFits(),
      _randomPieceThatFits(),
    ];
    used = [false, false, false];
    _undoSnap = null;
    persist();
    notifyListeners();
  }

  void _saveSnapshot() {
    _undoSnap = _UndoSnapshot(
      board: List.generate(kGrid, (r) => List<Color?>.from(board[r])),
      pieces: List<Piece?>.from(pieces),
      used: List<bool>.from(used),
      score: score,
      combo: combo,
      totalCleared: totalCleared,
      bestCombo: bestCombo,
      hiScore: hiScore,
      comboText: comboText,
    );
  }

  void undoLastMove() {
    final s = _undoSnap;
    if (s == null) return;
    board = List.generate(kGrid, (r) => List<Color?>.from(s.board[r]));
    pieces = List<Piece?>.from(s.pieces);
    used = List<bool>.from(s.used);
    score = s.score;
    combo = s.combo;
    totalCleared = s.totalCleared;
    bestCombo = s.bestCombo;
    hiScore = s.hiScore;
    comboText = s.comboText;
    lastClearedLines = 0;
    lastClearedRows = const [];
    lastClearedCols = const [];
    lastScoreDelta = 0;
    _undoSnap = null;

    storage.setTotalCleared(totalCleared);
    storage.setBestCombo(bestCombo);
    storage.setHiScore(hiScore);
    persist();
    notifyListeners();
  }

  Piece _randomPieceThatFits() {
    for (int i = 0; i < 60; i++) {
      final p = Piece.random(theme.pieceColors);
      if (_hasMoveForPiece(p)) return p;
    }
    // Fallback: 1x1 always fits if any empty cell exists.
    return Piece(
      shape: const [[1]],
      color: theme.pieceColors.first,
    );
  }

  void restart() {
    board = List.generate(kGrid, (_) => List.filled(kGrid, null));
    score = 0;
    combo = 0;
    isOver = false;
    adUsed = false;
    comboText = null;
    lastClearedLines = 0;
    lastClearedRows = const [];
    lastClearedCols = const [];
    _undoSnap = null;
    _newPieces();
    storage.clearSavedGame();
    notifyListeners();
  }

  void applyTheme(AppTheme newTheme) {
    theme = newTheme;
    storage.setThemeMode(newTheme.mode);
    notifyListeners();
  }

  void _checkAchievements() {
    final unlocked = <String>{};
    if (totalCleared >= 1) unlocked.add('first_clear');
    if (bestCombo >= 3) unlocked.add('combo_3');
    if (bestCombo >= 5) unlocked.add('combo_5');
    if (hiScore >= 1000) unlocked.add('score_1000');
    if (hiScore >= 5000) unlocked.add('score_5000');
    if (hiScore >= 10000) unlocked.add('score_10000');
    if (totalCleared >= 50) unlocked.add('cleared_50');
    if (gamesPlayed >= 10) unlocked.add('games_10');

    final newOnes = unlocked.difference(achievements);
    if (newOnes.isNotEmpty) {
      achievements.addAll(newOnes);
      storage.setAchievements(achievements);
      pendingAchievement = kAchievements.firstWhere(
        (a) => a.id == newOnes.first,
        orElse: () => kAchievements.first,
      );
    }
  }

  void consumePendingAchievement() {
    pendingAchievement = null;
  }

  void triggerHaptic({bool heavy = false}) {
    if (!storage.hapticOn) return;
    if (heavy) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }
}

class _UndoSnapshot {
  final List<List<Color?>> board;
  final List<Piece?> pieces;
  final List<bool> used;
  final int score;
  final int combo;
  final int totalCleared;
  final int bestCombo;
  final int hiScore;
  final String? comboText;

  _UndoSnapshot({
    required this.board,
    required this.pieces,
    required this.used,
    required this.score,
    required this.combo,
    required this.totalCleared,
    required this.bestCombo,
    required this.hiScore,
    required this.comboText,
  });
}
