import 'dart:math';
import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../theme/app_theme.dart';

class PieceWidget extends StatelessWidget {
  final Piece piece;
  final double size;
  final AppTheme theme;
  final double cellScale;

  const PieceWidget({
    super.key,
    required this.piece,
    required this.size,
    required this.theme,
    this.cellScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPaint(
        painter: PiecePainter(piece: piece, cellScale: cellScale),
      ),
    );
  }
}

class PiecePainter extends CustomPainter {
  final Piece piece;
  final double cellScale;

  const PiecePainter({required this.piece, this.cellScale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final rows = piece.rows;
    final cols = piece.cols;
    final cs = min(size.width * 0.85 / max(rows, cols), 22.0 * cellScale);
    final pw = cols * cs + (cols - 1) * 2;
    final ph = rows * cs + (rows - 1) * 2;
    final ox = (size.width - pw) / 2;
    final oy = (size.height - ph) / 2;

    final paint = Paint()..color = piece.color;
    final hPaint = Paint()..color = Colors.white.withValues(alpha: 0.2);

    for (int r = 0; r < rows; r++) {
      final row = piece.shape[r];
      for (int c = 0; c < row.length; c++) {
        if (row[c] == 0) continue;
        final x = ox + c * (cs + 2);
        final y = oy + r * (cs + 2);
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, cs, cs),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, paint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 2, y + 2, cs - 4, cs * 0.22),
            const Radius.circular(2),
          ),
          hPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(PiecePainter old) =>
      old.piece != piece || old.cellScale != cellScale;
}

class DraggedPieceWidget extends StatelessWidget {
  final Piece piece;
  final double cellSize;

  const DraggedPieceWidget({
    super.key,
    required this.piece,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    final w = piece.cols * cellSize;
    final h = piece.rows * cellSize;
    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(
        painter: DraggedPiecePainter(piece: piece, cellSize: cellSize),
      ),
    );
  }
}

class DraggedPiecePainter extends CustomPainter {
  final Piece piece;
  final double cellSize;

  const DraggedPiecePainter({required this.piece, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final pad = cellSize * 0.06;
    final inner = cellSize - pad * 2;
    final paint = Paint()..color = piece.color;
    final hPaint = Paint()..color = Colors.white.withValues(alpha: 0.22);
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (int r = 0; r < piece.rows; r++) {
      final row = piece.shape[r];
      for (int c = 0; c < row.length; c++) {
        if (row[c] == 0) continue;
        final x = c * cellSize + pad;
        final y = r * cellSize + pad;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, inner, inner),
          const Radius.circular(6),
        );
        canvas.drawRRect(rect.shift(const Offset(0, 4)), shadow);
        canvas.drawRRect(rect, paint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 3, y + 3, inner - 6, inner * 0.22),
            const Radius.circular(3),
          ),
          hPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DraggedPiecePainter old) =>
      old.piece != piece || old.cellSize != cellSize;
}
