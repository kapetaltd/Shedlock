import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Original pixel art for the retro look: a snake curled around a padlock.
/// `L` lock outline, `M` lock body, `S` snake, `E` snake eye, `.` empty.
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

/// The logo in the active look: [LogoMark] (modern) or the pixel art
/// (retro). [size] is the width.
class LogoArt extends StatelessWidget {
  const LogoArt({super.key, this.size = 132});

  final double size;

  @override
  Widget build(BuildContext context) {
    if (!Palette.retro) {
      return CustomPaint(
        size: Size.square(size),
        painter: LogoMarkPainter(
          lock: Palette.ink,
          snake: Palette.snake,
          background: Palette.background,
        ),
      );
    }
    final pixel = (size / logoPixels.first.length).floorToDouble();
    return CustomPaint(
      size: Size(logoPixels.first.length * pixel, logoPixels.length * pixel),
      painter: _LogoPainter(pixel),
    );
  }
}

/// The modern logo: a padlock with a snake coiled around it. Drawn in a
/// 100×100 box scaled to the canvas. Also renders the app icon and splash
/// (see tool/render_icon_test.dart), so the icon always matches the app.
class LogoMarkPainter extends CustomPainter {
  LogoMarkPainter({required this.lock, required this.snake, required this.background});

  final Color lock;
  final Color snake;

  /// Used for the keyhole and the thin gap that separates snake and lock.
  final Color background;

  static Path _snakePath() => Path()
    ..moveTo(13, 58)
    ..cubicTo(10, 82, 32, 94, 55, 89)
    ..cubicTo(76, 85, 88, 70, 87, 53)
    ..cubicTo(86, 42, 82, 35, 75, 31);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    canvas.translate(-1.5, -4); // optical centring
    final p = Paint()..isAntiAlias = true;

    // Shackle and body.
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = lock;
    canvas.drawPath(
      Path()
        ..moveTo(37, 46)
        ..lineTo(37, 33)
        ..arcToPoint(const Offset(63, 33), radius: const Radius.circular(13))
        ..lineTo(63, 46),
      p,
    );
    p.style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromLTRBR(26, 42, 74, 82, const Radius.circular(10)),
      p,
    );
    p.color = background;
    canvas.drawCircle(const Offset(50, 58), 5.2, p);
    canvas.drawRRect(RRect.fromLTRBR(47.6, 59, 52.4, 69, const Radius.circular(2.4)), p);

    // Snake: circles along the path, tapering from the tail to the neck,
    // over a slightly wider gap in the background colour.
    final metric = _snakePath().computeMetrics().first;
    final len = metric.length;
    for (final gap in [true, false]) {
      p.color = gap ? background : snake;
      for (var d = 0.0; d <= len; d += 0.5) {
        final t = d / len;
        final r = 3 + 4.2 * Curves.easeOut.transform(t) + (gap ? 2.6 : 0);
        canvas.drawCircle(metric.getTangentForOffset(d)!.position, r, p);
      }
      final head = metric.getTangentForOffset(len)!.position;
      canvas.drawCircle(head, 9.4 + (gap ? 2.6 : 0), p);
    }

    // Eye, looking towards the lock.
    final head = metric.getTangentForOffset(len)!.position;
    final light = snake.computeLuminance() > 0.6;
    p.color = light ? background : const Color(0xFFFFFFFF);
    canvas.drawCircle(head.translate(-2.6, -1.8), 3.4, p);
    p.color = light ? snake : const Color(0xFF1B1F23);
    canvas.drawCircle(head.translate(-3.6, -2.2), 1.7, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(LogoMarkPainter old) =>
      old.lock != lock || old.snake != snake || old.background != background;
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
            'L' || 'S' => Palette.ink,
            'M' => Palette.inkMid,
            'E' => Palette.board,
            _ => null,
          };
          if (color == null) continue;
          if (pass && row[x] == 'E') continue;
          paint.color = pass ? Palette.shadow : color;
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
