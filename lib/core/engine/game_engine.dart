import '../model/direction.dart';
import '../model/food.dart';
import '../model/game_config.dart';
import '../model/game_event.dart';
import '../model/game_state.dart';
import '../model/grid_pos.dart';
import '../model/shed_wall.dart';
import '../rng/seeded_rng.dart';
import '../rng/seeds.dart';
import 'layout_generator.dart';
import 'runner_ai.dart';
import 'spawner.dart';

/// Player input applied at the start of a tick.
class StepInput {
  const StepInput({this.turn, this.shed = false});

  final Direction? turn;
  final bool shed;

  static const none = StepInput();
}

class StepResult {
  const StepResult(this.state, this.events);
  final GameState state;
  final List<GameEvent> events;
}

/// The whole game simulation: `newGame` and `step` are pure functions of
/// their inputs.
///
/// Order of a tick:
///   1. advance simulated time, expire shed walls
///   2. shed (if requested)
///   3. turn (if requested and legal)
///   4. move head, check collisions
///   5. eat and spawn
///   6. move runners
///   7. detect locked runners
class GameEngine {
  static GameState newGame({required GameConfig config, required int seed}) {
    final layout = LayoutGenerator.generate(config, deriveSeed(seed, 'layout'));
    final head = LayoutGenerator.startHead(config);
    final snake = [
      for (var i = 0; i < config.startLength; i++) GridPos(head.x, head.y + i),
    ];

    final foodRng = SeededRng(deriveSeed(seed, 'food'));
    final state = GameState(
      config: config,
      layout: layout,
      tick: 0,
      simTimeMs: 0,
      tickMs: config.startTickMs,
      status: RunStatus.running,
      snake: snake,
      heading: Direction.up,
      foods: const [],
      shedWalls: const [],
      score: 0,
      foodEaten: 0,
      sheds: 0,
      locks: 0,
      lastShedAtMs: -config.shedCooldownMs,
      nextFoodId: 0,
      normalFoodSpawned: 0,
      foodRng: foodRng.state,
      runnerSpawnRng: deriveSeed(seed, 'runner-spawn'),
      runnerMoveRng: deriveSeed(seed, 'runner-move'),
    );
    final spawned = _spawnNormalFood(state, foodRng, tick: 0);
    return spawned.copyWith(foodRng: foodRng.state);
  }

  static StepResult step(GameState s, [StepInput input = StepInput.none]) {
    if (s.isDead) return StepResult(s, const []);
    final c = s.config;
    final events = <GameEvent>[];
    final tick = s.tick + 1;
    final now = s.simTimeMs + s.tickMs;

    // 1. Expire walls.
    var walls = <ShedWall>[];
    final expired = <GridPos>[];
    for (final w in s.shedWalls) {
      if (w.isExpiredAt(now)) {
        expired.add(w.pos);
      } else {
        walls.add(w);
      }
    }
    if (expired.isNotEmpty) events.add(WallsExpired(expired));

    // 2. Shed.
    var snake = s.snake;
    var sheds = s.sheds;
    var lastShedAtMs = s.lastShedAtMs;
    if (input.shed) {
      if (snake.length <= c.shedKeep) {
        events.add(const ShedDenied(ShedDeniedReason.tooShort));
      } else if (now - lastShedAtMs < c.shedCooldownMs) {
        events.add(const ShedDenied(ShedDeniedReason.cooldown));
      } else {
        final dropped = snake.sublist(c.shedKeep);
        walls = [
          ...walls,
          for (final p in dropped)
            ShedWall(
              pos: p,
              createdAtMs: now,
              expiresAtMs: now + c.shedWallLifetimeMs,
            ),
        ];
        snake = snake.sublist(0, c.shedKeep);
        sheds++;
        lastShedAtMs = now;
        events.add(Shed(dropped));
      }
    }

    // 3. Turn.
    var heading = s.heading;
    final turn = input.turn;
    if (turn != null && !turn.isOppositeOf(heading)) heading = turn;

    // 4. Move and collide.
    final newHead = snake.first.step(heading);
    final eaten = s.foodAt(newHead);
    final growing = eaten != null;
    final wallCells = {for (final w in walls) w.pos};

    DeathCause? cause;
    if (!s.layout.inBounds(newHead)) {
      cause = DeathCause.wall;
    } else if (s.layout.isObstacle(newHead)) {
      cause = DeathCause.obstacle;
    } else if (wallCells.contains(newHead)) {
      cause = DeathCause.shedWall;
    } else {
      // The tail moves out of the way this tick unless we are growing.
      final bodyEnd = growing ? snake.length : snake.length - 1;
      for (var i = 0; i < bodyEnd; i++) {
        if (snake[i] == newHead) {
          cause = DeathCause.self;
          break;
        }
      }
    }

    if (cause != null) {
      events.add(Died(cause, newHead));
      return StepResult(
        s.copyWith(
          tick: tick,
          simTimeMs: now,
          status: RunStatus.dead,
          snake: snake,
          heading: heading,
          shedWalls: walls,
          sheds: sheds,
          lastShedAtMs: lastShedAtMs,
          deathCause: cause,
          deathPos: newHead,
        ),
        events,
      );
    }

    final newSnake = [
      newHead,
      ...(growing ? snake : snake.sublist(0, snake.length - 1)),
    ];

    var next = s.copyWith(
      tick: tick,
      simTimeMs: now,
      snake: newSnake,
      heading: heading,
      shedWalls: walls,
      sheds: sheds,
      lastShedAtMs: lastShedAtMs,
    );

    // 5. Eat and spawn.
    if (eaten != null) {
      final points = c.foodPoints(snake.length);
      final foodEaten = next.foodEaten + 1;
      next = next.copyWith(
        foods: [for (final f in next.foods) if (f.id != eaten.id) f],
        score: next.score + points,
        foodEaten: foodEaten,
        tickMs: c.tickMsFor(foodEaten),
      );
      events.add(FoodEaten(eaten, points));

      if (eaten.kind == FoodKind.normal) {
        final foodRng = SeededRng(next.foodRng);
        next = _spawnNormalFood(next, foodRng, tick: tick, events: events)
            .copyWith(foodRng: foodRng.state);
        next = _maybeSpawnRunner(next, tick: tick, events: events);
      }
    }

    // 6. Move runners.
    next = _moveRunners(next, tick, events);

    // 7. Locks.
    next = _resolveLocks(next, events);

    return StepResult(next, events);
  }

