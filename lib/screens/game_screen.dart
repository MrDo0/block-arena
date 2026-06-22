import 'dart:math';
import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../services/storage.dart';
import '../theme/app_theme.dart';
import '../widgets/achievement_toast.dart';
import '../widgets/animated_score.dart';
import '../widgets/board.dart';
import '../widgets/dialogs.dart';
import '../widgets/piece_widget.dart';

class GameScreen extends StatefulWidget {
  final Storage storage;
  const GameScreen({super.key, required this.storage});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  late GameState _game;

  // Combo / score popup anim
  late AnimationController _comboCtrl;
  late Animation<double> _comboScale;
  late Animation<double> _comboOpacity;

  // Line clear anim
  late AnimationController _clearCtrl;
  Set<int> _clearingRows = {};
  Set<int> _clearingCols = {};

  // Ghost pulse
  late AnimationController _pulseCtrl;

  // Particles
  late AnimationController _particleCtrl;
  List<Particle> _particles = [];

  // Drag state
  int? _draggingSlot;
  Offset _dragGlobal = Offset.zero;
  int _ghostRow = -1, _ghostCol = -1;
  bool _ghostValid = false;
  final GlobalKey _boardKey = GlobalKey();

  // Achievement overlay
  OverlayEntry? _achEntry;

