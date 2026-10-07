import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/core/core.dart';

import 'helpers.dart';

void main() {
  final snake8 = line(const GridPos(5, 10), Direction.down, 8);

  test('shedding keeps the first 3 segments and turns the rest into walls', () {
    final s0 = board(snake: snake8);
    final r = stepWith(s0, shed: true);
    final s1 = r.state;
    final now = s0.tickMs;

    expect(s1.length, 3);
    // Shed happens before the move, so the kept 3 then step up by one.
    expect(s1.snake, line(const GridPos(5, 9), Direction.down, 3));
    expect(s1.shedWalls.map((w) => w.pos), snake8.sublist(3));
    for (final w in s1.shedWalls) {
      expect(w.createdAtMs, now);
      expect(w.expiresAtMs, now + testConfig.shedWallLifetimeMs);
    }
    expect(s1.sheds, 1);
    expect(s1.lastShedAtMs, now);
    expect(r.events.whereType<Shed>().single.wallCells, snake8.sublist(3));
  });

  test('shedding resets the multiplier', () {
    final s0 = board(snake: snake8);
    expect(s0.multiplierPercent, 150);
    expect(stepWith(s0, shed: true).state.multiplierPercent, 100);
  });

  test('cannot shed at 3 segments or fewer', () {
    final s0 = board(snake: line(const GridPos(5, 10), Direction.down, 3));
    final r = stepWith(s0, shed: true);
    expect(r.state.sheds, 0);
    expect(r.state.shedWalls, isEmpty);
    expect(r.events.whereType<ShedDenied>().single.reason,
        ShedDeniedReason.tooShort);
  });

  test('1 second cooldown between sheds', () {
    var s = board(snake: line(const GridPos(5, 20), Direction.down, 8));
    s = stepWith(s, shed: true).state;
    expect(s.sheds, 1);

    // Give it a long body again (to the side) so length isn't the limit.
    s = s.copyWith(snake: line(s.head, Direction.right, 8));

    final denied = stepWith(s, shed: true);
    expect(denied.events.whereType<ShedDenied>().single.reason,
        ShedDeniedReason.cooldown);
    expect(denied.state.sheds, 1);

    // Advance until the next tick lands a full cooldown after the shed.
    var t = denied.state;
    while (t.simTimeMs + t.tickMs - t.lastShedAtMs < testConfig.shedCooldownMs) {
      expect(stepWith(t, shed: true).state.sheds, 1);
      t = GameEngine.step(t).state;
    }
    final ok = stepWith(t, shed: true);
    expect(ok.state.sheds, 2);
    expect(ok.events.whereType<Shed>(), hasLength(1));
  });

  test('shed walls fade over their lifetime', () {
    const w = ShedWall(pos: GridPos(0, 0), createdAtMs: 1000, expiresAtMs: 11000);
    expect(w.remainingFraction(1000), 1.0);
    expect(w.remainingFraction(6000), closeTo(0.5, 1e-9));
    expect(w.remainingFraction(11000), 0.0);
    expect(w.remainingFraction(50000), 0.0);
    expect(w.isExpiredAt(10999), isFalse);
    expect(w.isExpiredAt(11000), isTrue);
  });

  test('shed walls disappear after 10 seconds of simulated time', () {
    // Snake runs left along row 28 after shedding, away from the walls.
    final snake = line(const GridPos(15, 28), Direction.right, 3) +
        [for (var y = 27; y > 20; y--) GridPos(17, y)];
    var s = board(snake: snake, heading: Direction.left);
    s = stepWith(s, shed: true).state;
    final expiresAt = s.shedWalls.first.expiresAtMs;
    expect(s.shedWalls, hasLength(7));

    // Use a slow fixed tick so the snake doesn't run out of board.
    s = s.copyWith(tickMs: 1000);
    while (s.simTimeMs + s.tickMs < expiresAt) {
      s = stepWith(s, turn: s.head.x <= 1 ? Direction.up : null).state;
      expect(s.shedWalls, hasLength(7));
    }
    final r = GameEngine.step(s);
    expect(r.state.shedWalls, isEmpty);
    expect(r.events.whereType<WallsExpired>().single.cells, hasLength(7));
  });

  test('running into a shed wall ends the run', () {
    final s0 = board(
      snake: line(const GridPos(5, 10), Direction.down, 3),
      walls: const [ShedWall(pos: GridPos(5, 9), createdAtMs: 0, expiresAtMs: 99999)],
    );
    expect(GameEngine.step(s0).state.deathCause, DeathCause.shedWall);
  });
}
