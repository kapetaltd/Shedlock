import '../run/run_result.dart';

/// 1240 → "1,240".
String formatThousands(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// How one slice of a run went, for the share grid.
enum SliceKind { quiet, warm, hot, blazing, lock }

/// Splits a run into [slices] equal stretches of simulated time and grades
/// each by points earned relative to the run's best stretch. Any stretch with
/// a lock shows as a lock.
List<SliceKind> runSlices(RunResult r, {int slices = 5}) {
  final duration = r.simDurationMs;
  if (duration <= 0 || r.timeline.isEmpty) {
    return List.filled(slices, SliceKind.quiet);
  }

  ScoreMark at(double t) {
    var mark = r.timeline.first;
    for (final m in r.timeline) {
      if (m.simTimeMs <= t) {
        mark = m;
      } else {
        break;
      }
    }
    return mark;
  }

  final points = <int>[];
  final locks = <int>[];
  for (var i = 0; i < slices; i++) {
    final start = i == 0 ? const ScoreMark(0, 0, 0) : at(duration * i / slices);
    final end = at(i == slices - 1 ? duration.toDouble() : duration * (i + 1) / slices);
    points.add(end.score - start.score);
    locks.add(end.locks - start.locks);
  }

  final best = points.fold<int>(0, (a, b) => b > a ? b : a);
  return [
    for (var i = 0; i < slices; i++)
      if (locks[i] > 0)
        SliceKind.lock
      else if (points[i] <= 0)
        SliceKind.quiet
      else if (points[i] * 100 < best * 40)
        SliceKind.warm
      else if (points[i] * 100 < best * 75)
        SliceKind.hot
      else
        SliceKind.blazing,
  ];
}

const Map<SliceKind, String> sliceEmoji = {
  SliceKind.quiet: '⬛',
  SliceKind.warm: '🟩',
  SliceKind.hot: '🟨',
  SliceKind.blazing: '🟧',
  SliceKind.lock: '🔒',
};

/// The text players paste into chats, e.g.
///
///     Shedlock #42 🐍 1,240 pts
///     🍎 37 · 🔒 3 · ✂️ 5
///     🟩🟨🟧🔒🟨
///     Shed your tail. Lock your prey.
String buildShareText(
  RunResult r, {
  required String appName,
  required String tagline,
}) {
  final number = r.dailyNumber != null ? ' #${r.dailyNumber}' : '';
  final practice = r.ranked ? '' : ' (practice)';
  final stats = [
    '🍎 ${r.foodEaten}',
    '🔒 ${r.locks}',
    '✂️ ${r.sheds}',
    if (r.rewindsUsed > 0) '⏪ ${r.rewindsUsed}',
  ].join(' · ');
  final grid = runSlices(r).map((k) => sliceEmoji[k]).join();
  return '$appName$number$practice 🐍 ${formatThousands(r.score)} pts\n'
      '$stats\n'
      '$grid\n'
      '$tagline';
}
