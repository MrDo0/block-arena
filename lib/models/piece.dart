import 'dart:math';
import 'package:flutter/material.dart';

const int kGrid = 8;

const List<List<List<int>>> kShapes = [
  [[1, 1, 1], [1, 1, 1], [1, 1, 1]],
  [[1, 1, 1, 1, 1]],
  [[1], [1], [1], [1], [1]],
  [[1, 1], [1, 1]],
  [[1, 1, 1], [1, 1, 1]],
  [[1, 1, 1]],
  [[1], [1], [1]],
  [[1, 0], [1, 0], [1, 1]],
  [[0, 1], [0, 1], [1, 1]],
  [[1, 1, 0], [0, 1, 1]],
  [[0, 1, 1], [1, 1, 0]],
  [[1, 1, 1], [0, 1, 0]],
  [[0, 1, 0], [1, 1, 1]],
  [[1, 1], [1, 0]],
  [[1, 1], [0, 1]],
  [[1, 0], [1, 1]],
  [[0, 1], [1, 1]],
  [[1, 1, 1], [1, 0, 0]],
  [[1, 1, 1], [0, 0, 1]],
  [[1, 0, 0], [1, 1, 1]],
  [[0, 0, 1], [1, 1, 1]],
  [[1]],
  [[1, 1]],
  [[1], [1]],
];

class Piece {
  final List<List<int>> shape;
  final Color color;

  Piece({required this.shape, required this.color});

  int get rows => shape.length;
  int get cols => shape.map((r) => r.length).reduce(max);
  int get cellCount =>
      shape.expand((r) => r).where((v) => v == 1).length;

  static final _rnd = Random();

  static Piece random(List<Color> palette) {
    return Piece(
      shape: kShapes[_rnd.nextInt(kShapes.length)],
      color: palette[_rnd.nextInt(palette.length)],
    );
  }
}
