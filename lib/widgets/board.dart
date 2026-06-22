import 'dart:math';
import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../theme/app_theme.dart';

class BoardPainter extends CustomPainter {
  final List<List<Color?>> board;
  final double cellSize;
  final int ghostRow, ghostCol;
  final Piece? ghostPiece;
  final bool ghostValid;
  final AppTheme theme;
  final Set<int> clearingRows;
  final Set<int> clearingCols;
  final double clearProgress;
  final double pulse;

  const BoardPainter({
    required this.board,
    required this.cellSize,
    required this.ghostRow,
    required this.ghostCol,
    required this.theme,
    this.ghostPiece,
    this.ghostValid = true,
    this.clearingRows = const {},
    this.clearingCols = const {},
    this.clearProgress = 0,
    this.pulse = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cs = cellSize;
    final pad = cs * 0.06;
    final inner = cs - pad * 2;

    final emptyPaint = Paint()..color = theme.cellEmpty;
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18);

    for (int r = 0; r < kGrid; r++) {
      for (int c = 0; c < kGrid; c++) {
        final isClearing = clearingRows.contains(r) || clearingCols.contains(c);

        double scale = 1.0;
        double alpha = 1.0;
        if (isClearing) {
          scale = 1.0 - clearProgress;
          alpha = 1.0 - clearProgress;
        }

        final x = c * cs + pad;
        final y = r * cs + pad;
        final size = inner * scale;
        final dx = x + (inner - size) / 2;
        final dy = y + (inner - size) / 2;

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(dx, dy, size, size),
          const Radius.circular(5),
        );

        final cell = board[r][c];
        if (cell != null) {
          final p = Paint()..color = cell.withValues(alpha: alpha);
          canvas.drawRRect(rect, p);
          if (alpha > 0.5) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(dx + 3, dy + 3, size - 6, size * 0.2),
                const Radius.circular(3),
              ),
              Paint()
                ..color = Colors.white.withValues(alpha: 0.18 * alpha),
            );
          }
        } else if (!isClearing) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, inner, inner),
              const Radius.circular(5),
            ),
            emptyPaint,
          );
        }
      }
    }

    // Ghost preview
    if (ghostPiece != null && ghostRow >= 0 && ghostCol >= 0) {
      final baseAlpha = ghostValid ? 0.55 : 0.25;
      final pulseAlpha = baseAlpha + (sin(pulse * 2 * pi) * 0.15);
      final ghostColor = ghostValid ? ghostPiece!.color : Colors.red;
      final ghostPaint = Paint()
        ..color = ghostColor.withValues(alpha: pulseAlpha.clamp(0.0, 1.0));
      final outline = Paint()
        ..color = ghostColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (int dr = 0; dr < ghostPiece!.rows; dr++) {
        final row = ghostPiece!.shape[dr];
        for (int dc = 0; dc < row.length; dc++) {
          if (row[dc] == 0) continue;
          final gr = ghostRow + dr, gc = ghostCol + dc;
          if (gr >= kGrid || gc >= kGrid) continue;
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(gc * cs + pad, gr * cs + pad, inner, inner),
            const Radius.circular(5),
          );
          canvas.drawRRect(rect, ghostPaint);
          canvas.drawRRect(rect, outline);
        }
      }
      // Highlight whole row/col that *would* clear
      if (ghostValid) {
        _drawProjectionHints(canvas, cs, pad, inner, highlightPaint);
      }
    }
  }

  void _drawProjectionHints(
      Canvas canvas, double cs, double pad, double inner, Paint hPaint) {
    final filledIfPlaced = List<List<bool>>.generate(
      kGrid,
      (r) => List<bool>.generate(kGrid, (c) => board[r][c] != null),
    );
    for (int dr = 0; dr < ghostPiece!.rows; dr++) {
      final row = ghostPiece!.shape[dr];
      for (int dc = 0; dc < row.length; dc++) {
        if (row[dc] == 0) continue;
        final gr = ghostRow + dr, gc = ghostCol + dc;
        if (gr < kGrid && gc < kGrid) filledIfPlaced[gr][gc] = true;
      }
    }

    final hint = Paint()
      ..color = ghostPiece!.color.withValues(alpha: 0.10);

    for (int r = 0; r < kGrid; r++) {
      if (filledIfPlaced[r].every((v) => v)) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, r * cs + pad, cs * kGrid, inner),
            const Radius.circular(5),
          ),
          hint,
        );
      }
    }
    for (int c = 0; c < kGrid; c++) {
      if (List.generate(kGrid, (r) => filledIfPlaced[r][c]).every((v) => v)) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(c * cs + pad, 0, inner, cs * kGrid),
            const Radius.circular(5),
          ),
          hint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(BoardPainter old) => true;
}

class Particle {
  Offset pos;
  Offset vel;
  Color color;
  double life;
  double size;

  Particle({
    required this.pos,
    required this.vel,
    required this.color,
    required this.life,
    required this.size,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double t;

  const ParticlePainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final lifeLeft = (p.life - t).clamp(0.0, p.life);
      if (lifeLeft <= 0) continue;
      final alpha = (lifeLeft / p.life).clamp(0.0, 1.0);
      final cur = p.pos + p.vel * t + Offset(0, 220 * t * t);
      final paint = Paint()..color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(cur, p.size * (0.4 + 0.6 * alpha), paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter old) => true;
}
