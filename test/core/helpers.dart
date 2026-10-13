import 'package:shedlock/core/core.dart';

const testConfig = GameConfig(obstacleClusters: 0);

/// Builds a hand-made board on top of a fresh game.
GameState board({
  GameConfig config = testConfig,
  required List<GridPos> snake,
  Direction heading = Direction.up,
  List<Food> foods = const [],
  Set<GridPos> obstacles = const {},
  List<ShedWall> walls = const [],
  int seed = 1,
}) {
  final base = GameEngine.newGame(config: config, seed: seed);
  return base.copyWith(
    snake: snake,
    heading: heading,
    foods: foods,
    shedWalls: walls,
    layout: BoardLayout(
      width: config.width,
      height: config.height,
      obstacles: obstacles,
    ),
  );
}

/// [n] cells starting at [head] and extending in [towardsTail].
List<GridPos> line(GridPos head, Direction towardsTail, int n) => [
      for (var i = 0; i < n; i++)
        GridPos(head.x + towardsTail.dx * i, head.y + towardsTail.dy * i),
    ];

Food food(int x, int y, {int id = 100, FoodKind kind = FoodKind.normal, int spawnTick = 0}) =>
    Food(id: id, pos: GridPos(x, y), kind: kind, spawnTick: spawnTick);

StepResult stepWith(GameState s, {Direction? turn, bool shed = false}) =>
    GameEngine.step(s, StepInput(turn: turn, shed: shed));

GameState run(GameState s, int ticks) {
  for (var i = 0; i < ticks; i++) {
    s = GameEngine.step(s).state;
  }
  return s;
}

/// A simple deterministic bot: heads for the nearest food, avoiding
/// immediate death when it can. Sheds every [shedEvery] ticks.
class Bot {
  Bot({this.shedEvery = 60});
  final int shedEvery;

  StepInput decide(GameState s) {
    final blocked = {
      ...s.snake.sublist(0, s.snake.length - 1),
      for (final w in s.shedWalls) w.pos,
    };
    bool safe(GridPos p) =>
        s.layout.inBounds(p) && !s.layout.isObstacle(p) && !blocked.contains(p);

    final target = s.foods.isEmpty
        ? s.head
        : (s.foods.toList()
              ..sort((a, b) => a.pos.manhattanTo(s.head).compareTo(b.pos.manhattanTo(s.head))))
            .first
            .pos;

    Direction? best;
    var bestDist = 1 << 30;
    for (final d in Direction.values) {
      if (d.isOppositeOf(s.heading)) continue;
      final n = s.head.step(d);
      if (!safe(n)) continue;
      final dist = n.manhattanTo(target);
      if (dist < bestDist) {
        bestDist = dist;
        best = d;
      }
    }
    return StepInput(
      turn: best,
      shed: shedEvery > 0 && s.tick > 0 && s.tick % shedEvery == 0,
    );
  }
}
