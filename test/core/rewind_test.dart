import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/core/core.dart';

import 'helpers.dart';

/// Tall board, no obstacles: the snake runs straight up for ~6 s and dies.
const tallConfig = GameConfig(height: 60, obstacleClusters: 0);

/// Runs [session] with no input until it dies, recording every state.
Map<int, GameState> playToDeath(RunSession session) {
  final seen = <int, GameState>{session.state.simTimeMs: session.state};
  while (!session.isOver) {
    session.tick();
    seen[session.state.simTimeMs] = session.state;
  }
  return seen;
}

void main() {
  group('SnapshotBuffer', () {
    GameState at(int ms) =>
        GameEngine.newGame(config: testConfig, seed: 1).copyWith(simTimeMs: ms);

    test('keeps just over the window and nothing older', () {
      final b = SnapshotBuffer(windowMs: 3000);
      for (var t = 0; t <= 10000; t += 100) {
        b.push(at(t));
      }
      expect(b.oldest!.simTimeMs, 7000);
      expect(b.newest!.simTimeMs, 10000);
    });

    test('target is the latest snapshot at least 3 s before death', () {
      final b = SnapshotBuffer(windowMs: 3000);
      for (var t = 0; t <= 9900; t += 180) {
        b.push(at(t));
      }
      final target = b.targetFor(10080)!;
      expect(10080 - target.simTimeMs, greaterThanOrEqualTo(3000));
      expect(10080 - target.simTimeMs, lessThan(3000 + 180));
    });

    test('a young run rewinds to its first snapshot', () {
      final b = SnapshotBuffer(windowMs: 3000)..push(at(0))..push(at(180));
      expect(b.targetFor(360)!.simTimeMs, 0);
    });

    test('restore drops newer snapshots', () {
      final b = SnapshotBuffer(windowMs: 3000);
      for (var t = 0; t <= 6000; t += 200) {
        b.push(at(t));
      }
      final restored = b.restore(6200)!;
      expect(b.newest, same(restored));
    });
  });

  group('RunSession rewind', () {
    test('restores the exact state from 3 seconds before death', () {
      final session =
          RunSession(mode: GameMode.endless, seed: 11, config: tallConfig);
      final seen = playToDeath(session);
      final deathAt = session.state.simTimeMs;
      expect(deathAt, greaterThan(3000));
      expect(session.canFreeRewind, isTrue);

      expect(session.rewind(), isTrue);
      final s = session.state;
      expect(s.isDead, isFalse);
      expect(deathAt - s.simTimeMs, greaterThanOrEqualTo(3000));
      expect(deathAt - s.simTimeMs, lessThan(3000 + tallConfig.startTickMs));
      expect(s.sameAs(seen[s.simTimeMs]!), isTrue);
      expect(session.freeRewindsUsed, 1);
    });

    test('replaying after a rewind is deterministic (RNG is restored)', () {
      final session =
          RunSession(mode: GameMode.endless, seed: 12, config: tallConfig);
      playToDeath(session);
      final firstDeath = session.state;
      session.rewind();
      playToDeath(session);
      expect(session.state.sameAs(firstDeath), isTrue);
    });

    test('rewind brings back score, length and shed walls of that moment', () {
      final session = RunSession(mode: GameMode.endless, seed: 5);
      final bot = Bot(shedEvery: 25);
      final seen = <int, GameState>{};
      while (!session.isOver && session.state.tick < 5000) {
        final input = bot.decide(session.state);
        if (input.turn != null) session.turn(input.turn!);
        if (input.shed) session.requestShed();
        session.tick();
        seen[session.state.simTimeMs] = session.state;
      }
      if (!session.isOver) {
        // Force a death by steering into the edge.
        while (!session.isOver) {
          session.tick();
        }
      }
      session.rewind();
      final s = session.state;
      final original = seen[s.simTimeMs]!;
      expect(s.score, original.score);
      expect(s.snake, original.snake);
      expect(s.shedWalls, original.shedWalls);
    });

    test('1 free rewind, then up to 2 ad rewinds', () {
      final session =
          RunSession(mode: GameMode.endless, seed: 13, config: tallConfig);
      expect(session.canFreeRewind, isFalse, reason: 'not dead yet');
      expect(session.rewind(), isFalse);

      playToDeath(session);
      expect(session.canFreeRewind, isTrue);
      expect(session.canAdRewind, isFalse, reason: 'free one first');
      session.rewind();

      for (var i = 0; i < 2; i++) {
        playToDeath(session);
        expect(session.canFreeRewind, isFalse);
        expect(session.canAdRewind, isTrue);
        expect(session.rewind(), isTrue);
      }
      playToDeath(session);
      expect(session.canAdRewind, isFalse);
      expect(session.rewind(), isFalse);
      expect(session.freeRewindsUsed, 1);
      expect(session.adRewindsUsed, 2);
      expect(session.result().rewindsUsed, 3);
    });

    test('ranked daily: free rewind only, no ad rewinds or continues', () {
      final session = RunSession(
        mode: GameMode.daily,
        seed: 14,
        config: tallConfig,
        rules: RunRules.rankedDaily,
        ranked: true,
      );
      playToDeath(session);
      expect(session.canContinue, isFalse);
      session.rewind();
      playToDeath(session);
      expect(session.canAdRewind, isFalse);
      expect(session.canContinue, isFalse);
    });

    test('timeline is truncated to the restored moment', () {
      final session = RunSession(mode: GameMode.endless, seed: 3);
      final bot = Bot(shedEvery: 0);
      while (!session.isOver) {
        final input = bot.decide(session.state);
        if (input.turn != null) session.turn(input.turn!);
        session.tick();
        if (session.state.tick > 3000) break;
      }
      while (!session.isOver) {
        session.tick();
      }
      session.rewind();
      final r = session.result();
      expect(r.timeline.last.simTimeMs, lessThanOrEqualTo(session.state.simTimeMs));
      expect(r.timeline.last.score, session.state.score);
    });
  });

  group('continue', () {
    test('puts a 3-segment snake back with a clear path, keeping the score', () {
      final session =
          RunSession(mode: GameMode.endless, seed: 21, config: tallConfig);
      playToDeath(session);
      final dead = session.state;
      expect(session.canContinue, isTrue);
      expect(session.continueRun(), isTrue);
      final s = session.state;
      expect(s.isDead, isFalse);
      expect(s.length, tallConfig.shedKeep);
      expect(s.score, dead.score);
      expect(s.deathCause, isNull);
      for (var k = 1; k <= ContinueResolver.clearAhead; k++) {
        final p = GridPos(s.head.x + s.heading.dx * k, s.head.y + s.heading.dy * k);
        expect(s.layout.inBounds(p), isTrue);
        expect(s.layout.isObstacle(p), isFalse);
      }
      // Survives the next few ticks.
      for (var i = 0; i < ContinueResolver.clearAhead; i++) {
        session.tick();
        expect(session.isOver, isFalse);
      }
      expect(session.canContinue, isFalse, reason: 'once per run');
    });
  });
}
