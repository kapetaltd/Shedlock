import '../model/board_layout.dart';
import '../model/grid_pos.dart';
import '../rng/seeded_rng.dart';

typedef CellTest = bool Function(GridPos p);

/// Picks spawn cells from a seeded candidate sequence.
///
/// Each call consumes a fixed number of RNG draws whatever the board looks
/// like, so the n-th candidate is the same for every player on a given seed.
/// If the candidate is blocked, the first acceptable cell after it in
/// row-major order (wrapping) is used instead.
class Spawner {
  /// Draws two numbers (x, y) from [rng] and returns the cell to use, or null
  /// if no cell on the board is acceptable.
  static GridPos? pick(BoardLayout layout, SeededRng rng, CellTest acceptable) {
    final candidate = GridPos(
      rng.nextInt(layout.width),
      rng.nextInt(layout.height),
    );
    return scanFrom(layout, candidate, acceptable);
  }

  static GridPos? scanFrom(
    BoardLayout layout,
    GridPos start,
    CellTest acceptable,
  ) {
    final n = layout.cellCount;
    final first = layout.indexOf(start);
    for (var i = 0; i < n; i++) {
      final p = layout.posOf((first + i) % n);
      if (acceptable(p)) return p;
    }
    return null;
  }
}
