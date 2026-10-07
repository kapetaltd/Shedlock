import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence. Everything the app stores goes through here so keys
/// live in one place.
abstract class StorageService {
  int get endlessBest;
  Future<void> setEndlessBest(int score);
}

class PrefsStorageService implements StorageService {
  PrefsStorageService(this._prefs);

  static Future<PrefsStorageService> create() async =>
      PrefsStorageService(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _kEndlessBest = 'endless_best';

  @override
  int get endlessBest => _prefs.getInt(_kEndlessBest) ?? 0;

  @override
  Future<void> setEndlessBest(int score) => _prefs.setInt(_kEndlessBest, score);
}

/// In-memory storage for tests.
class MemoryStorageService implements StorageService {
  @override
  int endlessBest = 0;

  @override
  Future<void> setEndlessBest(int score) async => endlessBest = score;
}
