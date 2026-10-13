import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/core/core.dart';

void main() {
  group('layout generator', () {
    bool allFreeConnected(BoardLayout l) {
      final free = <GridPos>{
        for (var i = 0; i < l.cellCount; i++)
          if (!l.isObstacle(l.posOf(i))) l.posOf(i),
      };
      final start = free.first;
      final seen = {start};
      final queue = [start];
      while (queue.isNotEmpty) {
        final p = queue.removeLast();
        for (final n in p.neighbours) {
          if (free.contains(n) && seen.add(n)) queue.add(n);
        }
      }
      return seen.length == free.length;
    }

    test('obstacles never wall off part of the board or the start area', () {
      const c = GameConfig.daily;
      for (var seed = 0; seed < 300; seed++) {
        final l = LayoutGenerator.generate(c, seed);
        expect(l.obstacles, isNotEmpty);
        expect(allFreeConnected(l), isTrue, reason: 'seed $seed');
        for (final o in l.obstacles) {
          expect(LayoutGenerator.inSafeZone(c, o), isFalse);
          expect(o.x > 0 && o.y > 0 && o.x < c.width - 1 && o.y < c.height - 1,
              isTrue);
        }
      }
    });

    test('same seed, same layout', () {
      final a = LayoutGenerator.generate(GameConfig.daily, 1234);
      final b = LayoutGenerator.generate(GameConfig.daily, 1234);
      expect(a.obstacles, b.obstacles);
    });
  });

  group('fixed-step clock', () {
    int stepsFor(List<double> frames) {
      final clock = FixedStepClock();
      var steps = 0;
      for (final f in frames) {
        steps += clock.advance(f, () => 100, () => true);
      }
      return steps;
    }

    test('tick count depends on elapsed time, not frame rate', () {
      final at60 = stepsFor(List.filled(600, 1000 / 60));
      final at30 = stepsFor(List.filled(300, 1000 / 30));
      final at120 = stepsFor(List.filled(1200, 1000 / 120));
      final jittery = stepsFor([
        for (var i = 0; i < 400; i++) i.isEven ? 10.0 : 40.0,
      ]);
      expect(at60, 100);
      expect(at30, 100);
      expect(at120, 100);
      expect(jittery, 100);
    });

    test('long frames are clamped', () {
      final clock = FixedStepClock(maxFrameMs: 250);
      expect(clock.advance(5000, () => 100, () => true), 2);
      expect(clock.accumulatorMs, closeTo(50, 1e-9));
    });

    test('step length is re-read every step (speed-ups)', () {
      final clock = FixedStepClock();
      var len = 100;
      final steps = clock.advance(200, () => len, () {
        len = 50;
        return true;
      });
      expect(steps, 3); // 100 + 50 + 50
    });

    test('stopping discards leftover time; alpha tracks progress', () {
      final clock = FixedStepClock();
      expect(clock.advance(250, () => 100, () => false), 1);
      expect(clock.accumulatorMs, 0);
      clock.advance(25, () => 100, () => true);
      expect(clock.alpha(100), closeTo(0.25, 1e-9));
    });
  });

  test('core/ is pure Dart: no Flutter, Flame or package imports', () {
    final files = Directory('lib/core')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    expect(files, isNotEmpty);
    final importRe = RegExp(r'''^\s*(import|export)\s+['"]([^'"]+)['"]''',
        multiLine: true);
    for (final f in files) {
      for (final m in importRe.allMatches(f.readAsStringSync())) {
        final uri = m.group(2)!;
        expect(uri.startsWith('package:') || uri == 'dart:ui', isFalse,
            reason: '${f.path} imports $uri');
      }
    }
  });
}
