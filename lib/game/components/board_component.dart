import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/core.dart';
import '../lcd_palette.dart';
import '../shedlock_game.dart';
import '../snake_interpolation.dart';

/// Draws the board, obstacles, shed walls, food and snake in the LCD style:
/// chunky ink blocks with a soft offset shadow over a ghosted pixel grid.
class BoardComponent extends Component with HasGameReference<ShedlockGame> {
  BoardComponent() : super(priority: 0);

  final Paint _fill = Paint();

  @override
  void render(Canvas canvas) {
    final m = game.metrics;
    final s = game.session.state;
    final c = s.config;
    final cell = m.cell;

    canvas.save();
    canvas.translate(game.shakeOffset.dx, game.shakeOffset.dy);

    // Frame and screen.
    final boardRect = Rect.fromLTWH(m.origin.dx, m.origin.dy, cell * c.width, cell * c.height);
    _fill.color = LcdPalette.ink;
    canvas.drawRect(boardRect.inflate(3), _fill);
    _fill.color = LcdPalette.screen;
    canvas.drawRect(boardRect, _fill);

    // Unlit pixel ghosting.
    _fill.color = LcdPalette.ghost;
    final gi = cell * 0.08;
    for (var y = 0; y < c.height; y++) {
      for (var x = 0; x < c.width; x++) {
        canvas.drawRect(m.cellRect(x.toDouble(), y.toDouble()).deflate(gi), _fill);
      }
    }

    final snakePts = interpolateSnake(game.previous.snake, s.snake, game.alpha);

    // Shadow pass, then ink pass.
    final shadow = cell * 0.12;
    canvas.save();
    canvas.translate(shadow, shadow);
    _drawScene(canvas, s, snakePts, shadowPass: true);
    canvas.restore();
    _drawScene(canvas, s, snakePts, shadowPass: false);

    canvas.restore();
  }

  void _drawScene(
    Canvas canvas,
    GameState s,
    List<CellPoint> snake,
    {required bool shadowPass}
  ) {
    final m = game.metrics;
    final cell = m.cell;
    Color col(Color c, [double opacity = 1]) => shadowPass
        ? LcdPalette.shadow.withValues(alpha: LcdPalette.shadow.a * opacity)
        : c.withValues(alpha: c.a * opacity);

    // Obstacles: solid blocks with a diagonal hatch, so they read as
    // permanent and never get confused with food.
    for (final o in s.layout.obstacles) {
      final r = m.cellRect(o.x.toDouble(), o.y.toDouble()).deflate(cell * 0.02);
      _fill.color = col(LcdPalette.ink);
      canvas.drawRect(r, _fill);
      if (!shadowPass) {
        _fill.color = LcdPalette.inkMid;
        final u = r.width / 5;
        for (var i = 0; i < 4; i++) {
          canvas.drawRect(Rect.fromLTWH(r.left + u * (i + 0.5), r.top + u * (3.5 - i), u, u), _fill);
        }
      }
    }

    // Shed walls: checkered mid-tone blocks that fade and flicker.
    final now = game.renderTimeMs;
    for (final w in s.shedWalls) {
      final o = shedWallOpacity(w, now);
      final r = m.cellRect(w.pos.x.toDouble(), w.pos.y.toDouble()).deflate(cell * 0.06);
      _fill.color = col(LcdPalette.inkMid, o);
      canvas.drawRect(r, _fill);
      if (!shadowPass) {
        _fill.color = LcdPalette.screen.withValues(alpha: 0.55 * o);
        final q = r.width / 2;
        canvas.drawRect(Rect.fromLTWH(r.left, r.top, q, q).deflate(cell * 0.08), _fill);
        canvas.drawRect(Rect.fromLTWH(r.left + q, r.top + q, q, q).deflate(cell * 0.08), _fill);
      }
    }

    // Food.
    for (final f in s.foods) {
      final r = m.cellRect(f.pos.x.toDouble(), f.pos.y.toDouble());
      if (f.isRunner) {
        _drawRunner(canvas, s, f, r, col, shadowPass: shadowPass);
      } else {
        _drawFood(canvas, r, col);
      }
    }

    // Snake. Blinks after death.
    if (s.isDead && (game.animTime * 6).floor().isEven) return;
    _drawSnake(canvas, s, snake, col, shadowPass: shadowPass);
  }

