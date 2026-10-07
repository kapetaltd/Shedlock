import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/core/core.dart';

RunResult result({
  int score = 1240,
  int duration = 50000,
  List<ScoreMark> timeline = const [],
  int rewinds = 0,
  bool ranked = true,
}) =>
    RunResult(
      mode: GameMode.daily,
      ranked: ranked,
      seed: 1,
      dailyNumber: 42,
      score: score,
      foodEaten: 37,
      sheds: 5,
      locks: 3,
      rewindsUsed: rewinds,
      continuesUsed: 0,
      simDurationMs: duration,
      timeline: timeline,
    );

void main() {
  group('run slices', () {
    test('grades each fifth of the run against the best fifth', () {
      // 5 slices of 10 s. Points: 0, 100, 300, 400 (+lock), 200.
      final r = result(timeline: const [
        ScoreMark(0, 0, 0),
        ScoreMark(15000, 100, 0),
        ScoreMark(25000, 400, 0),
        ScoreMark(35000, 700, 1),
        ScoreMark(38000, 800, 1),
        ScoreMark(45000, 1000, 1),
      ]);
      expect(runSlices(r), [
        SliceKind.quiet,
        SliceKind.warm, // 100 of best 400 = 25%
        SliceKind.blazing, // 300 of 400 = 75%
        SliceKind.lock, // best slice, but it had a lock
        SliceKind.hot, // 200 of 400 = 50%
      ]);
    });

    test('empty or instant runs are all quiet', () {
      expect(runSlices(result(duration: 0)), List.filled(5, SliceKind.quiet));
      expect(runSlices(result(timeline: const [ScoreMark(0, 0, 0)])),
          List.filled(5, SliceKind.quiet));
    });
  });

  group('share text', () {
    test('has the name, number, score, stats, grid and tagline', () {
      final text = buildShareText(
        result(timeline: const [ScoreMark(0, 0, 0), ScoreMark(45000, 1240, 3)]),
        appName: 'Shedlock',
        tagline: 'Shed your tail. Lock your prey.',
      );
      expect(
        text,
        'Shedlock #42 🐍 1,240 pts\n'
        '🍎 37 · 🔒 3 · ✂️ 5\n'
        '⬛⬛⬛⬛🔒\n'
        'Shed your tail. Lock your prey.',
      );
    });

    test('shows rewinds when used and marks practice runs', () {
      final text = buildShareText(result(rewinds: 1, ranked: false),
          appName: 'Shedlock', tagline: 't');
      expect(text, startsWith('Shedlock #42 (practice) 🐍'));
      expect(text, contains('⏪ 1'));
    });

    test('thousands separators', () {
      expect(formatThousands(0), '0');
      expect(formatThousands(999), '999');
      expect(formatThousands(1000), '1,000');
      expect(formatThousands(1234567), '1,234,567');
    });
  });

  group('streak', () {
    test('consecutive days count up; a gap resets to 1', () {
      var s = const Streak();
      s = s.record('2026-10-06');
      expect((s.current, s.best), (1, 1));
      s = s.record('2026-10-07');
      s = s.record('2026-10-08');
      expect((s.current, s.best), (3, 3));
      s = s.record('2026-10-10');
      expect((s.current, s.best), (1, 3));
    });

    test('playing twice on one day counts once', () {
      final s = const Streak().record('2026-10-06').record('2026-10-06');
      expect(s.current, 1);
    });

    test('crosses month and year boundaries', () {
      final s = const Streak().record('2026-12-31').record('2027-01-01');
      expect(s.current, 2);
      final leap = const Streak().record('2028-02-28').record('2028-02-29').record('2028-03-01');
      expect(leap.current, 3);
    });

    test('shown streak stays alive until a day is missed', () {
      final s = const Streak().record('2026-10-06').record('2026-10-07');
      expect(s.currentOn('2026-10-07'), 2);
      expect(s.currentOn('2026-10-08'), 2, reason: 'today not played yet');
      expect(s.currentOn('2026-10-09'), 0, reason: 'missed a day');
      expect(const Streak().currentOn('2026-10-09'), 0);
    });

    test('json round trip', () {
      final s = const Streak().record('2026-10-06').record('2026-10-07');
      final back = Streak.fromJson(s.toJson());
      expect((back.current, back.best, back.lastDayKey), (2, 2, '2026-10-07'));
    });
  });

  group('daily record and status', () {
    test('json round trip keeps everything', () {
      final r = DailyRecord.fromResult(
        result(timeline: const [ScoreMark(0, 0, 0), ScoreMark(20000, 600, 1)]),
        dayKey: '2026-10-07',
        shareText: 'text',
      );
      final back = DailyRecord.fromJson(r.toJson());
      expect(back.toJson(), r.toJson());
      expect(back.slices, r.slices);
    });

    test('one ranked attempt per UTC day', () {
      final rec = DailyRecord.fromResult(result(), dayKey: '2026-10-07', shareText: '');
      expect(
        dailyStatus(todayKey: '2026-10-07', attemptStartedDayKey: null, lastRecord: null),
        DailyStatus.available,
      );
      expect(
        dailyStatus(todayKey: '2026-10-07', attemptStartedDayKey: '2026-10-07', lastRecord: null),
        DailyStatus.abandoned,
      );
      expect(
        dailyStatus(todayKey: '2026-10-07', attemptStartedDayKey: '2026-10-07', lastRecord: rec),
        DailyStatus.completed,
      );
      // Yesterday's attempt doesn't block today.
      expect(
        dailyStatus(todayKey: '2026-10-08', attemptStartedDayKey: '2026-10-07', lastRecord: rec),
        DailyStatus.available,
      );
    });
  });
}
