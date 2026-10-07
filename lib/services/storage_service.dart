import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/core.dart';

/// Local persistence. Everything the app stores goes through here so keys
/// live in one place.
abstract class StorageService {
  int get endlessBest;
  Future<void> setEndlessBest(int score);

  /// Day key of the last ranked daily attempt that was *started*.
  String? get dailyAttemptStarted;
  Future<void> setDailyAttemptStarted(String dayKey);

  /// The most recent finished ranked daily.
  DailyRecord? get lastDailyRecord;
  Future<void> setLastDailyRecord(DailyRecord record);

  Streak get streak;
  Future<void> setStreak(Streak streak);
}

class PrefsStorageService implements StorageService {
  PrefsStorageService(this._prefs);

  static Future<PrefsStorageService> create() async =>
      PrefsStorageService(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _kEndlessBest = 'endless_best';
  static const _kDailyStarted = 'daily_attempt_started';
  static const _kDailyRecord = 'daily_last_record';
  static const _kStreak = 'daily_streak';

  @override
  int get endlessBest => _prefs.getInt(_kEndlessBest) ?? 0;

  @override
  Future<void> setEndlessBest(int score) => _prefs.setInt(_kEndlessBest, score);

  @override
  String? get dailyAttemptStarted => _prefs.getString(_kDailyStarted);

  @override
  Future<void> setDailyAttemptStarted(String dayKey) => _prefs.setString(_kDailyStarted, dayKey);

  @override
  DailyRecord? get lastDailyRecord {
    final raw = _prefs.getString(_kDailyRecord);
    if (raw == null) return null;
    try {
      return DailyRecord.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    } on Object {
      return null; // corrupt or old format: treat as missing
    }
  }

  @override
  Future<void> setLastDailyRecord(DailyRecord record) =>
      _prefs.setString(_kDailyRecord, jsonEncode(record.toJson()));

  @override
  Streak get streak {
    final raw = _prefs.getString(_kStreak);
    if (raw == null) return const Streak();
    try {
      return Streak.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    } on Object {
      return const Streak();
    }
  }

  @override
  Future<void> setStreak(Streak streak) => _prefs.setString(_kStreak, jsonEncode(streak.toJson()));
}

/// In-memory storage for tests.
class MemoryStorageService implements StorageService {
  @override
  int endlessBest = 0;

  @override
  String? dailyAttemptStarted;

  @override
  DailyRecord? lastDailyRecord;

  @override
  Streak streak = const Streak();

  @override
  Future<void> setEndlessBest(int score) async => endlessBest = score;

  @override
  Future<void> setDailyAttemptStarted(String dayKey) async => dailyAttemptStarted = dayKey;

  @override
  Future<void> setLastDailyRecord(DailyRecord record) async => lastDailyRecord = record;

  @override
  Future<void> setStreak(Streak s) async => streak = s;
}
