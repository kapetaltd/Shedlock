import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/core/core.dart';

import 'helpers.dart';

void main() {
  group('movement', () {
    test('new game: snake of startLength in the centre, heading up, one food',
        () {
      final s = GameEngine.newGame(config: testConfig, seed: 7);
      expect(s.snake, line(const GridPos(10, 15), Direction.down, 3));
      expect(s.heading, Direction.up);
      expect(s.foods, hasLength(1));
      expect(s.snake.contains(s.foods.single.pos), isFalse);
      expect(s.status, RunStatus.running);
    });

    test('moves one cell per tick and keeps its length', () {
      final s0 = board(snake: line(const GridPos(5, 10), Direction.down, 4));
      final s1 = GameEngine.step(s0).state;
      expect(s1.snake, line(const GridPos(5, 9), Direction.down, 4));
      expect(s1.tick, 1);
      expect(s1.simTimeMs, testConfig.startTickMs);
    });

    test('turns apply before moving', () {
      final s0 = board(snake: line(const GridPos(5, 10), Direction.down, 3));
      final s1 = stepWith(s0, turn: Direction.left).state;
      expect(s1.head, const GridPos(4, 10));
      expect(s1.heading, Direction.left);
    });

    test('engine ignores a reversing turn', () {
      final s0 = board(snake: line(const GridPos(5, 10), Direction.down, 3));
      final s1 = stepWith(s0, turn: Direction.down).state;
      expect(s1.isDead, isFalse);
      expect(s1.head, const GridPos(5, 9));
      expect(s1.heading, Direction.up);
    });

    test('a dead state does not change', () {
      final s0 = board(snake: line(const GridPos(0, 0), Direction.down, 3));
      final dead = GameEngine.step(s0).state;
      expect(dead.isDead, isTrue);
      final again = GameEngine.step(dead);
      expect(identical(again.state, dead), isTrue);
      expect(again.events, isEmpty);
    });
  });

  group('input buffer', () {
    test('rejects reversal and repeats of the current heading', () {
      final b = InputBuffer();
      expect(b.push(Direction.down, Direction.up), isFalse);
      expect(b.push(Direction.up, Direction.up), isFalse);
      expect(b.isEmpty, isTrue);
    });

    test('buffers one extra turn, validated against the queued one', () {
      final b = InputBuffer();
      expect(b.push(Direction.left, Direction.up), isTrue);
      expect(b.push(Direction.right, Direction.up), isFalse,
          reason: 'right reverses the queued left');
      expect(b.push(Direction.down, Direction.up), isTrue);
      expect(b.push(Direction.left, Direction.up), isFalse, reason: 'full');
      expect(b.pop(), Direction.left);
      expect(b.pop(), Direction.down);
      expect(b.pop(), isNull);
    });

    test('a fast U-turn (left then down within one tick) is safe', () {
      final session = RunSession(
        mode: GameMode.endless,
        seed: 3,
        config: testConfig,
      );
      expect(session.turn(Direction.left), isTrue);
      expect(session.turn(Direction.down), isTrue);
      session.tick();
      session.tick();
      expect(session.isOver, isFalse);
      expect(session.state.heading, Direction.down);
      expect(session.state.head, const GridPos(9, 16));
    });
  });

  group('collision', () {
    test('hitting the board edge ends the run', () {
      final s0 = board(
        snake: line(const GridPos(0, 5), Direction.right, 3),
        heading: Direction.left,
      );
      final r = GameEngine.step(s0);
      expect(r.state.isDead, isTrue);
      expect(r.state.deathCause, DeathCause.wall);
      expect(r.state.deathPos, const GridPos(-1, 5));
      expect(r.state.snake, s0.snake, reason: 'snake stays where it was');
      expect(r.events.whereType<Died>().single.cause, DeathCause.wall);
    });

    test('hitting an obstacle ends the run', () {
      final s0 = board(
        snake: line(const GridPos(5, 5), Direction.down, 3),
        obstacles: {const GridPos(5, 4)},
      );
      final s1 = GameEngine.step(s0).state;
      expect(s1.deathCause, DeathCause.obstacle);
    });

    test('hitting your own body ends the run', () {
      // Head at (5,5) heading left into (4,5), which is a body segment.
      final s0 = board(
        snake: const [
          GridPos(5, 5),
          GridPos(5, 6),
          GridPos(4, 6),
          GridPos(4, 5),
          GridPos(4, 4),
        ],
        heading: Direction.up,
      );
      final s1 = stepWith(s0, turn: Direction.left).state;
      expect(s1.deathCause, DeathCause.self);
    });

    test('moving into the cell the tail is leaving is allowed', () {
      // A 4-long snake in a 2x2 loop chases its own tail forever.
      var s = board(
        snake: const [
          GridPos(5, 5),
          GridPos(6, 5),
          GridPos(6, 6),
          GridPos(5, 6),
        ],
        heading: Direction.left,
      );
      final turns = [Direction.down, Direction.right, Direction.up, Direction.left];
      for (var i = 0; i < 12; i++) {
        s = stepWith(s, turn: turns[i % 4]).state;
        expect(s.isDead, isFalse, reason: 'tick $i');
      }
    });
  });

  group('eating and speed', () {
    test('eating grows by 1, scores, speeds up and respawns food', () {
      final s0 = board(
        snake: line(const GridPos(5, 10), Direction.down, 3),
        foods: [food(5, 9)],
      );
      final r = GameEngine.step(s0);
      final s1 = r.state;
      expect(s1.length, 4);
      expect(s1.head, const GridPos(5, 9));
      expect(s1.score, 10);
      expect(s1.foodEaten, 1);
      expect(s1.tickMs, testConfig.startTickMs - testConfig.tickMsDropPerFood);
      expect(r.events.whereType<FoodEaten>().single.points, 10);
      final spawned = r.events.whereType<FoodSpawned>().single.food;
      expect(s1.foods.single, spawned);
      expect(s1.snake.contains(spawned.pos), isFalse);
    });

    test('points scale with length: +0.1x per segment above start', () {
      final s0 = board(
        snake: line(const GridPos(5, 10), Direction.down, 8),
        foods: [food(5, 9)],
      );
      expect(s0.multiplierPercent, 150);
      final s1 = GameEngine.step(s0).state;
      expect(s1.score, 15);
    });

    test('tick interval never drops below the minimum', () {
      expect(testConfig.tickMsFor(0), testConfig.startTickMs);
      expect(testConfig.tickMsFor(10000), testConfig.minTickMs);
    });
  });
}
