import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/core.dart';
import '../palette.dart';
import '../shedlock_game.dart';
import '../snake_interpolation.dart';
import '../snake_skin_painter.dart';

/// Draws the board, obstacles, shed walls, food and snake in the active
/// look: soft rounded shapes (modern) or chunky LCD blocks (retro).
class BoardComponent extends Component with HasGameReference<ShedlockGame> {
  BoardComponent() : super(priority: 0);

  final Paint _fill = Paint();
  final Paint _ring = Paint()..style = PaintingStyle.stroke;
  final SnakeSkinPainter _skin = SnakeSkinPainter();

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(game.shakeOffset.dx, game.shakeOffset.dy);
    if (Palette.retro) {
      _renderRetro(canvas);
    } else {
      _renderModern(canvas);
    }
    canvas.restore();
  }

  Rect get _boardRect {
    final m = game.metrics;
    final c = game.session.state.config;
    return Rect.fromLTWH(m.origin.dx, m.origin.dy, m.cell * c.width, m.cell * c.height);
  }

  /// Exits a runner still has (1 means it is one move from being locked).
  int _exits(GameState s, Food f) {
    final blocked = {
      ...s.snake,
      for (final w in s.shedWalls) w.pos,
      for (final o in s.foods) if (o.id != f.id) o.pos,
    };
    return RunnerAi.legalMoves(s.layout, f.pos, blocked.contains).length;
  }

  // --- Modern -----------------------------------------------------------------

  void _renderModern(Canvas canvas) {
    final m = game.metrics;
    final s = game.session.state;
    final c = s.config;
    final cell = m.cell;
    final boardRect = _boardRect;
    final outer = RRect.fromRectAndRadius(boardRect.inflate(cell * 0.2), Radius.circular(cell * 0.7));

    // Soft card shadow, then the board itself.
    _fill
      ..color = Palette.shadow
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.6);
    canvas.drawRRect(outer.shift(Offset(0, cell * 0.25)), _fill);
    _fill.maskFilter = null;

    // After death the board slowly loses its colour.
    final died = game.diedAt;
    final desaturate = s.isDead && died != null;
    if (desaturate) {
      final t = ((game.animTime - died) / 0.6).clamp(0.0, 1.0);
      canvas.saveLayer(
        outer.outerRect.inflate(cell),
        Paint()..colorFilter = ColorFilter.matrix(_saturation(1 - 0.8 * t)),
      );
    }

    _fill.color = Palette.board;
    canvas.drawRRect(outer, _fill);

    // A faint dot in each cell so distances can be judged.
    _fill.color = Palette.boardAlt;
    final dot = math.max(1.0, cell * 0.07);
    for (var y = 0; y < c.height; y++) {
      for (var x = 0; x < c.width; x++) {
        canvas.drawCircle(m.cellRect(x.toDouble(), y.toDouble()).center, dot, _fill);
      }
    }

    // Obstacles: soft rounded tiles with a small shadow.
    final tileRadius = Radius.circular(cell * 0.24);
    for (final o in s.layout.obstacles) {
      final r = RRect.fromRectAndRadius(
        m.cellRect(o.x.toDouble(), o.y.toDouble()).deflate(cell * 0.07),
        tileRadius,
      );
      _fill.color = Palette.shadow;
      canvas.drawRRect(r.shift(Offset(0, cell * 0.07)), _fill);
      _fill.color = Palette.obstacle;
      canvas.drawRRect(r, _fill);
    }

    // Shed walls: shrink and fade as they expire.
    final now = game.renderTimeMs;
    for (final w in s.shedWalls) {
      final o = shedWallOpacity(w, now);
      final left = w.remainingFraction(now.round());
      final r = RRect.fromRectAndRadius(
        m.cellRect(w.pos.x.toDouble(), w.pos.y.toDouble()).deflate(cell * (0.08 + 0.14 * (1 - left))),
        tileRadius,
      );
      _fill.color = Palette.wall.withValues(alpha: o);
      canvas.drawRRect(r, _fill);
    }

    // Food: a gently pulsing dot with a halo.
    final pulse = 1 + 0.07 * math.sin(game.animTime * 5);
    final before = {for (final f in game.previous.foods) f.id: f.pos};
    for (final f in s.foods) {
      final center = m.cellRect(f.pos.x.toDouble(), f.pos.y.toDouble()).center;
      if (f.isRunner) {
        _drawModernRunner(canvas, s, f, before[f.id], cell);
      } else {
        _fill.color = Palette.food.withValues(alpha: 0.18);
        canvas.drawCircle(center, cell * 0.47 * pulse, _fill);
        _fill.color = Palette.food;
        canvas.drawCircle(center, cell * 0.3 * pulse, _fill);
        _fill.color = const Color(0x66FFFFFF);
        canvas.drawCircle(center.translate(-cell * 0.09, -cell * 0.09), cell * 0.08, _fill);
      }
    }

    _drawTrail(canvas);

    final snakePts = interpolateSnake(game.previous.snake, s.snake, game.alpha);
    _skin.paintModern(
      canvas,
      cells: [for (final p in snakePts) m.cellRect(p.x, p.y)],
      cell: cell,
      skin: game.loadout.skin,
      heading: s.heading,
    );

    if (desaturate) canvas.restore();
  }

  void _drawModernRunner(Canvas canvas, GameState s, Food f, GridPos? from, double cell) {
    final m = game.metrics;
    // Slide smoothly from the previous cell.
    final a = game.alpha;
    final p = from != null && from.manhattanTo(f.pos) == 1
        ? Offset(from.x + (f.pos.x - from.x) * a, from.y + (f.pos.y - from.y) * a)
        : Offset(f.pos.x.toDouble(), f.pos.y.toDouble());
    final center = m.cellRect(p.dx, p.dy).center;

    // A fading echo where it just was.
    if (from != null && from != f.pos) {
      _fill.color = Palette.runner.withValues(alpha: 0.25 * (1 - a));
      canvas.drawCircle(m.cellRect(from.x.toDouble(), from.y.toDouble()).center, cell * 0.24, _fill);
    }

    // One exit left: a pulsing ring says "almost locked".
    if (_exits(s, f) == 1) {
      final k = 0.5 + 0.5 * math.sin(game.animTime * 10);
      _ring
        ..strokeWidth = cell * 0.08
        ..color = Palette.runner.withValues(alpha: 0.45 + 0.4 * k);
      canvas.drawCircle(center, cell * (0.5 + 0.06 * k), _ring);
    }

    _fill.color = Palette.shadow;
    canvas.drawCircle(center.translate(0, cell * 0.07), cell * 0.34, _fill);
    _fill.color = Palette.runner;
    canvas.drawCircle(center, cell * 0.34, _fill);

    // Little eyes, looking where it is heading.
    final dir = from == null || from == f.pos
        ? Offset.zero
        : Offset((f.pos.x - from.x).toDouble(), (f.pos.y - from.y).toDouble());
    for (final sx in const [-1.0, 1.0]) {
      final e = center.translate(sx * cell * 0.11, -cell * 0.04);
      _fill.color = const Color(0xFFFFFFFF);
      canvas.drawCircle(e, cell * 0.085, _fill);
      _fill.color = const Color(0xFF1B1F23);
      canvas.drawCircle(e + dir * cell * 0.03, cell * 0.045, _fill);
    }
  }

  /// Colour matrix that scales saturation (1 = unchanged, 0 = grey).
  static List<double> _saturation(double s) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final i = 1 - s;
    return [
      r * i + s, g * i, b * i, 0, 0,
      r * i, g * i + s, b * i, 0, 0,
      r * i, g * i, b * i + s, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  void _drawTrail(Canvas canvas) {
    if (game.loadout.trail == Trail.none) return;
    final m = game.metrics;
    for (final (pos, t) in game.trail) {
      _skin.paintTrail(
        canvas,
        game.loadout.trail,
        m.cellRect(pos.x.toDouble(), pos.y.toDouble()),
        game.animTime - t,
        ShedlockGame.trailSeconds,
      );
    }
  }

  // --- Retro ------------------------------------------------------------------

  void _renderRetro(Canvas canvas) {
    final m = game.metrics;
    final s = game.session.state;
    final c = s.config;
    final cell = m.cell;

    // Frame and screen.
    final boardRect = _boardRect;
    _fill.color = Palette.ink;
    canvas.drawRect(boardRect.inflate(3), _fill);
    _fill.color = Palette.board;
    canvas.drawRect(boardRect, _fill);

    // Unlit pixel ghosting.
    _fill.color = Palette.boardAlt;
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
    _drawRetroScene(canvas, s, snakePts, shadowPass: true);
    canvas.restore();
    _drawRetroScene(canvas, s, snakePts, shadowPass: false);
  }

  void _drawRetroScene(
    Canvas canvas,
    GameState s,
    List<CellPoint> snake,
    {required bool shadowPass}
  ) {
    final m = game.metrics;
    final cell = m.cell;
    Color col(Color c, [double opacity = 1]) => shadowPass
        ? Palette.shadow.withValues(alpha: Palette.shadow.a * opacity)
        : c.withValues(alpha: c.a * opacity);

    // Obstacles: solid blocks with a diagonal hatch, so they read as
    // permanent and never get confused with food.
    for (final o in s.layout.obstacles) {
      final r = m.cellRect(o.x.toDouble(), o.y.toDouble()).deflate(cell * 0.02);
      _fill.color = col(Palette.ink);
      canvas.drawRect(r, _fill);
      if (!shadowPass) {
        _fill.color = Palette.inkMid;
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
      _fill.color = col(Palette.inkMid, o);
      canvas.drawRect(r, _fill);
      if (!shadowPass) {
        _fill.color = Palette.board.withValues(alpha: 0.55 * o);
        final q = r.width / 2;
        canvas.drawRect(Rect.fromLTWH(r.left, r.top, q, q).deflate(cell * 0.08), _fill);
        canvas.drawRect(Rect.fromLTWH(r.left + q, r.top + q, q, q).deflate(cell * 0.08), _fill);
      }
    }

    // Food.
    for (final f in s.foods) {
      final r = m.cellRect(f.pos.x.toDouble(), f.pos.y.toDouble());
      if (f.isRunner) {
        _drawRetroRunner(canvas, s, f, r, col, shadowPass: shadowPass);
      } else {
        _drawRetroFood(canvas, r, col);
      }
    }

    // Trail cosmetic, under the snake.
    if (!shadowPass) _drawTrail(canvas);

    // Snake. Blinks after death.
    if (s.isDead && (game.animTime * 6).floor().isEven) return;
    _skin.paintRetro(
      canvas,
      cells: [for (final p in snake) m.cellRect(p.x, p.y)],
      cell: cell,
      skin: game.loadout.skin,
      heading: s.heading,
      ink: col(Palette.ink),
      shadowPass: shadowPass,
    );
  }

  void _drawRetroFood(Canvas canvas, Rect r, Color Function(Color, [double]) col) {
    // A pixel "plus": centre and four arms.
    final u = r.width / 4;
    final cx = r.center.dx;
    final cy = r.center.dy;
    _fill.color = col(Palette.ink);
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: u * 1.2, height: u * 1.2), _fill);
    for (final d in const [Offset(1, 0), Offset(-1, 0), Offset(0, 1), Offset(0, -1)]) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset(cx + d.dx * u, cy + d.dy * u), width: u * 0.9, height: u * 0.9),
        _fill,
      );
    }
  }

  void _drawRetroRunner(
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
    _fill.color = col(Palette.ink);
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
      _fill.color = Palette.board;
      for (final sx in const [-1.0, 1.0]) {
        canvas.drawRect(
          Rect.fromCenter(center: r.center.translate(sx * u * 0.55, -u * 0.6), width: u * 0.6, height: u * 0.6),
          _fill,
        );
      }
      _fill.color = Palette.ink;
    }

    // "Almost locked" hint: corner brackets when only one escape is left.
    if (_exits(s, f) == 1 && (game.animTime * 8).floor().isEven) {
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
}
