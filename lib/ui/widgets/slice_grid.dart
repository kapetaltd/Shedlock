import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../theme/lcd_theme.dart';

/// The run-summary grid in LCD shades (the share text uses emoji instead).
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
    final r = Offset.zero & size;
    final p = Paint();
    // Frame.
    p.color = LcdPalette.ink;
    canvas.drawRect(r, p);
    p.color = LcdPalette.screen;
    canvas.drawRect(r.deflate(size.width * 0.1), p);

    final inner = r.deflate(size.width * 0.2);
    switch (kind) {
      case SliceKind.quiet:
        break;
      case SliceKind.warm:
        p.color = LcdPalette.inkSoft;
        canvas.drawRect(inner, p);
      case SliceKind.hot:
        p.color = LcdPalette.inkMid;
        canvas.drawRect(inner, p);
      case SliceKind.blazing:
        p.color = LcdPalette.ink;
        canvas.drawRect(inner, p);
      case SliceKind.lock:
        // A tiny padlock.
        final u = inner.width / 6;
        p.color = LcdPalette.ink;
        canvas.drawRect(Rect.fromLTWH(inner.left + u, inner.top + u * 2.6, u * 4, u * 3.4), p);
        canvas.drawRect(Rect.fromLTWH(inner.left + u * 1.6, inner.top, u * 0.8, u * 2.8), p);
        canvas.drawRect(Rect.fromLTWH(inner.left + u * 3.6, inner.top, u * 0.8, u * 2.8), p);
        canvas.drawRect(Rect.fromLTWH(inner.left + u * 1.6, inner.top, u * 2.8, u * 0.8), p);
    }
  }

  @override
  bool shouldRepaint(_SlicePainter old) => old.kind != kind;
}
