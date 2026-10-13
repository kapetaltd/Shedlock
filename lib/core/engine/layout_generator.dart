import '../model/board_layout.dart';
import '../model/game_config.dart';
import '../model/grid_pos.dart';
import '../rng/seeded_rng.dart';

/// Generates seeded obstacle layouts.
///
/// Clusters are small hole-free shapes that never touch the border or each
/// other (not even diagonally), so every free cell stays reachable.
class LayoutGenerator {
  static const List<List<GridPos>> shapes = [
    [GridPos(0, 0), GridPos(1, 0), GridPos(2, 0)], // I3 horizontal
    [GridPos(0, 0), GridPos(0, 1), GridPos(0, 2)], // I3 vertical
    [GridPos(0, 0), GridPos(1, 0), GridPos(2, 0), GridPos(3, 0)], // I4 h
    [GridPos(0, 0), GridPos(0, 1), GridPos(0, 2), GridPos(0, 3)], // I4 v
    [GridPos(0, 0), GridPos(1, 0), GridPos(0, 1), GridPos(1, 1)], // O
    [GridPos(0, 0), GridPos(0, 1), GridPos(0, 2), GridPos(1, 2)], // L
    [GridPos(1, 0), GridPos(1, 1), GridPos(1, 2), GridPos(0, 2)], // J
    [GridPos(0, 0), GridPos(1, 0), GridPos(2, 0), GridPos(0, 1)], // L rot
    [GridPos(0, 0), GridPos(1, 0), GridPos(2, 0), GridPos(2, 1)], // J rot
  ];

  /// Where the snake's head starts.
  static GridPos startHead(GameConfig c) => GridPos(c.width ~/ 2, c.height ~/ 2);

  /// Cells kept clear so the opening moves are always safe.
  static bool inSafeZone(GameConfig c, GridPos p) {
    final h = startHead(c);
    return (p.x - h.x).abs() <= 2 &&
        p.y >= h.y - 8 &&
        p.y <= h.y + c.startLength + 1;
  }

  static BoardLayout generate(GameConfig c, int seed) {
    final rng = SeededRng(seed);
    final obstacles = <GridPos>{};
    for (var cluster = 0; cluster < c.obstacleClusters; cluster++) {
      for (var attempt = 0; attempt < 200; attempt++) {
        final shape = shapes[rng.nextInt(shapes.length)];
        final ox = 1 + rng.nextInt(c.width - 2);
        final oy = 1 + rng.nextInt(c.height - 2);
        final cells = [for (final s in shape) GridPos(ox + s.x, oy + s.y)];
        if (cells.every((p) => _canPlace(c, p, obstacles))) {
          obstacles.addAll(cells);
          break;
        }
      }
    }
    return BoardLayout(width: c.width, height: c.height, obstacles: obstacles);
  }

  static bool _canPlace(GameConfig c, GridPos p, Set<GridPos> existing) {
    if (p.x < 1 || p.y < 1 || p.x > c.width - 2 || p.y > c.height - 2) {
      return false;
    }
    if (inSafeZone(c, p)) return false;
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        if (existing.contains(GridPos(p.x + dx, p.y + dy))) return false;
      }
    }
    return true;
  }
}
