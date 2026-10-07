/// Consecutive UTC days with a completed ranked daily.
class Streak {
  const Streak({this.current = 0, this.best = 0, this.lastDayKey});

  final int current;
  final int best;

  /// "YYYY-MM-DD" of the last day that counted.
  final String? lastDayKey;

  static DateTime parseDay(String key) {
    final p = key.split('-').map(int.parse).toList();
    return DateTime.utc(p[0], p[1], p[2]);
  }

  static int daysBetween(String fromKey, String toKey) =>
      parseDay(toKey).difference(parseDay(fromKey)).inDays;

  /// Records a completed ranked daily on [dayKey].
  Streak record(String dayKey) {
    final last = lastDayKey;
    if (last != null) {
      final gap = daysBetween(last, dayKey);
      if (gap <= 0) return this; // same day (or clock went backwards)
      if (gap == 1) return _with(current + 1, dayKey);
    }
    return _with(1, dayKey);
  }

  Streak _with(int c, String day) =>
      Streak(current: c, best: c > best ? c : best, lastDayKey: day);

  /// The streak to show on [todayKey]: still alive if the last counted day
  /// was today or yesterday, otherwise broken (0).
  int currentOn(String todayKey) {
    final last = lastDayKey;
    if (last == null) return 0;
    final gap = daysBetween(last, todayKey);
    return gap <= 1 ? current : 0;
  }

  Map<String, Object?> toJson() =>
      {'current': current, 'best': best, 'last': lastDayKey};

  factory Streak.fromJson(Map<String, Object?> j) => Streak(
        current: (j['current'] as num?)?.toInt() ?? 0,
        best: (j['best'] as num?)?.toInt() ?? 0,
        lastDayKey: j['last'] as String?,
      );
}