  void _drawFood(Canvas canvas, Rect r, Color Function(Color, [double]) col) {
    // A pixel "plus": centre and four arms.
    final u = r.width / 4;
    final cx = r.center.dx;
    final cy = r.center.dy;
    _fill.color = col(LcdPalette.ink);
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: u * 1.2, height: u * 1.2), _fill);
    for (final d in const [Offset(1, 0), Offset(-1, 0), Offset(0, 1), Offset(0, -1)]) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset(cx + d.dx * u, cy + d.dy * u), width: u * 0.9, height: u * 0.9),
        _fill,
      );
    }
  }

  void _drawRunner(
    Canvas canvas,
    GameState s,
    Food f,
    Rect r,
    Color Function(Color, [double]) col, {
    required bool shadowPass,
  }) {
    final cell = r.width;
    // A little bug: a body with four legs that scuttle (toggle in/out).
    final u = cell / 6;
    final legsOut = (game.animTime * 5).floor().isEven;
    _fill.color = col(LcdPalette.ink);
    canvas.drawRect(Rect.fromCenter(center: r.center, width: u * 2.4, height: u * 2.8), _fill);
    final spread = legsOut ? u * 2.0 : u * 1.5;
    for (final sx in const [-1.0, 1.0]) {
      for (final sy in const [-1.0, 1.0]) {
        final c = r.center.translate(sx * spread, sy * (legsOut ? u * 1.3 : u * 1.7));
        canvas.drawRect(Rect.fromCenter(center: c, width: u, height: u), _fill);
      }
    }
    if (!shadowPass) {
      // Eyes.
      _fill.color = LcdPalette.screen;
      for (final sx in const [-1.0, 1.0]) {
        canvas.drawRect(
          Rect.fromCenter(center: r.center.translate(sx * u * 0.55, -u * 0.6), width: u * 0.6, height: u * 0.6),
          _fill,
        );
      }
      _fill.color = LcdPalette.ink;
    }

    // "Almost locked" hint: corner brackets when only one escape is left.
    final blocked = {
      ...s.snake,
      for (final w in s.shedWalls) w.pos,
      for (final o in s.foods) if (o.id != f.id) o.pos,
    };
    final exits = RunnerAi.legalMoves(s.layout, f.pos, blocked.contains).length;
    if (exits == 1 && (game.animTime * 8).floor().isEven) {
      final b = r.inflate(cell * 0.12);
      final l = cell * 0.3;
      final t = cell * 0.1;
      for (final corner in [b.topLeft, b.topRight, b.bottomLeft, b.bottomRight]) {
        final sx = corner.dx == b.left ? 1.0 : -1.0;
        final sy = corner.dy == b.top ? 1.0 : -1.0;
        canvas.drawRect(Rect.fromPoints(corner, corner.translate(l * sx, t * sy)), _fill);
        canvas.drawRect(Rect.fromPoints(corner, corner.translate(t * sx, l * sy)), _fill);
      }
    }
  }

  void _drawSnake(
    Canvas canvas,
    GameState s,
    List<CellPoint> pts,
    Color Function(Color, [double]) col, {
    required bool shadowPass,
  }) {
    if (pts.isEmpty) return;
    final m = game.metrics;
    final cell = m.cell;
    final inset = cell * 0.08;
    _fill.color = col(LcdPalette.ink);

    // Bridges between consecutive segments keep the body continuous while
    // segments slide.
    final bridgeInset = cell * 0.24;
    for (var i = 0; i < pts.length - 1; i++) {
      final a = m.cellRect(pts[i].x, pts[i].y).deflate(bridgeInset);
      final b = m.cellRect(pts[i + 1].x, pts[i + 1].y).deflate(bridgeInset);
      if ((pts[i].x - pts[i + 1].x).abs() + (pts[i].y - pts[i + 1].y).abs() <= 1.01) {
        canvas.drawRect(a.expandToInclude(b), _fill);
      }
    }
    for (var i = 0; i < pts.length; i++) {
      final shrink = i == pts.length - 1 && pts.length > 1 ? cell * 0.1 : 0.0;
      canvas.drawRect(m.cellRect(pts[i].x, pts[i].y).deflate(inset * 1.4 + shrink), _fill);
    }

    // Eyes on the head, facing the heading.
    if (shadowPass) return;
    final head = m.cellRect(pts.first.x, pts.first.y);
    final e = cell * 0.16;
    final h = s.heading;
    final fwd = Offset(h.dx * cell * 0.18, h.dy * cell * 0.18);
    final side = Offset(h.dy.abs() * cell * 0.2, h.dx.abs() * cell * 0.2);
    _fill.color = LcdPalette.screen;
    for (final sgn in const [-1.0, 1.0]) {
      final c = head.center + fwd + side * sgn;
      canvas.drawRect(Rect.fromCenter(center: c, width: e, height: e), _fill);
    }
  }
}
