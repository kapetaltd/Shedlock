import 'seeded_rng.dart';

/// FNV-1a 32-bit hash of [s]'s UTF-16 code units. Stable across platforms.
int fnv1a32(String s) {
  var h = 0x811C9DC5;
  for (final c in s.codeUnits) {
    h ^= c & 0xFF;
    h = SeededRng.imul32(h, 0x01000193);
    final hi = c >> 8;
    if (hi != 0) {
      h ^= hi;
      h = SeededRng.imul32(h, 0x01000193);
    }
  }
  return h;
}

/// "YYYY-MM-DD" for the UTC calendar date of [time].
String dailyKey(DateTime time) {
  final u = time.toUtc();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${u.year.toString().padLeft(4, '0')}-${two(u.month)}-${two(u.day)}';
}

/// The seed every player shares for the UTC day containing [time].
int dailySeed(DateTime time) => fnv1a32('shedlock-${dailyKey(time)}');

/// Puzzle number for the UTC day containing [time]; [epoch]'s day is #1.
int dailyNumber(DateTime time, DateTime epoch) {
  DateTime day(DateTime t) {
    final u = t.toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }

  // Both are UTC midnights, so the difference is a whole number of days.
  return day(time).difference(day(epoch)).inDays + 1;
}

/// Derives an independent seed for a named stream ("layout", "food", ...),
/// so consuming numbers in one stream never shifts another.
int deriveSeed(int seed, String stream) => fnv1a32('$seed/$stream');
