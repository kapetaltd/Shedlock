import '../run/run_result.dart';
import 'share_text.dart';

/// The stored outcome of a day's ranked attempt.
class DailyRecord {
  const DailyRecord({
    required this.dayKey,
    required this.dailyNumber,
    required this.score,
    required this.foodEaten,
    required this.locks,
    required this.sheds,
    required this.rewindsUsed,
    required this.slices,
    required this.shareText,
  });

  factory DailyRecord.fromResult(RunResult r, {required String dayKey, required String shareText}) =>
      DailyRecord(
        dayKey: dayKey,
        dailyNumber: r.dailyNumber ?? 0,
        score: r.score,
        foodEaten: r.foodEaten,
        locks: r.locks,
        sheds: r.sheds,
        rewindsUsed: r.rewindsUsed,
        slices: runSlices(r),
        shareText: shareText,
      );

  final String dayKey;
  final int dailyNumber;
  final int score;
  final int foodEaten;
  final int locks;
  final int sheds;
  final int rewindsUsed;

  /// The run summary grid (see [runSlices]).
  final List<SliceKind> slices;
  final String shareText;

  Map<String, Object?> toJson() => {
        'day': dayKey,
        'n': dailyNumber,
        'score': score,
        'food': foodEaten,
        'locks': locks,
        'sheds': sheds,
        'rewinds': rewindsUsed,
        'slices': slices.map((k) => k.name).join(','),
        'share': shareText,
      };

  factory DailyRecord.fromJson(Map<String, Object?> j) => DailyRecord(
        dayKey: j['day']! as String,
        dailyNumber: (j['n']! as num).toInt(),
        score: (j['score']! as num).toInt(),
        foodEaten: (j['food']! as num).toInt(),
        locks: (j['locks']! as num).toInt(),
        sheds: (j['sheds']! as num).toInt(),
        rewindsUsed: (j['rewinds']! as num).toInt(),
        slices: [
          for (final name in ((j['slices'] as String?) ?? '').split(','))
            if (name.isNotEmpty) SliceKind.values.byName(name),
        ],
        shareText: j['share']! as String,
      );
}

enum DailyStatus {
  /// Today's ranked attempt hasn't started.
  available,

  /// Started but never finished (app closed mid-run). The attempt is used.
  abandoned,

  /// Finished; a result exists.
  completed,
}

/// Today's status from what was stored. The attempt is marked as started the
/// moment a ranked run begins, so quitting the app can't buy a retry.
DailyStatus dailyStatus({
  required String todayKey,
  required String? attemptStartedDayKey,
  required DailyRecord? lastRecord,
}) {
  if (lastRecord?.dayKey == todayKey) return DailyStatus.completed;
  if (attemptStartedDayKey == todayKey) return DailyStatus.abandoned;
  return DailyStatus.available;
}
