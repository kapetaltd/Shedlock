import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/core/core.dart';

import 'helpers.dart';

/// The first [n] food candidates for [seed], on an empty board.
List<GridPos> candidateSequence(int seed, int n) {
  final layout = BoardLayout(width: 20, height: 30);
  final rng = SeededRng(deriveSeed(seed, 'food'));
  return [for (var i = 0; i < n; i++) Spawner.pick(layout, rng, (_) => true)!];
}

/// Plays a full bot run and returns every state.
List<GameState> botRun(RunSession session, {int maxTicks = 4000}) {
  final bot = Bot(shedEvery: 40);
  final states = <GameState>[session.state];
  while (!session.isOver && session.state.tick < maxTicks) {
    final input = bot.decide(session.state);
    if (input.turn != null) session.turn(input.turn!);
    if (input.shed) session.requestShed();
    session.tick();
    states.add(session.state);
  }
  return states;
}

void main() {
  final epoch = DateTime.utc(2026, 11, 1);

  group('SeededRng', () {
    test('matches the mulberry32 reference (JS Math.imul) output', () {
      // Reference values computed with the canonical JavaScript mulberry32.
      final r1 = SeededRng(1);
      expect([for (var i = 0; i < 5; i++) r1.nextUint32()],
          [2693262067, 11749833, 2265367787, 4213581821, 4159151403]);
      final r42 = SeededRng(42);
      expect([for (var i = 0; i < 5; i++) r42.nextUint32()],
          [2581720956, 1925393290, 3661312704, 2876485805, 750819978]);
      final rBig = SeededRng(0xDEADBEEF);
      expect([for (var i = 0; i < 5; i++) rBig.nextUint32()],
          [4043151706, 1147597007, 3315858022, 1538288752, 2042435954]);
    });

    test('nextInt stays in range and covers it', () {
      final r = SeededRng(99);
      final seen = <int>{};
      for (var i = 0; i < 2000; i++) {
        final v = r.nextInt(20);
        expect(v, inInclusiveRange(0, 19));
        seen.add(v);
      }
      expect(seen, hasLength(20));
    });

    test('state can be saved and resumed', () {
      final a = SeededRng(7)..nextUint32()..nextUint32();
      final b = SeededRng(a.state);
      expect(b.nextUint32(), a.nextUint32());
    });

    test('FNV-1a matches the reference', () {
      expect(fnv1a32(''), 2166136261);
      expect(fnv1a32('a'), 3826002220);
      expect(fnv1a32('shedlock-2026-10-07'), 606429645);
    });
  });

  group('daily seed', () {
    test('every moment of the same UTC day gives the same seed', () {
      final seeds = {
        dailySeed(DateTime.utc(2026, 10, 7, 0, 0, 0)),
        dailySeed(DateTime.utc(2026, 10, 7, 12, 30)),
        dailySeed(DateTime.utc(2026, 10, 7, 23, 59, 59, 999)),
        // Same instant expressed in local time.
        dailySeed(DateTime.utc(2026, 10, 7, 9).toLocal()),
      };
      expect(seeds, hasLength(1));
      expect(dailyKey(DateTime.utc(2026, 10, 7, 23, 59)), '2026-10-07');
    });

    test('different days give different seeds', () {
      final seeds = {
        for (var d = 0; d < 365; d++)
          dailySeed(DateTime.utc(2026, 1, 1).add(Duration(days: d))),
      };
      expect(seeds, hasLength(365));
    });

    test('daily number counts UTC days from the epoch', () {
      expect(dailyNumber(DateTime.utc(2026, 11, 1, 0, 0, 1), epoch), 1);
      expect(dailyNumber(DateTime.utc(2026, 11, 1, 23, 59), epoch), 1);
      expect(dailyNumber(DateTime.utc(2026, 11, 2), epoch), 2);
      expect(dailyNumber(DateTime.utc(2027, 11, 1), epoch), 366);
    });
  });

  group('same date → identical game', () {
    final date = DateTime.utc(2026, 10, 7, 8);

    test('same food spawn sequence', () {
      final seed = dailySeed(date);
      final a = candidateSequence(seed, 200);
      final b = candidateSequence(dailySeed(DateTime.utc(2026, 10, 7, 22)), 200);
      expect(a, b);
      expect(candidateSequence(dailySeed(DateTime.utc(2026, 10, 8)), 200),
          isNot(a));
    });

    test('same layout, start state and runner decisions', () {
      final a = RunSession.daily(now: date, epoch: epoch, ranked: true);
      final b = RunSession.daily(
          now: DateTime.utc(2026, 10, 7, 23), epoch: epoch, ranked: true);
      expect(a.state.layout.obstacles, b.state.layout.obstacles);
      expect(a.state.layout.obstacles, isNotEmpty);
      expect(a.state.sameAs(b.state), isTrue);
      expect(a.dailyNumber, b.dailyNumber);

      final other = RunSession.daily(
          now: DateTime.utc(2026, 10, 8), epoch: epoch, ranked: true);
      expect(other.state.sameAs(a.state), isFalse);
    });

    test('same inputs produce the same run, tick for tick', () {
      final a = botRun(RunSession.daily(now: date, epoch: epoch, ranked: true));
      final b = botRun(RunSession.daily(now: date, epoch: epoch, ranked: true));
      expect(a.length, b.length);
      expect(a.length, greaterThan(50), reason: 'bot should survive a while');
      for (var i = 0; i < a.length; i++) {
        expect(a[i].sameAs(b[i]), isTrue, reason: 'diverged at tick $i');
      }
      // The run should have exercised the interesting systems.
      expect(a.last.foodEaten, greaterThan(3));
      expect(a.last.sheds, greaterThan(0));
    });

    test('the n-th food spawned is the same for players who play differently',
        () {
      // Two different play styles on the same day: the food positions differ
      // only where a candidate was blocked, so on a mostly-empty board most
      // of the first spawns match.
      List<GridPos> spawns(int shedEvery) {
        final s = RunSession.daily(now: date, epoch: epoch, ranked: true);
        final bot = Bot(shedEvery: shedEvery);
        final out = <GridPos>[s.state.foods.first.pos];
        while (!s.isOver && out.length < 10 && s.state.tick < 5000) {
          final input = bot.decide(s.state);
          if (input.turn != null) s.turn(input.turn!);
          if (input.shed) s.requestShed();
          for (final e in s.tick()) {
            if (e is FoodSpawned && e.food.kind == FoodKind.normal) {
              out.add(e.food.pos);
            }
          }
        }
        return out;
      }

      final a = spawns(0);
      final b = spawns(15);
      final n = a.length < b.length ? a.length : b.length;
      expect(n, greaterThan(3));
      var same = 0;
      for (var i = 0; i < n; i++) {
        if (a[i] == b[i]) same++;
      }
      expect(same / n, greaterThanOrEqualTo(0.7));
    });
  });
}
