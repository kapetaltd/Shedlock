import 'dart:ui';

import '../core/core.dart';
import 'lcd_palette.dart';

/// Draws a snake in any [SnakeSkin]. Shared by the board and the shop
/// preview so both always match.
class SnakeSkinPainter {
  SnakeSkinPainter() : _fill = Paint();

  final Paint _fill;

  /// [cells] are segment rectangles, head first. [cell] is the cell size.
  /// Consecutive segments are joined by a bridge when they are adjacent.
  void paint(
    Canvas canvas, {
    required List<Rect> cells,
    required double cell,
    required SnakeSkin skin,
    required Direction heading,
    required Color ink,
    bool shadowPass = false,
  }) {
    if (cells.isEmpty) return;
    _fill.color = ink;

    final bridgeInset = cell * 0.24;
    for (var i = 0; i < cells.length - 1; i++) {
      final a = cells[i];
      final b = cells[i + 1];
      if ((a.center - b.center).distance <= cell * 1.01) {
        canvas.drawRect(a.deflate(bridgeInset).expandToInclude(b.deflate(bridgeInset)), _fill);
      }
    }
    final inset = cell * 0.11;
    for (var i = 0; i < cells.length; i++) {
      final shrink = i == cells.length - 1 && cells.length > 1 ? cell * 0.1 : 0.0;
      canvas.drawRect(cells[i].deflate(inset + shrink), _fill);
    }
    if (shadowPass) return;

    // Skin pattern on the body (the head stays plain so the eyes read).
    for (var i = 1; i < cells.length; i++) {
      final r = cells[i];
      switch (skin) {
        case SnakeSkin.classic:
          break;
        case SnakeSkin.striped:
          if (i.isOdd) {
            _fill.color = LcdPalette.inkMid;
            canvas.drawRect(r.deflate(cell * 0.24), _fill);
          }
        case SnakeSkin.dotted:
          _fill.color = LcdPalette.screen;
          canvas.drawRect(Rect.fromCenter(center: r.center, width: cell * 0.2, height: cell * 0.2), _fill);
        case SnakeSkin.hollow:
          _fill.color = LcdPalette.screen;
          canvas.drawRect(r.deflate(cell * 0.3), _fill);
      }
    }

    // Eyes, facing the heading.
    final head = cells.first;
    final e = cell * 0.16;
    final fwd = Offset(heading.dx * cell * 0.18, heading.dy * cell * 0.18);
    final side = Offset(heading.dy.abs() * cell * 0.2, heading.dx.abs() * cell * 0.2);
    _fill.color = LcdPalette.screen;
    for (final sgn in const [-1.0, 1.0]) {
      final c = head.center + fwd + side * sgn;
      canvas.drawRect(Rect.fromCenter(center: c, width: e, height: e), _fill);
    }
  }

  /// Draws the [trail] cosmetic at [pos] that is [age] seconds old.
  void paintTrail(Canvas canvas, Trail trail, Rect r, double age, double life) {
    final fade = (1 - age / life).clamp(0.0, 1.0);
    if (fade <= 0) return;
    final cell = r.width;
    switch (trail) {
      case Trail.none:
        break;
      case Trail.ghost:
        _fill.color = LcdPalette.inkSoft.withValues(alpha: 0.65 * fade);
        canvas.drawRect(r.deflate(cell * (0.18 + 0.15 * (1 - fade))), _fill);
      case Trail.dust:
        _fill.color = LcdPalette.inkMid.withValues(alpha: fade);
        // Three specks that settle downwards as they fade.
        final seed = (r.left * 7 + r.top * 13).round();
        for (var k = 0; k < 3; k++) {
          final dx = (((seed >> k) % 5) - 2) * cell * 0.15;
          final dy = (k - 1) * cell * 0.15 + (1 - fade) * cell * 0.3;
          canvas.drawRect(
            Rect.fromCenter(center: r.center.translate(dx, dy), width: cell * 0.14, height: cell * 0.14),
            _fill,
          );
        }
    }
  }
}
