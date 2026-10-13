import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle, FontWeight;

import '../../core/core.dart';
import '../palette.dart';
import '../shedlock_game.dart';

enum _FxKind { pop, ring, spark, label }

class _Fx {
  _Fx(this.kind, this.x, this.y, this.life, [this.text = '']);
  final _FxKind kind;
  final double x;
  final double y;
  final double life;
  final String text;
  double age = 0;
  double get t => (age / life).clamp(0.0, 1.0);
}

/// Short-lived visual effects driven by game events: eat pops, lock rings,
/// shed sparks and floating score labels.
class EffectsComponent extends Component with HasGameReference<ShedlockGame> {
  EffectsComponent() : super(priority: 10);

  final List<_Fx> _fx = [];
  final Paint _paint = Paint();
  final Map<int, TextPaint> _textCache = {};

  void handle(List<GameEvent> events) {
    for (final e in events) {
      switch (e) {
        case FoodEaten(:final food, :final points):
          _fx.add(_Fx(_FxKind.pop, food.pos.x + 0.5, food.pos.y + 0.5, 0.3));
          _fx.add(_Fx(_FxKind.label, food.pos.x + 0.5, food.pos.y.toDouble(), 0.7, '+$points'));
        case RunnerLocked(:final food, :final bonus):
          _fx.add(_Fx(_FxKind.ring, food.pos.x + 0.5, food.pos.y + 0.5, 0.7));
          _fx.add(_Fx(_FxKind.label, food.pos.x + 0.5, food.pos.y.toDouble(), 1.1, Palette.retro ? 'LOCK +$bonus' : 'Lock +$bonus'));
          game.shake(0.15, game.metrics.cell * (Palette.retro ? 0.15 : 0.1));
        case Shed(:final wallCells):
          for (final p in wallCells) {
            _fx.add(_Fx(_FxKind.spark, p.x + 0.5, p.y + 0.5, 0.35));
          }
        default:
          break;
      }
    }
  }

  void clear() => _fx.clear();

  @override
  void update(double dt) {
    for (final f in _fx) {
      f.age += dt;
    }
    _fx.removeWhere((f) => f.age >= f.life);
  }

  TextPaint _text(double size) => _textCache.putIfAbsent(
        Object.hash(size.round(), Palette.ink),
        () => TextPaint(
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: size.roundToDouble(),
            color: Palette.ink,
          ),
        ),
      );

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

  /// Keeps a label inside the board and below its top edge.
  Offset _labelPos(Offset center, double half, double t) {
    final m = game.metrics;
    final cell = m.cell;
    final c = game.session.state.config;
    final minX = m.origin.dx + half + 2;
    final maxX = m.origin.dx + c.width * cell - half - 2;
    final x = minX > maxX ? center.dx : center.dx.clamp(minX, maxX);
    final y = (center.dy - cell * (0.3 + t * 1.2)).clamp(m.origin.dy + cell, double.infinity);
    return Offset(x, y);
  }

  void _renderModern(Canvas canvas) {
    final m = game.metrics;
    final cell = m.cell;
    for (final f in _fx) {
      final center = Offset(m.origin.dx + f.x * cell, m.origin.dy + f.y * cell);
      final fade = 1 - f.t;
      final ease = 1 - (1 - f.t) * (1 - f.t);
      switch (f.kind) {
        case _FxKind.pop:
          _paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.1 * fade + 0.5
            ..color = Palette.food.withValues(alpha: fade);
          canvas.drawCircle(center, cell * (0.3 + 0.55 * ease), _paint);
        case _FxKind.ring:
          _paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.14 * fade + 0.5
            ..color = Palette.runner.withValues(alpha: fade);
          for (final k in const [1.0, 1.7]) {
            canvas.drawCircle(center, cell * (0.4 + 1.3 * ease * k), _paint);
          }
        case _FxKind.spark:
          _paint
            ..style = PaintingStyle.fill
            ..color = Palette.wall.withValues(alpha: fade);
          final d = cell * 0.45 * ease;
          for (final o in [Offset(-d, -d), Offset(d, -d), Offset(-d, d), Offset(d, d)]) {
            canvas.drawCircle(center + o, cell * 0.1 * fade + 0.5, _paint);
          }
        case _FxKind.label:
          final tp = TextPainter(
            text: TextSpan(
              text: f.text,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: (cell * 0.75).roundToDouble(),
                color: Palette.ink.withValues(alpha: f.t < 0.6 ? 1 : fade / 0.4),
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          final p = _labelPos(center, tp.width / 2, ease);
          tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height));
          tp.dispose();
      }
    }
  }

  void _renderRetro(Canvas canvas) {
    final m = game.metrics;
    final cell = m.cell;
    for (final f in _fx) {
      final center = Offset(m.origin.dx + f.x * cell, m.origin.dy + f.y * cell);
      final fade = 1 - f.t;
      switch (f.kind) {
        case _FxKind.pop:
          _paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.14
            ..color = Palette.ink.withValues(alpha: fade);
          final side = cell * (0.6 + f.t * 0.9);
          canvas.drawRect(Rect.fromCenter(center: center, width: side, height: side), _paint);
        case _FxKind.ring:
          _paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.2
            ..color = Palette.ink.withValues(alpha: fade);
          for (final k in const [1.0, 1.8]) {
            final side = cell * (0.8 + f.t * 2.4 * k);
            canvas.drawRect(Rect.fromCenter(center: center, width: side, height: side), _paint);
          }
        case _FxKind.spark:
          _paint
            ..style = PaintingStyle.fill
            ..color = Palette.inkMid.withValues(alpha: fade);
          final d = cell * 0.35 * f.t;
          final u = cell * 0.18;
          for (final o in [Offset(-d, -d), Offset(d, -d), Offset(-d, d), Offset(d, d)]) {
            canvas.drawRect(Rect.fromCenter(center: center + o, width: u, height: u), _paint);
          }
        case _FxKind.label:
          if ((f.t > 0.7) && ((f.age * 12).floor().isEven)) continue;
          final tp = _text(cell * 0.55);
          final p = _labelPos(center, tp.getLineMetrics(f.text).width / 2, f.t);
          tp.render(canvas, f.text, Vector2(p.dx, p.dy), anchor: Anchor.bottomCenter);
      }
    }
  }
}
