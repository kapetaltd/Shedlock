import 'board_layout.dart';
import 'direction.dart';
import 'food.dart';
import 'game_config.dart';
import 'game_event.dart';
import 'grid_pos.dart';
import 'shed_wall.dart';

enum RunStatus { running, dead }

/// A complete, immutable snapshot of a run at one tick.
///
/// Everything needed to continue the simulation deterministically is in here,
/// including RNG states, so a snapshot can be restored for a rewind.
/// [config] and [layout] never change during a run and are shared, not copied.
class GameState {
  GameState({
    required this.config,
    required this.layout,
    required this.tick,
    required this.simTimeMs,
    required this.tickMs,
    required this.status,
    required List<GridPos> snake,
    required this.heading,
    required List<Food> foods,
    required List<ShedWall> shedWalls,
    required this.score,
    required this.foodEaten,
    required this.sheds,
    required this.locks,
    required this.lastShedAtMs,
    required this.nextFoodId,
    required this.normalFoodSpawned,
    required this.foodRng,
    required this.runnerSpawnRng,
    required this.runnerMoveRng,
    this.deathCause,
    this.deathPos,
  })  : snake = List.unmodifiable(snake),
        foods = List.unmodifiable(foods),
        shedWalls = List.unmodifiable(shedWalls);

  final GameConfig config;
  final BoardLayout layout;

  /// Number of ticks simulated so far.
  final int tick;

  /// Simulated time: the sum of all tick intervals so far.
  final int simTimeMs;

  /// Interval of the next tick.
  final int tickMs;

  final RunStatus status;

  /// Head first.
  final List<GridPos> snake;
  final Direction heading;
  final List<Food> foods;
  final List<ShedWall> shedWalls;

  final int score;
  final int foodEaten;
  final int sheds;
  final int locks;
  final int lastShedAtMs;

  final int nextFoodId;

  /// How many normal foods have been spawned. Indexes the daily sequence.
  final int normalFoodSpawned;

  /// RNG states for independent streams (see `SeededRng`).
  final int foodRng;
  final int runnerSpawnRng;
  final int runnerMoveRng;

  final DeathCause? deathCause;
  final GridPos? deathPos;

  bool get isDead => status == RunStatus.dead;
  GridPos get head => snake.first;
  int get length => snake.length;
  int get multiplierPercent => config.multiplierPercent(length);

  bool get canShedNow =>
      length > config.shedKeep &&
      simTimeMs - lastShedAtMs >= config.shedCooldownMs;

  Food? foodAt(GridPos p) {
    for (final f in foods) {
      if (f.pos == p) return f;
    }
    return null;
  }

  bool isShedWall(GridPos p) => shedWalls.any((w) => w.pos == p);

  GameState copyWith({
    BoardLayout? layout,
    int? tick,
    int? simTimeMs,
    int? tickMs,
    RunStatus? status,
    List<GridPos>? snake,
    Direction? heading,
    List<Food>? foods,
    List<ShedWall>? shedWalls,
    int? score,
    int? foodEaten,
    int? sheds,
    int? locks,
    int? lastShedAtMs,
    int? nextFoodId,
    int? normalFoodSpawned,
    int? foodRng,
    int? runnerSpawnRng,
    int? runnerMoveRng,
    DeathCause? deathCause,
    GridPos? deathPos,
    bool clearDeath = false,
  }) =>
      GameState(
        config: config,
        layout: layout ?? this.layout,
        tick: tick ?? this.tick,
        simTimeMs: simTimeMs ?? this.simTimeMs,
        tickMs: tickMs ?? this.tickMs,
        status: status ?? this.status,
        snake: snake ?? this.snake,
        heading: heading ?? this.heading,
        foods: foods ?? this.foods,
        shedWalls: shedWalls ?? this.shedWalls,
        score: score ?? this.score,
        foodEaten: foodEaten ?? this.foodEaten,
        sheds: sheds ?? this.sheds,
        locks: locks ?? this.locks,
        lastShedAtMs: lastShedAtMs ?? this.lastShedAtMs,
        nextFoodId: nextFoodId ?? this.nextFoodId,
        normalFoodSpawned: normalFoodSpawned ?? this.normalFoodSpawned,
        foodRng: foodRng ?? this.foodRng,
        runnerSpawnRng: runnerSpawnRng ?? this.runnerSpawnRng,
        runnerMoveRng: runnerMoveRng ?? this.runnerMoveRng,
        deathCause: clearDeath ? null : (deathCause ?? this.deathCause),
        deathPos: clearDeath ? null : (deathPos ?? this.deathPos),
      );

  /// Structural equality of everything that affects the simulation.
  /// Used by determinism tests.
  bool sameAs(GameState o) =>
      tick == o.tick &&
      simTimeMs == o.simTimeMs &&
      tickMs == o.tickMs &&
      status == o.status &&
      heading == o.heading &&
      score == o.score &&
      foodEaten == o.foodEaten &&
      sheds == o.sheds &&
      locks == o.locks &&
      lastShedAtMs == o.lastShedAtMs &&
      nextFoodId == o.nextFoodId &&
      normalFoodSpawned == o.normalFoodSpawned &&
      foodRng == o.foodRng &&
      runnerSpawnRng == o.runnerSpawnRng &&
      runnerMoveRng == o.runnerMoveRng &&
      _listEq(snake, o.snake) &&
      _listEq(foods, o.foods) &&
      _listEq(shedWalls, o.shedWalls) &&
      layout.obstacles.length == o.layout.obstacles.length &&
      layout.obstacles.containsAll(o.layout.obstacles);

  static bool _listEq<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
