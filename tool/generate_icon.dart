import 'dart:io';
import 'package:image/image.dart' as img;

const int _size = 1024;
const int _bgColor = 0xFF0F0F1E;

const List<int> _tileColors = [
  0xFF378ADD, // top-left  blue
  0xFFE24B4A, // top-right red
  0xFF1D9E75, // bottom-left green
  0xFFBA7517, // bottom-right orange
];

img.ColorRgba8 _argbToColor(int argb) {
  final a = (argb >> 24) & 0xFF;
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  return img.ColorRgba8(r, g, b, a);
}

void _fillRoundedRect(
  img.Image image, {
  required int x1,
  required int y1,
  required int x2,
  required int y2,
  required int radius,
  required img.Color color,
}) {
  img.fillRect(image,
      x1: x1 + radius, y1: y1, x2: x2 - radius, y2: y2, color: color);
  img.fillRect(image,
      x1: x1, y1: y1 + radius, x2: x2, y2: y2 - radius, color: color);
  img.fillCircle(image,
      x: x1 + radius, y: y1 + radius, radius: radius, color: color);
  img.fillCircle(image,
      x: x2 - radius, y: y1 + radius, radius: radius, color: color);
  img.fillCircle(image,
      x: x1 + radius, y: y2 - radius, radius: radius, color: color);
  img.fillCircle(image,
      x: x2 - radius, y: y2 - radius, radius: radius, color: color);
}

void main() {
  final image = img.Image(width: _size, height: _size, numChannels: 4);
  img.fill(image, color: _argbToColor(_bgColor));

  const inset = 184;
  const gap = 51;
  const tileSize = (_size - inset * 2 - gap) ~/ 2;
  final tileRadius = (tileSize * 0.18).toInt();

  final positions = [
    [inset, inset],
    [inset + tileSize + gap, inset],
    [inset, inset + tileSize + gap],
    [inset + tileSize + gap, inset + tileSize + gap],
  ];

  for (int i = 0; i < 4; i++) {
    final x = positions[i][0];
    final y = positions[i][1];
    _fillRoundedRect(
      image,
      x1: x,
      y1: y,
      x2: x + tileSize,
      y2: y + tileSize,
      radius: tileRadius,
      color: _argbToColor(_tileColors[i]),
    );
  }

  final out = File('assets/icon.png');
  out.parent.createSync(recursive: true);
  out.writeAsBytesSync(img.encodePng(image));
  stdout.writeln('Wrote ${out.path} (${image.width}x${image.height})');
}