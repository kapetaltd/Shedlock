import '../model/direction.dart';
import '../model/game_state.dart';
import '../model/grid_pos.dart';

/// Finds a safe place to put the snake back after a "Continue".
///
/// The snake is cut to [GameConfig.shedKeep] segments and placed in a straight
/// line at the free spot nearest to where it died, facing a clear run of
/// [clearAhead] cells. Score, timers and food are untouched.
class ContinueResolver {
  static const int clearAhead = 4;

  static GameState? resolve(GameState s) {
    final keep = s.config.shedKeep;
    final layout = s.layout;
    final walls = {for (final w in s.shedWalls) w.pos};
    final foods = {for (final f in s.foods) f.pos};
    bool free(GridPos p) =>
        layout.inBounds(p) && !layout.isObstacle(p) && !walls.contains(p);

    final origin = s.snake.first;
    final cells = [
      for (var i = 0; i < layout.cellCount; i++) layout.posOf(i),
    ]..sort((a, b) {
        final d = a.manhattanTo(origin).compareTo(b.manhattanTo(origin));
        return d != 0 ? d : layout.indexOf(a).compareTo(layout.indexOf(b));
      });

    for (final head in cells) {
      for (final dir in Direction.values) {
        final body = [
          for (var i = 0; i < keep; i++)
            GridPos(head.x - dir.dx * i, head.y - dir.dy * i),
        ];
        if (!body.every((p) => free(p) && !foods.contains(p))) continue;
        var clear = true;
        for (var k = 1; k <= clearAhead; k++) {
          if (!free(GridPos(head.x + dir.dx * k, head.y + dir.dy * k))) {
            clear = false;
            break;
          }
        }
        if (!clear) continue;
        return s.copyWith(
          status: RunStatus.running,
          snake: body,
          heading: dir,
          clearDeath: true,
        );
      }
    }
    return null;
  }
}
