import '../model/board_layout.dart';
import '../model/grid_pos.dart';
import '../rng/seeded_rng.dart';
import 'spawner.dart';

/// Movement and lock rules for runner food.
class RunnerAi {
  /// Cells a runner at [from] could step to. [blocked] must report snake
  /// segments, shed walls and other food; bounds and obstacles are checked
  /// here.
  static List<GridPos> legalMoves(
    BoardLayout layout,
    GridPos from,
    CellTest blocked,
  ) =>
      [
        for (final n in from.neighbours)
          if (layout.inBounds(n) && !layout.isObstacle(n) && !blocked(n)) n,
      ];

  /// A runner is locked when it has no legal move.
  static bool isLocked(BoardLayout layout, GridPos at, CellTest blocked) =>
      legalMoves(layout, at, blocked).isEmpty;

  /// Chooses the next cell. Always draws exactly two numbers from [rng] so the
  /// stream advances the same way whatever the board looks like.
  /// Returns null if there is no legal move.
  static GridPos? chooseMove({
    required BoardLayout layout,
    required GridPos from,
    required GridPos snakeHead,
    required CellTest blocked,
    required SeededRng rng,
    required int fleePercent,
  }) {
    final flee = rng.chance(fleePercent);
    final pickRoll = rng.nextUint32();
    final moves = legalMoves(layout, from, blocked);
    if (moves.isEmpty) return null;

    var options = moves;
    if (flee) {
      var best = -1;
      for (final m in moves) {
        final d = m.manhattanTo(snakeHead);
        if (d > best) best = d;
      }
      options = [for (final m in moves) if (m.manhattanTo(snakeHead) == best) m];
    }
    return options[pickRoll % options.length];
  }
}
