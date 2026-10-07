import 'package:flutter/material.dart';

import '../theme/lcd_theme.dart';

/// Original pixel art: a snake curled around a padlock.
/// `L` lock outline, `M` lock body, `S` snake, `E` snake eye, `.` empty.
/// Also the source for the generated app icon (Phase 6).
const List<String> logoPixels = [
  '......................',
  '........LLLLLL........',
  '.......LL....LL.......',
  '......LL......LL..SSS.',
  '......L........L..SES.',
  '......L........L..SSS.',
  '....LLLLLLLLLLLLLL.SS.',
  '....LMMMMMMMMMMMML.SS.',
  '....LMMMMMMMMMMMML.SS.',
  '....LMMMMMLLMMMMML.SS.',
  '....LMMMMMLLMMMMML.SS.',
  '....LMMMMMLLMMMMML.SS.',
  '....LMMMMMMMMMMMML.SS.',
  '....LLLLLLLLLLLLLL.SS.',
  '...................SS.',
  '..SSSSSSSSSSSSSSSSSSS.',
  '...SSSSSSSSSSSSSSSSSS.',
  '......................',
];

class LogoArt extends StatelessWidget {
  const LogoArt({super.key, this.pixel = 6});

  final double pixel;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(logoPixels.first.length * pixel, logoPixels.length * pixel),
        painter: _LogoPainter(pixel),
      );
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.pixel);
  final double pixel;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final shadow = pixel * 0.35;
    for (final pass in [true, false]) {
      for (var y = 0; y < logoPixels.length; y++) {
        final row = logoPixels[y];
        for (var x = 0; x < row.length; x++) {
          final color = switch (row[x]) {
            'L' || 'S' => LcdPalette.ink,
            'M' => LcdPalette.inkMid,
            'E' => LcdPalette.screen,
            _ => null,
          };
          if (color == null) continue;
          if (pass && row[x] == 'E') continue;
          paint.color = pass ? LcdPalette.shadow : color;
          final o = pass ? shadow : 0.0;
          canvas.drawRect(
            Rect.fromLTWH(x * pixel + o, y * pixel + o, pixel, pixel),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.pixel != pixel;
}
