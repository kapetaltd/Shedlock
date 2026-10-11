import 'dart:math' as math;
import 'dart:ui';

import '../core/core.dart';
import 'palette.dart';

/// Draws a snake in any [SnakeSkin], in the active look. Shared by the
/// board and the shop preview so both always match.
class SnakeSkinPainter {
  final Paint _fill = Paint();

  /// [cells] are segment rectangles, head first. [cell] is the cell size.
  void paint(
    Canvas canvas, {
    required List<Rect> cells,
    required double cell,
    required SnakeSkin skin,
    required Direction heading,
  }) {
    if (Palette.retro) {
      paintRetro(canvas, cells: cells, cell: cell, skin: skin, heading: heading, ink: Palette.ink);
    } else {
      paintModern(canvas, cells: cells, cell: cell, skin: skin, heading: heading);
    }
  }

  // --- Modern -----------------------------------------------------------------

  /// A smooth, tapering tube with a soft shadow and a round head.
  void paintModern(
    Canvas canvas, {
    required List<Rect> cells,
    required double cell,
    required SnakeSkin skin,
    required Direction heading,
    double opacity = 1,
  }) {
    if (cells.isEmpty) return;
    final pts = [for (final r in cells) r.center];
    final n = pts.length;
    double radius(int i) {
      if (i == 0) return cell * 0.42;
      final t = n <= 2 ? 1.0 : (i - 1) / (n - 2);
      return cell * (0.38 - 0.11 * math.pow(t, 1.4));
    }

    final radii = [for (var i = 0; i < n; i++) radius(i)];

    // Shadow: drawn opaque into a layer, then the layer is made
    // translucent, so overlapping segments don't darken each other.
    final shadow = Palette.shadow;
    final bounds = _bounds(pts, cell);
    canvas.saveLayer(bounds, Paint()..color = Color.fromRGBO(0, 0, 0, shadow.a * opacity));
    canvas.translate(0, cell * 0.1);
    _tube(canvas, pts, radii, cell, shadow.withValues(alpha: 1), from: 0);
    canvas.restore();

    if (opacity < 1) canvas.saveLayer(bounds, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));

    _tube(canvas, pts, radii, cell, Palette.snake, from: 0);

    // Skin pattern on the body (the head stays plain so the eyes read).
    switch (skin) {
      case SnakeSkin.classic:
        break;
      case SnakeSkin.striped:
        _fill.color = Palette.snakeAlt;
        for (var i = 2; i < n; i += 2) {
          canvas.drawCircle(pts[i], radii[i] * 0.98, _fill);
        }
      case SnakeSkin.dotted:
        _fill.color = Palette.board.withValues(alpha: 0.8);
        for (var i = 1; i < n; i++) {
          canvas.drawCircle(pts[i], radii[i] * 0.34, _fill);
        }
      case SnakeSkin.hollow:
        final inner = [for (final r in radii) math.max(0.0, r - cell * 0.1)];
        _tube(canvas, pts, inner, cell, Palette.board, from: 1);
    }

    // Head on top, with eyes looking where it is going.
    final head = pts.first;
    _fill.color = Palette.snake;
    canvas.drawCircle(head, radii.first, _fill);
    final light = Palette.snake.computeLuminance() > 0.6;
    final white = light ? Palette.board : const Color(0xFFFFFFFF);
    final pupil = light ? Palette.snake : const Color(0xFF1B1F23);
    final fwd = Offset(heading.dx * cell * 0.12, heading.dy * cell * 0.12);
    final side = Offset(heading.dy.abs() * cell * 0.17, heading.dx.abs() * cell * 0.17);
    for (final sgn in const [-1.0, 1.0]) {
      final c = head + fwd + side * sgn;
      _fill.color = white;
      canvas.drawCircle(c, cell * 0.12, _fill);
      _fill.color = pupil;
      canvas.drawCircle(c + fwd * 0.4, cell * 0.065, _fill);
    }

