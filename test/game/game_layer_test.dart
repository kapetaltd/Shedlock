import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/core/core.dart';
import 'package:shedlock/game/shedlock_game.dart';
import 'package:shedlock/game/snake_interpolation.dart';
import 'package:shedlock/game/swipe.dart';

const cfg = GameConfig(obstacleClusters: 0);

RunSession session([int seed = 1]) =>
    RunSession(mode: GameMode.endless, seed: seed, config: cfg);

Future<ShedlockGame> loadedGame({RunSession? s}) async {
  final game = ShedlockGame(session: s ?? session());
  game.onGameResize(Vector2(400, 640));
  await game.onLoad();
  game.onGameResize(Vector2(400, 640));
  return game;
}

void main() {
  group('swipe', () {
    test('needs the threshold on the dominant axis', () {
      expect(swipeDirection(5, 3, 10), isNull);
      expect(swipeDirection(12, 3, 10), Direction.right);
      expect(swipeDirection(-12, 11, 10), Direction.left);
      expect(swipeDirection(4, -15, 10), Direction.up);
      expect(swipeDirection(4, 15, 10), Direction.down);
    });

    test('one continuous L-shaped drag yields two turns', () {
      final t = SwipeTracker(threshold: 10)..start();
      final out = <Direction>[];
      for (final d in [(4.0, 0.0), (4.0, 0.0), (4.0, 0.0), (0.0, 6.0), (0.0, 6.0)]) {
        final r = t.update(d.$1, d.$2);
        if (r != null) out.add(r);
      }
      expect(out, [Direction.right, Direction.down]);
    });
  });

  group('interpolation', () {
    test('segments slide between ticks', () {
      final prev = [const GridPos(5, 5), const GridPos(5, 6)];
      final cur = [const GridPos(5, 4), const GridPos(5, 5)];
      final pts = interpolateSnake(prev, cur, 0.5);
      expect(pts[0].y, 4.5);
      expect(pts[1].y, 5.5);
    });

    test('new segments and jumps (rewind) snap', () {
      final prev = [const GridPos(5, 5)];
      final cur = [const GridPos(9, 9), const GridPos(9, 10)];
      final pts = interpolateSnake(prev, cur, 0.3);
      expect((pts[0].x, pts[0].y), (9.0, 9.0));
      expect((pts[1].x, pts[1].y), (9.0, 10.0));
    });

    test('shed walls fade and flicker before expiring', () {
      const w = ShedWall(pos: GridPos(0, 0), createdAtMs: 0, expiresAtMs: 10000);
      expect(shedWallOpacity(w, 0), closeTo(1, 1e-9));
      expect(shedWallOpacity(w, 5000), lessThan(1));
      final late1 = shedWallOpacity(w, 9000);
      final late2 = shedWallOpacity(w, 9130);
      expect(late1, isNot(late2), reason: 'flickers in the last 2 s');
    });
  });

  group('ShedlockGame', () {
    test('waits for the first input, then ticks on a fixed step', () async {
      final game = await loadedGame();
      game.update(1.0);
      expect(game.session.state.tick, 0);
      expect(game.phase.value, PlayPhase.waiting);

      game.turn(Direction.left);
      expect(game.phase.value, PlayPhase.playing);
      // 0.18 s of frames at 60 fps → exactly one 180 ms tick.
      for (var i = 0; i < 11; i++) {
        game.update(1 / 60);
      }
      expect(game.session.state.tick, 1);
      expect(game.session.state.heading, Direction.left);
    });

    test('tap before starting starts without shedding', () async {
      final game = await loadedGame();
      game.shed();
      expect(game.phase.value, PlayPhase.playing);
      game.update(0.2);
      expect(game.session.state.sheds, 0);
    });

    test('death switches to over; free rewind counts down then resumes', () async {
      final game = await loadedGame();
      game.turn(Direction.left);
      while (game.phase.value == PlayPhase.playing) {
        game.update(0.05);
      }
      expect(game.phase.value, PlayPhase.over);
      expect(game.session.isOver, isTrue);

      expect(game.rewind(), isTrue);
      expect(game.phase.value, PlayPhase.countdown);
      expect(game.countdown.value, 3);
      final tickAtRewind = game.session.state.tick;
      game.update(0.5);
      expect(game.session.state.tick, tickAtRewind, reason: 'frozen during countdown');
      game.update(ShedlockGame.countdownSeconds);
      expect(game.phase.value, PlayPhase.playing);
    });

    test('pause stops time; resume counts down', () async {
      final game = await loadedGame();
      game.turn(Direction.left);
      game.update(0.2);
      game.pauseGame();
      final t = game.session.state.tick;
      game.update(2);
      expect(game.session.state.tick, t);
      game.resumeGame();
      expect(game.phase.value, PlayPhase.countdown);
    });

    test('board fits the screen in whole-pixel cells', () async {
      final game = await loadedGame();
      final m = game.metrics;
      expect(m.cell, 19, reason: "width-limited: (400 - 8) / 20");
      expect(m.origin.dx + m.cell * 20, lessThanOrEqualTo(400));
      expect(m.origin.dy + m.cell * 30, lessThanOrEqualTo(640));
    });

    test('restart begins a fresh run', () async {
      final game = await loadedGame();
      game.turn(Direction.left);
      game.update(1);
      game.restart(session(2));
      expect(game.phase.value, PlayPhase.waiting);
      expect(game.session.state.tick, 0);
      expect(game.hud.value.score, 0);
    });
  });
}