  // ---------------------------------------------------------------------------

  /// Cells nothing may be spawned on or moved into (besides bounds/obstacles).
  static Set<GridPos> _occupied(GameState s) => {
        ...s.snake,
        for (final w in s.shedWalls) w.pos,
        for (final f in s.foods) f.pos,
      };

  static GameState _spawnNormalFood(
    GameState s,
    SeededRng rng, {
    required int tick,
    List<GameEvent>? events,
  }) {
    final occupied = _occupied(s);
    final pos = Spawner.pick(
      s.layout,
      rng,
      (p) => !s.layout.isObstacle(p) && !occupied.contains(p),
    );
    final spawnedCount = s.normalFoodSpawned + 1;
    if (pos == null) return s.copyWith(normalFoodSpawned: spawnedCount);
    final food = Food(
      id: s.nextFoodId,
      pos: pos,
      kind: FoodKind.normal,
      spawnTick: tick,
    );
    events?.add(FoodSpawned(food));
    return s.copyWith(
      foods: [...s.foods, food],
      nextFoodId: s.nextFoodId + 1,
      normalFoodSpawned: spawnedCount,
    );
  }

  /// Called once per normal food eaten. Always draws roll + x + y from the
  /// runner-spawn stream so the k-th decision is the same for every player.
  static GameState _maybeSpawnRunner(
    GameState s, {
    required int tick,
    required List<GameEvent> events,
  }) {
    final c = s.config;
    final rng = SeededRng(s.runnerSpawnRng);
    final wantsRunner = rng.chance(c.runnerSpawnPercent);
    final candidate = GridPos(
      rng.nextInt(s.layout.width),
      rng.nextInt(s.layout.height),
    );
    var next = s.copyWith(runnerSpawnRng: rng.state);

    final hasRunner = s.foods.any((f) => f.isRunner);
    if (!wantsRunner || hasRunner || s.normalFoodSpawned < c.runnerMinNormalFood) {
      return next;
    }

    final occupied = _occupied(s);
    bool free(GridPos p) =>
        s.layout.inBounds(p) && !s.layout.isObstacle(p) && !occupied.contains(p);
    // Never spawn a runner that is already (nearly) trapped, or right next to
    // the head.
    final pos = Spawner.scanFrom(
      s.layout,
      candidate,
      (p) =>
          free(p) &&
          p.manhattanTo(s.head) > 2 &&
          p.neighbours.where(free).length >= 2,
    );
    if (pos == null) return next;
    final runner = Food(
      id: s.nextFoodId,
      pos: pos,
      kind: FoodKind.runner,
      spawnTick: tick,
    );
    events.add(FoodSpawned(runner));
    return next.copyWith(
      foods: [...next.foods, runner],
      nextFoodId: next.nextFoodId + 1,
    );
  }

  static GameState _moveRunners(GameState s, int tick, List<GameEvent> events) {
    final every = s.config.runnerMoveEveryTicks;
    final due = s.foods.any(
      (f) => f.isRunner && tick > f.spawnTick && (tick - f.spawnTick) % every == 0,
    );
    if (!due) return s;

    final rng = SeededRng(s.runnerMoveRng);
    final foods = [...s.foods];
    final blockedBase = {
      ...s.snake,
      for (final w in s.shedWalls) w.pos,
    };
    for (var i = 0; i < foods.length; i++) {
      final f = foods[i];
      if (!f.isRunner || tick <= f.spawnTick || (tick - f.spawnTick) % every != 0) {
        continue;
      }
      final otherFood = {
        for (var j = 0; j < foods.length; j++)
          if (j != i) foods[j].pos,
      };
      final to = RunnerAi.chooseMove(
        layout: s.layout,
        from: f.pos,
        snakeHead: s.head,
        blocked: (p) => blockedBase.contains(p) || otherFood.contains(p),
        rng: rng,
        fleePercent: s.config.runnerFleePercent,
      );
      if (to != null) {
        foods[i] = f.movedTo(to);
        events.add(RunnerMoved(f.id, f.pos, to));
      }
    }
    return s.copyWith(foods: foods, runnerMoveRng: rng.state);
  }

  static GameState _resolveLocks(GameState s, List<GameEvent> events) {
    if (!s.foods.any((f) => f.isRunner)) return s;
    final blockedBase = {
      ...s.snake,
      for (final w in s.shedWalls) w.pos,
    };
    final kept = <Food>[];
    var score = s.score;
    var locks = s.locks;
    for (final f in s.foods) {
      if (f.isRunner) {
        final locked = RunnerAi.isLocked(
          s.layout,
          f.pos,
          (p) =>
              blockedBase.contains(p) ||
              s.foods.any((o) => o.id != f.id && o.pos == p),
        );
        if (locked) {
          score += s.config.lockBonus;
          locks++;
          events.add(RunnerLocked(f, s.config.lockBonus));
          continue;
        }
      }
      kept.add(f);
    }
    if (locks == s.locks) return s;
    return s.copyWith(foods: kept, score: score, locks: locks);
  }
}