    if (opacity < 1) canvas.restore();
  }

  /// Round joints at [pts] joined by tapered bridges, so the body narrows
  /// smoothly. Skips joins between non-adjacent points, and starts at
  /// segment [from].
  void _tube(Canvas canvas, List<Offset> pts, List<double> radii, double cell, Color color,
      {required int from}) {
    _fill.color = color;
    for (var i = pts.length - 1; i >= from; i--) {
      if (i + 1 < pts.length && (pts[i] - pts[i + 1]).distance <= cell * 1.01) {
        final a = pts[i];
        final b = pts[i + 1];
        final d = b - a;
        final len = d.distance;
        if (len > 0.01) {
          final n = Offset(-d.dy / len, d.dx / len);
          canvas.drawPath(
            Path()
              ..moveTo(a.dx + n.dx * radii[i], a.dy + n.dy * radii[i])
              ..lineTo(b.dx + n.dx * radii[i + 1], b.dy + n.dy * radii[i + 1])
              ..lineTo(b.dx - n.dx * radii[i + 1], b.dy - n.dy * radii[i + 1])
              ..lineTo(a.dx - n.dx * radii[i], a.dy - n.dy * radii[i])
              ..close(),
            _fill,
          );
        }
      }
      if (radii[i] > 0) canvas.drawCircle(pts[i], radii[i], _fill);
    }
  }

  Rect _bounds(List<Offset> pts, double cell) {
    var r = Rect.fromCenter(center: pts.first, width: cell, height: cell);
    for (final p in pts) {
      r = r.expandToInclude(Rect.fromCenter(center: p, width: cell, height: cell));
    }
    return r.inflate(cell * 0.3);
  }

  // --- Retro ------------------------------------------------------------------

  /// Chunky LCD blocks. The board draws this twice: once in the shadow
  /// colour (offset), once in [ink].
  void paintRetro(
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

    for (var i = 1; i < cells.length; i++) {
      final r = cells[i];
      switch (skin) {
        case SnakeSkin.classic:
          break;
        case SnakeSkin.striped:
          if (i.isOdd) {
            _fill.color = Palette.inkMid;
            canvas.drawRect(r.deflate(cell * 0.24), _fill);
          }
        case SnakeSkin.dotted:
          _fill.color = Palette.board;
          canvas.drawRect(Rect.fromCenter(center: r.center, width: cell * 0.2, height: cell * 0.2), _fill);
        case SnakeSkin.hollow:
          _fill.color = Palette.board;
          canvas.drawRect(r.deflate(cell * 0.3), _fill);
      }
    }

    final head = cells.first;
    final e = cell * 0.16;
    final fwd = Offset(heading.dx * cell * 0.18, heading.dy * cell * 0.18);
    final side = Offset(heading.dy.abs() * cell * 0.2, heading.dx.abs() * cell * 0.2);
    _fill.color = Palette.board;
    for (final sgn in const [-1.0, 1.0]) {
      final c = head.center + fwd + side * sgn;
      canvas.drawRect(Rect.fromCenter(center: c, width: e, height: e), _fill);
    }
  }

  // --- Trails -----------------------------------------------------------------

  /// Draws the [trail] cosmetic at [r] that is [age] seconds old.
  void paintTrail(Canvas canvas, Trail trail, Rect r, double age, double life) {
    final fade = (1 - age / life).clamp(0.0, 1.0);
    if (fade <= 0 || trail == Trail.none) return;
    final cell = r.width;
    final seed = (r.left * 7 + r.top * 13).round();
    if (Palette.retro) {
      switch (trail) {
        case Trail.none:
          break;
        case Trail.ghost:
          _fill.color = Palette.inkSoft.withValues(alpha: 0.65 * fade);
          canvas.drawRect(r.deflate(cell * (0.18 + 0.15 * (1 - fade))), _fill);
        case Trail.dust:
          _fill.color = Palette.inkMid.withValues(alpha: fade);
          // Three specks that settle downwards as they fade.
          for (var k = 0; k < 3; k++) {
            final dx = (((seed >> k) % 5) - 2) * cell * 0.15;
            final dy = (k - 1) * cell * 0.15 + (1 - fade) * cell * 0.3;
            canvas.drawRect(
              Rect.fromCenter(center: r.center.translate(dx, dy), width: cell * 0.14, height: cell * 0.14),
              _fill,
            );
          }
      }
      return;
    }
    switch (trail) {
      case Trail.none:
        break;
      case Trail.ghost:
        _fill.color = Palette.snake.withValues(alpha: 0.32 * fade);
        canvas.drawCircle(r.center, cell * 0.3 * (0.55 + 0.45 * fade), _fill);
      case Trail.dust:
        // Three little sparkles that drift up as they fade.
        for (var k = 0; k < 3; k++) {
          final dx = (((seed >> k) % 5) - 2) * cell * 0.14;
          final dy = (k - 1) * cell * 0.14 - (1 - fade) * cell * 0.35;
          final c = r.center.translate(dx, dy);
          final s = cell * (0.05 + 0.05 * fade);
          _fill.color = (k.isEven ? Palette.runner : Palette.snake).withValues(alpha: fade);
          canvas.drawPath(_sparkle(c, s * 1.9), _fill);
        }
    }
  }

  /// A four-pointed star.
  Path _sparkle(Offset c, double s) {
    final w = s * 0.32;
    return Path()
      ..moveTo(c.dx, c.dy - s)
      ..quadraticBezierTo(c.dx + w * 0.3, c.dy - w * 0.3, c.dx + s, c.dy)
      ..quadraticBezierTo(c.dx + w * 0.3, c.dy + w * 0.3, c.dx, c.dy + s)
      ..quadraticBezierTo(c.dx - w * 0.3, c.dy + w * 0.3, c.dx - s, c.dy)
      ..quadraticBezierTo(c.dx - w * 0.3, c.dy - w * 0.3, c.dx, c.dy - s)
      ..close();
  }
}
