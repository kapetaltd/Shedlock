import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/core.dart';
import 'settings.dart';

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

  // --- Sessions and ad pacing -------------------------------------------------
  int get sessionCount;
  Future<void> setSessionCount(int n);
  DateTime? get lastActiveAt;
  Future<void> setLastActiveAt(DateTime t);
  int get runsSinceInterstitial;
  Future<void> setRunsSinceInterstitial(int n);

  // --- Purchases and cosmetics --------------------------------------------------
  /// Packs the player owns (cached from the store; restored on reinstall).
  Set<Pack> get ownedPacks;
  Future<void> setOwnedPacks(Set<Pack> packs);
  Loadout get loadout;
  Future<void> setLoadout(Loadout loadout);

  GameSettings get settings;
  Future<void> setSettings(GameSettings settings);
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
  static const _kSessions = 'session_count';
  static const _kLastActive = 'last_active_ms';
  static const _kRunsSinceAd = 'runs_since_interstitial';
  static const _kOwned = 'owned_packs';
  static const _kLoadout = 'loadout';
  static const _kSettings = 'settings';

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

  @override
  int get sessionCount => _prefs.getInt(_kSessions) ?? 0;

  @override
  Future<void> setSessionCount(int n) => _prefs.setInt(_kSessions, n);

  @override
  DateTime? get lastActiveAt {
    final ms = _prefs.getInt(_kLastActive);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  @override
  Future<void> setLastActiveAt(DateTime t) => _prefs.setInt(_kLastActive, t.millisecondsSinceEpoch);

  @override
  int get runsSinceInterstitial => _prefs.getInt(_kRunsSinceAd) ?? 0;

  @override
  Future<void> setRunsSinceInterstitial(int n) => _prefs.setInt(_kRunsSinceAd, n);

  @override
  Set<Pack> get ownedPacks => {
        for (final name in _prefs.getStringList(_kOwned) ?? const <String>[])
          ...Pack.values.where((p) => p.name == name),
      };

  @override
  Future<void> setOwnedPacks(Set<Pack> packs) =>
      _prefs.setStringList(_kOwned, [for (final p in packs) p.name]);

  @override
  Loadout get loadout {
    final raw = _prefs.getString(_kLoadout);
    if (raw == null) return const Loadout();
    try {
      return Loadout.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    } on Object {
      return const Loadout();
    }
  }

  @override
  Future<void> setLoadout(Loadout loadout) => _prefs.setString(_kLoadout, jsonEncode(loadout.toJson()));

  @override
  GameSettings get settings {
    final raw = _prefs.getString(_kSettings);
    if (raw == null) return const GameSettings();
    try {
      return GameSettings.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    } on Object {
      return const GameSettings();
    }
  }

  @override
  Future<void> setSettings(GameSettings s) => _prefs.setString(_kSettings, jsonEncode(s.toJson()));
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

  @override
  int sessionCount = 0;

  @override
  DateTime? lastActiveAt;

  @override
  int runsSinceInterstitial = 0;

  @override
  Set<Pack> ownedPacks = {};

  @override
  Loadout loadout = const Loadout();

  @override
  Future<void> setSessionCount(int n) async => sessionCount = n;

  @override
  Future<void> setLastActiveAt(DateTime t) async => lastActiveAt = t;

  @override
  Future<void> setRunsSinceInterstitial(int n) async => runsSinceInterstitial = n;

  @override
  Future<void> setOwnedPacks(Set<Pack> packs) async => ownedPacks = {...packs};

  @override
  Future<void> setLoadout(Loadout l) async => loadout = l;

  @override
  GameSettings settings = const GameSettings();

  @override
  Future<void> setSettings(GameSettings s) async => settings = s;
}
