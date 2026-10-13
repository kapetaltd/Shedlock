import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/core/core.dart';

import 'helpers.dart';

void main() {
  final layout = BoardLayout(width: 20, height: 30);

  group('lock detection', () {
    test('a runner in a corner with both exits blocked is locked', () {
      final blocked = {const GridPos(1, 0), const GridPos(0, 1)};
      expect(RunnerAi.isLocked(layout, const GridPos(0, 0), blocked.contains),
          isTrue);
    });

    test('one free exit means not locked', () {
      final blocked = {const GridPos(1, 0)};
      expect(RunnerAi.isLocked(layout, const GridPos(0, 0), blocked.contains),
          isFalse);
    });

    test('obstacles count as blockers', () {
      final l = BoardLayout(
        width: 20,
        height: 30,
        obstacles: {
          const GridPos(4, 5),
          const GridPos(6, 5),
          const GridPos(5, 4),
          const GridPos(5, 6),
        },
      );
      expect(RunnerAi.isLocked(l, const GridPos(5, 5), (_) => false), isTrue);
    });

    test('legal moves exclude bounds, obstacles and blocked cells', () {
      final moves = RunnerAi.legalMoves(
        layout,
        const GridPos(0, 5),
        {const GridPos(0, 4)}.contains,
      );
      expect(moves, unorderedEquals([const GridPos(0, 6), const GridPos(1, 5)]));
    });
  });

  group('runners in the engine', () {
    test('trapping a runner with snake + shed wall locks it for a bonus', () {
      // Runner in the top-left corner, wall to its right, snake head arrives
      // below it.
      final s0 = board(
        snake: line(const GridPos(0, 2), Direction.down, 3),
        foods: [food(0, 0, id: 1, kind: FoodKind.runner), food(10, 20, id: 2)],
        walls: const [
          ShedWall(pos: GridPos(1, 0), createdAtMs: 0, expiresAtMs: 99999),
        ],
      );
      final r = GameEngine.step(s0);
      expect(r.state.head, const GridPos(0, 1));
      final lock = r.events.whereType<RunnerLocked>().single;
      expect(lock.food.id, 1);
      expect(lock.bonus, testConfig.lockBonus);
      expect(r.state.locks, 1);
      expect(r.state.score, testConfig.lockBonus);
      expect(r.state.foods.map((f) => f.id), [2]);
    });

    test('runners move only every N ticks, to adjacent legal cells', () {
      var s = board(
        snake: line(const GridPos(0, 27), Direction.down, 3),
        foods: [food(10, 5, id: 1, kind: FoodKind.runner, spawnTick: 0)],
        obstacles: {const GridPos(10, 4)},
      );
      final n = testConfig.runnerMoveEveryTicks;
      var lastPos = const GridPos(10, 5);
      for (var t = 1; t <= n * 4; t++) {
        final r = GameEngine.step(s);
        s = r.state;
        final runner = s.foods.single;
        final moved = r.events.whereType<RunnerMoved>().toList();
        if (t % n == 0) {
          expect(moved, hasLength(1), reason: 'tick $t');
          expect(runner.pos.manhattanTo(lastPos), 1);
          expect(s.layout.inBounds(runner.pos), isTrue);
          expect(s.layout.isObstacle(runner.pos), isFalse);
          expect(s.snake.contains(runner.pos), isFalse);
        } else {
          expect(moved, isEmpty, reason: 'tick $t');
          expect(runner.pos, lastPos);
        }
        lastPos = runner.pos;
      }
    });

    test('a fleeing runner picks a move furthest from the head', () {
      for (var seed = 0; seed < 50; seed++) {
        final to = RunnerAi.chooseMove(
          layout: layout,
          from: const GridPos(10, 10),
          snakeHead: const GridPos(10, 12),
          blocked: (_) => false,
          rng: SeededRng(seed),
          fleePercent: 100,
        )!;
        expect(to, isNot(const GridPos(10, 11)));
        expect(to.manhattanTo(const GridPos(10, 12)), 3);
      }
    });

    test('chooseMove always consumes two draws', () {
      final a = SeededRng(9);
      final b = SeededRng(9);
      RunnerAi.chooseMove(
        layout: layout,
        from: const GridPos(0, 0),
        snakeHead: const GridPos(5, 5),
        blocked: (_) => true, // no legal moves at all
        rng: a,
        fleePercent: 50,
      );
      b
        ..nextUint32()
        ..nextUint32();
      expect(a.state, b.state);
    });

    test('eating a runner scores like food and does not respawn normal food',
        () {
      final s0 = board(
        snake: line(const GridPos(5, 10), Direction.down, 3),
        foods: [food(5, 9, id: 1, kind: FoodKind.runner, spawnTick: 0), food(15, 20, id: 2)],
      );
      final r = GameEngine.step(s0);
      expect(r.state.score, 10);
      expect(r.state.length, 4);
      expect(r.state.foods.map((f) => f.id), [2]);
      expect(r.events.whereType<FoodSpawned>(), isEmpty);
    });

    test('runners spawn in open space, away from the head', () {
      const cfg = GameConfig(
        obstacleClusters: 0,
        runnerSpawnPercent: 100,
        runnerMinNormalFood: 0,
      );
      final s0 = board(
        config: cfg,
        snake: line(const GridPos(5, 10), Direction.down, 3),
        foods: [food(5, 9)],
      );
      final r = GameEngine.step(s0);
      final runner = r.state.foods.singleWhere((f) => f.isRunner);
      expect(runner.pos.manhattanTo(r.state.head), greaterThan(2));
      final occupied = {...r.state.snake, ...r.state.foods.map((f) => f.pos)};
      final freeNeighbours = runner.pos.neighbours
          .where((p) => r.state.layout.inBounds(p) && !occupied.contains(p));
      expect(freeNeighbours.length, greaterThanOrEqualTo(2));
    });

    test('only one runner at a time', () {
      const cfg = GameConfig(
        obstacleClusters: 0,
        runnerSpawnPercent: 100,
        runnerMinNormalFood: 0,
      );
      final s0 = board(
        config: cfg,
        snake: line(const GridPos(5, 10), Direction.down, 3),
        foods: [food(5, 9, id: 1), food(15, 25, id: 2, kind: FoodKind.runner)],
      );
      final s1 = GameEngine.step(s0).state;
      expect(s1.foods.where((f) => f.isRunner), hasLength(1));
    });
  });
}
