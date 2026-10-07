import '../core/core.dart';

/// A cell position in fractional grid units, for smooth rendering.
class CellPoint {
  const CellPoint(this.x, this.y);
  final double x;
  final double y;
}

/// Where each snake segment should be drawn at [alpha] (0..1) between the
/// previous tick's state and the current one.
///
/// Segment i slides from previous segment i to current segment i. Segments
/// that did not exist before (growth) or that jumped more than one cell
/// (rewind, continue) are drawn at their current cell.
List<CellPoint> interpolateSnake(
  List<GridPos> previous,
  List<GridPos> current,
  double alpha,
) {
  final a = alpha.clamp(0.0, 1.0);
  return [
    for (var i = 0; i < current.length; i++)
      _lerp(i < previous.length ? previous[i] : current[i], current[i], a),
  ];
}

CellPoint _lerp(GridPos from, GridPos to, double a) {
  if (from.manhattanTo(to) > 1) return CellPoint(to.x.toDouble(), to.y.toDouble());
  return CellPoint(from.x + (to.x - from.x) * a, from.y + (to.y - from.y) * a);
}

/// Opacity of a shed wall: fades with remaining lifetime and flickers in the
/// last [flickerMs] so players see it is about to vanish.
double shedWallOpacity(ShedWall w, double nowMs, {double flickerMs = 2000}) {
  final total = (w.expiresAtMs - w.createdAtMs).toDouble();
  if (total <= 0) return 0;
  final remaining = (w.expiresAtMs - nowMs).clamp(0.0, total);
  final base = 0.35 + 0.65 * (remaining / total);
  if (remaining < flickerMs) {
    // Faster flicker as it gets closer to expiry.
    final phase = (remaining / 120).floor();
    return phase.isEven ? base : base * 0.35;
  }
  return base;
}
