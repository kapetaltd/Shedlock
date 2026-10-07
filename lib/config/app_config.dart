/// App-wide constants that are not gameplay tuning (see `GameConfig` for that).
class AppConfig {
  static const String appName = 'Shedlock';
  static const String tagline = 'Shed your tail. Lock your prey.';

  /// UTC day that is "Shedlock #1". Change before launch.
  static final DateTime dailyEpoch = DateTime.utc(2026, 11, 1);
}
