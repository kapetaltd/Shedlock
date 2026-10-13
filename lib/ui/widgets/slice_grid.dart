import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../theme/app_theme.dart';

/// The run-summary grid in the active look (the share text uses emoji).
class SliceGrid extends StatelessWidget {
  const SliceGrid({super.key, required this.slices, this.cell = 28});

  final List<SliceKind> slices;
  final double cell;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final k in slices)
            Padding(
              padding: EdgeInsets.all(cell * 0.12),
              child: CustomPaint(size: Size.square(cell), painter: _SlicePainter(k)),
            ),
        ],
      );
}

class _SlicePainter extends CustomPainter {
  _SlicePainter(this.kind);
  final SliceKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    if (Palette.retro) {
      _paintRetro(canvas, size);
    } else {
      _paintModern(canvas, size);
    }
  }

  /// Rounded tiles, more saturated the busier that part of the run was.
  void _paintModern(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.width * 0.24));
    final p = Paint();
    p.color = switch (kind) {
      SliceKind.quiet => Palette.line,
      SliceKind.warm => Palette.accent.withValues(alpha: 0.35),
      SliceKind.hot => Palette.accent.withValues(alpha: 0.7),
      SliceKind.blazing => Palette.accent,
      SliceKind.lock => Palette.runner,
    };
    canvas.drawRRect(r, p);
    if (kind != SliceKind.lock) return;
    // A small padlock.
    final u = size.width / 10;
    final c = size.center(Offset.zero);
    p.color = const Color(0xFFFFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c.translate(0, u * 0.9), width: u * 4.4, height: u * 3.4),
        Radius.circular(u * 0.8),
      ),
      p,
    );
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.9;
    canvas.drawArc(
      Rect.fromCenter(center: c.translate(0, -u * 0.7), width: u * 2.6, height: u * 3),
      3.1416,
      3.1416,
      false,
      p,
    );
  }

  void _paintRetro(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final p = Paint();
    // Frame.
    p.color = Palette.ink;
    canvas.drawRect(r, p);
    p.color = Palette.board;
    canvas.drawRect(r.deflate(size.width * 0.1), p);

    final inner = r.deflate(size.width * 0.2);
    switch (kind) {
      case SliceKind.quiet:
        break;
      case SliceKind.warm:
        p.color = Palette.inkSoft;
        canvas.drawRect(inner, p);
      case SliceKind.hot:
        p.color = Palette.inkMid;
        canvas.drawRect(inner, p);
      case SliceKind.blazing:
        p.color = Palette.ink;
        canvas.drawRect(inner, p);
      case SliceKind.lock:
        // A tiny padlock.
        final u = inner.width / 6;
        p.color = Palette.ink;
        canvas.drawRect(Rect.fromLTWH(inner.left + u, inner.top + u * 2.6, u * 4, u * 3.4), p);
        canvas.drawRect(Rect.fromLTWH(inner.left + u * 1.6, inner.top, u * 0.8, u * 2.8), p);
        canvas.drawRect(Rect.fromLTWH(inner.left + u * 3.6, inner.top, u * 0.8, u * 2.8), p);
        canvas.drawRect(Rect.fromLTWH(inner.left + u * 1.6, inner.top, u * 2.8, u * 0.8), p);
    }
  }

  @override
  bool shouldRepaint(_SlicePainter old) => old.kind != kind;
}