  @override
  void initState() {
    super.initState();
    final initialTheme = AppTheme.fromMode(widget.storage.themeMode);
    _game = GameState(storage: widget.storage, theme: initialTheme);
    _game.load();
    _game.addListener(_onGameChanged);

    _comboCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _comboScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.6, end: 1.25)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 1.25, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
    ]).animate(_comboCtrl);
    _comboOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_comboCtrl);

    _clearCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    )..addListener(() => setState(() {}));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() => setState(() {}));
  }

  void _onGameChanged() {
    if (_game.lastClearedLines > 0) {
      _runClearAnimation();
    }
    if (_game.comboText != null) {
      _comboCtrl.forward(from: 0);
    }
    if (_game.pendingAchievement != null) {
      _showAchievementToast(_game.pendingAchievement!);
      _game.consumePendingAchievement();
    }
    if (_game.isOver) {
      _game.triggerHaptic(heavy: true);
      _showGameOverDialog();
    }
    setState(() {});
  }

  void _runClearAnimation() {
    _clearingRows = _game.lastClearedRows.toSet();
    _clearingCols = _game.lastClearedCols.toSet();
    _spawnParticles();
    _game.triggerHaptic(heavy: true);
    _clearCtrl.forward(from: 0).then((_) {
      _clearingRows = {};
      _clearingCols = {};
      setState(() {});
    });
  }

  void _spawnParticles() {
    final cs = _cellSize;
    final pad = cs * 0.06;
    final rnd = Random();
    final list = <Particle>[];

    void spawnAt(int r, int c, Color color) {
      final cx = c * cs + cs / 2;
      final cy = r * cs + cs / 2;
      for (int i = 0; i < 6; i++) {
        final angle = rnd.nextDouble() * 2 * pi;
        final speed = 80 + rnd.nextDouble() * 220;
        list.add(Particle(
          pos: Offset(cx, cy),
          vel: Offset(cos(angle) * speed, sin(angle) * speed - 80),
          color: color,
          life: 0.7 + rnd.nextDouble() * 0.3,
          size: 2 + rnd.nextDouble() * 3,
        ));
      }
    }

    for (final r in _game.lastClearedRows) {
      for (int c = 0; c < kGrid; c++) {
        spawnAt(r, c, _game.theme.pieceColors[rnd.nextInt(_game.theme.pieceColors.length)]);
      }
    }
    for (final c in _game.lastClearedCols) {
      for (int r = 0; r < kGrid; r++) {
        if (_game.lastClearedRows.contains(r)) continue;
        spawnAt(r, c, _game.theme.pieceColors[rnd.nextInt(_game.theme.pieceColors.length)]);
      }
    }
    pad;
    _particles = list;
    _particleCtrl.forward(from: 0);
  }

  void _showAchievementToast(Achievement a) {
    _achEntry?.remove();
    _achEntry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          top: MediaQuery.of(ctx).padding.top + 60,
          left: 16,
          right: 16,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: _AnimatedToast(
                child: AchievementToast(
                  achievement: a,
                  theme: _game.theme,
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_achEntry!);
    Future.delayed(const Duration(milliseconds: 2800), () {
      _achEntry?.remove();
      _achEntry = null;
    });
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameOverDialog(
        score: _game.score,
        hiScore: _game.hiScore,
        adUsed: _game.adUsed,
        theme: _game.theme,
        onRewardedAd: () {
          Navigator.pop(context);
          _showRewardedAdSimulation();
        },
        onRestart: () {
          Navigator.pop(context);
          _game.restart();
        },
      ),
    );
  }

  void _showRewardedAdSimulation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RewardedAdDialog(
        theme: _game.theme,
        onComplete: () {
          Navigator.pop(context);
          _game.useRewardedAd();
        },
      ),
    );
  }

  void _showUndoAd() {
    if (!_game.canUndo) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RewardedAdDialog(
        theme: _game.theme,
        onComplete: () {
          Navigator.pop(context);
          _game.undoLastMove();
          _game.triggerHaptic();
        },
      ),
    );
  }

  void _showPause() {
    showDialog(
      context: context,
      builder: (_) => PauseDialog(
        game: _game,
        onResume: () => Navigator.pop(context),
        onRestart: () {
          Navigator.pop(context);
          _game.restart();
        },
        onHome: () {
          Navigator.pop(context);
          Navigator.of(context).pop();
        },
        onOpenStats: () {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (_) => StatsDialog(game: _game),
          );
        },
        onOpenSettings: () {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (_) => SettingsDialog(
              game: _game,
              onThemeChange: (m) => _game.applyTheme(AppTheme.fromMode(m)),
            ),
          );
        },
      ),
    );
  }

  double get _cellSize {
    final screenW = MediaQuery.of(context).size.width;
    return (screenW - 32) / kGrid;
  }

  double get _boardSize => _cellSize * kGrid;

  // Drag offset: lift piece above finger so user can see it
  double get _dragLift => _cellSize * 2.2;

  (int, int) _gridPosFromGlobal(Offset global, Piece piece) {
    final box =
        _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return (-1, -1);
    // Adjust: finger position - lift, then anchor by piece center top
    final local = box.globalToLocal(global - Offset(0, _dragLift));
    final cs = _cellSize;
    // Anchor: piece top-left placed so the piece center sits at the finger
    int c = ((local.dx - piece.cols * cs / 2 + cs / 2) / cs).round();
    int r = ((local.dy - piece.rows * cs / 2 + cs / 2) / cs).round();
    if (piece.cols > kGrid || piece.rows > kGrid) return (-1, -1);
    c = c.clamp(0, kGrid - piece.cols);
    r = r.clamp(0, kGrid - piece.rows);
    return (r, c);
  }

  void _updateGhost(Offset globalPos) {
    if (_draggingSlot == null) return;
    final piece = _game.pieces[_draggingSlot!];
    if (piece == null) return;
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    _dragGlobal = globalPos;

    final adjusted = globalPos - Offset(0, _dragLift);
    final boardOrigin = box.localToGlobal(Offset.zero);
    if (adjusted.dy < boardOrigin.dy - _cellSize * 0.8 ||
        adjusted.dy > boardOrigin.dy + _boardSize + _cellSize * 0.8 ||
        adjusted.dx < boardOrigin.dx - _cellSize * 0.8 ||
        adjusted.dx > boardOrigin.dx + _boardSize + _cellSize * 0.8) {
      setState(() {
        _ghostRow = -1;
        _ghostCol = -1;
        _ghostValid = false;
      });
      return;
    }
    final (r, c) = _gridPosFromGlobal(globalPos, piece);
    if (r < 0 || c < 0) {
      setState(() {
        _ghostRow = -1;
        _ghostCol = -1;
        _ghostValid = false;
      });
      return;
    }
    if (_game.canPlace(piece, r, c)) {
      setState(() {
        _ghostRow = r;
        _ghostCol = c;
        _ghostValid = true;
      });
      return;
    }
    // Snap to the nearest valid position within a small radius.
    final snap = _findNearestValid(piece, r, c, 2);
    setState(() {
      if (snap != null) {
        _ghostRow = snap.$1;
        _ghostCol = snap.$2;
        _ghostValid = true;
      } else {
        _ghostRow = r;
        _ghostCol = c;
        _ghostValid = false;
      }
    });
  }

  (int, int)? _findNearestValid(Piece p, int tr, int tc, int maxRadius) {
    (int, int)? best;
    int bestDist = 1 << 30;
    for (int radius = 1; radius <= maxRadius; radius++) {
      for (int dr = -radius; dr <= radius; dr++) {
        for (int dc = -radius; dc <= radius; dc++) {
          if (dr.abs() != radius && dc.abs() != radius) continue;
          final r = tr + dr;
          final c = tc + dc;
          if (r < 0 || c < 0) continue;
          if (r + p.rows > kGrid || c + p.cols > kGrid) continue;
          if (!_game.canPlace(p, r, c)) continue;
          final dist = dr * dr + dc * dc;
          if (dist < bestDist) {
            bestDist = dist;
            best = (r, c);
          }
        }
      }
      if (best != null) return best;
    }
    return best;
  }

  void _endDrag({required bool place}) {
    if (place &&
        _draggingSlot != null &&
        _ghostValid &&
        _ghostRow >= 0 &&
        _ghostCol >= 0) {
      _game.triggerHaptic();
      _game.placePiece(_draggingSlot!, _ghostRow, _ghostCol);
    }
    setState(() {
      _draggingSlot = null;
      _ghostRow = -1;
      _ghostCol = -1;
      _ghostValid = false;
    });
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    _game.dispose();
    _comboCtrl.dispose();
    _clearCtrl.dispose();
    _pulseCtrl.dispose();
    _particleCtrl.dispose();
    _achEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _game.theme;
    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(t),
                const SizedBox(height: 8),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildBoard(t),
                    if (_particles.isNotEmpty)
                      IgnorePointer(
                        child: SizedBox(
                          width: _boardSize,
                          height: _boardSize,
                          child: CustomPaint(
                            painter: ParticlePainter(
                              particles: _particles,
                              t: _particleCtrl.value,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildComboText(t),
                _buildUndoBar(t),
                _buildPiecesArea(t),
                const Spacer(),
                _buildAdBannerPlaceholder(t),
              ],
            ),
            if (_draggingSlot != null && _game.pieces[_draggingSlot!] != null)
              _buildFloatingPiece(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AppTheme t) {
    final comboActive = _game.combo > 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _statCard(
            t,
            icon: Icons.stars,
            label: 'SCORE',
            value: AnimatedScore(
              value: _game.score,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: t.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          _statCard(
            t,
            icon: Icons.emoji_events,
            label: 'BEST',
            value: Text('${_game.hiScore}',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: t.textPrimary)),
          ),
          const SizedBox(width: 8),
          _statCard(
            t,
            icon: Icons.local_fire_department,
            label: 'COMBO',
            highlight: comboActive,
            value: Text('x${max(1, _game.combo)}',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: comboActive ? t.accent : t.textPrimary)),
          ),
          const SizedBox(width: 8),
          Material(
            color: t.surface,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _showPause,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 46,
                height: 64,
                alignment: Alignment.center,
                child: Icon(Icons.pause, color: t.textPrimary, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    AppTheme t, {
    required IconData icon,
    required String label,
    required Widget value,
    bool highlight = false,
  }) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(14),
          border: highlight
              ? Border.all(color: t.accent.withValues(alpha: 0.7), width: 1.5)
              : null,
          boxShadow: highlight
              ? [
                  BoxShadow(
                    color: t.accent.withValues(alpha: 0.25),
                    blurRadius: 14,
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 11,
                    color: highlight ? t.accent : t.textSecondary),
                const SizedBox(width: 3),
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color:
                            highlight ? t.accent : t.textSecondary)),
              ],
            ),
            const SizedBox(height: 3),
            value,
          ],
        ),
      ),
    );
  }

  Widget _buildComboText(AppTheme t) {
    if (_game.comboText == null) return const SizedBox(height: 28);
    return AnimatedBuilder(
      animation: _comboCtrl,
      builder: (_, __) {
        return Opacity(
          opacity: _comboOpacity.value,
          child: Transform.scale(
            scale: _comboScale.value,
            child: Text(
              _game.comboText!,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: t.accent,
                shadows: [
                  Shadow(
                      color: t.accent.withValues(alpha: 0.5),
                      blurRadius: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoard(AppTheme t) {
    final cs = _cellSize;
    final bs = _boardSize;
    return AnimatedBuilder(
      animation: Listenable.merge([_clearCtrl, _pulseCtrl]),
      builder: (_, __) {
        return Container(
          key: _boardKey,
          width: bs,
          height: bs,
          decoration: BoxDecoration(
            color: t.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CustomPaint(
            painter: BoardPainter(
              board: _game.board,
              cellSize: cs,
              ghostRow: _ghostRow,
              ghostCol: _ghostCol,
              ghostPiece: _draggingSlot != null
                  ? _game.pieces[_draggingSlot!]
                  : null,
              ghostValid: _ghostValid,
              theme: t,
              clearingRows: _clearingRows,
              clearingCols: _clearingCols,
              clearProgress:
                  _clearingRows.isEmpty && _clearingCols.isEmpty
                      ? 0
                      : Curves.easeIn.transform(_clearCtrl.value),
              pulse: _pulseCtrl.value,
            ),
          ),
        );
      },
    );
  }

  Widget _buildUndoBar(AppTheme t) {
    final visible = _game.canUndo;
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: visible
                  ? Material(
                      key: const ValueKey('undo'),
                      color: t.surface,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: _showUndoAd,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: t.accent.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.undo,
                                  size: 16, color: t.accent),
                              const SizedBox(width: 6),
                              Text('Undo',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: t.accent)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      t.accent.withValues(alpha: 0.18),
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: Text('AD',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                        color: t.accent)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPiecesArea(AppTheme t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) => _buildPieceSlot(i, t)),
      ),
    );
  }

  Widget _buildPieceSlot(int idx, AppTheme t) {
    final piece = _game.pieces[idx];
    final isUsed = _game.used[idx];

    if (piece == null || isUsed) {
      return Opacity(
        opacity: 0.2,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) {
        setState(() => _draggingSlot = idx);
        _game.triggerHaptic();
        _updateGhost(d.globalPosition);
      },
      onPanUpdate: (d) => _updateGhost(d.globalPosition),
      onPanEnd: (_) => _endDrag(place: true),
      onPanCancel: () => _endDrag(place: false),
      child: AnimatedScale(
        scale: _draggingSlot == idx ? 0.3 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedOpacity(
          opacity: _draggingSlot == idx ? 0.3 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: PieceWidget(piece: piece, size: 100, theme: t),
        ),
      ),
    );
  }

  Widget _buildFloatingPiece() {
    final piece = _game.pieces[_draggingSlot!]!;
    final cs = _cellSize;
    final w = piece.cols * cs;
    final h = piece.rows * cs;
    final pos = _dragGlobal - Offset(w / 2, h / 2 + _dragLift);
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: IgnorePointer(
        child: DraggedPieceWidget(piece: piece, cellSize: cs),
      ),
    );
  }

  Widget _buildAdBannerPlaceholder(AppTheme t) {
    return Container(
      height: 50,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: t.textSecondary.withValues(alpha: 0.12)),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined,
                size: 14, color: t.textSecondary),
            const SizedBox(width: 6),
            Text(
              'AdMob Banner',
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                  color: t.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedToast extends StatefulWidget {
  final Widget child;
  const _AnimatedToast({required this.child});

  @override
  State<_AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<_AnimatedToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value;
        double opacity;
        double dy;
        if (t < 0.1) {
          opacity = t / 0.1;
          dy = -30 * (1 - t / 0.1);
        } else if (t > 0.85) {
          opacity = (1 - t) / 0.15;
          dy = -20 * ((t - 0.85) / 0.15);
        } else {
          opacity = 1;
          dy = 0;
        }
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, dy),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
