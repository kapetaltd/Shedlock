import 'package:flutter/widgets.dart';

import '../config/app_config.dart';
import '../core/core.dart';
import 'services.dart';
import 'storage_service.dart';

/// Daily Challenge bookkeeping: today's puzzle, the one ranked attempt,
/// results and the streak. The rules themselves live in `core/daily`.
class DailyService {
  DailyService({required this.storage, required this.clock, required this.epoch});

  factory DailyService.of(BuildContext context) {
    final s = Services.of(context);
    return DailyService(storage: s.storage, clock: s.clock, epoch: AppConfig.dailyEpoch);
  }

  final StorageService storage;
  final DateTime Function() clock;
  final DateTime epoch;

  String get todayKey => dailyKey(clock());
  int get todayNumber => dailyNumber(clock(), epoch);

  DailyStatus get status => dailyStatus(
        todayKey: todayKey,
        attemptStartedDayKey: storage.dailyAttemptStarted,
        lastRecord: storage.lastDailyRecord,
      );

  /// Today's ranked result, if finished.
  DailyRecord? get todayRecord {
    final r = storage.lastDailyRecord;
    return r?.dayKey == todayKey ? r : null;
  }

  int get currentStreak => storage.streak.currentOn(todayKey);
  int get bestStreak => storage.streak.best;

  /// Time until the next puzzle (next UTC midnight).
  Duration get untilNextPuzzle {
    final now = clock().toUtc();
    final next = DateTime.utc(now.year, now.month, now.day + 1);
    return next.difference(now);
  }

  /// Marks [dayKey]'s ranked attempt as used. Call when the run starts.
  Future<void> markStarted(String dayKey) => storage.setDailyAttemptStarted(dayKey);

  /// Stores the finished ranked run and extends the streak.
  Future<DailyRecord> complete(RunResult result, {required String dayKey}) async {
    final text = buildShareText(result, appName: AppConfig.appName, tagline: AppConfig.tagline);
    final record = DailyRecord.fromResult(result, dayKey: dayKey, shareText: text);
    await storage.setLastDailyRecord(record);
    await storage.setStreak(storage.streak.record(dayKey));
    return record;
  }
}
