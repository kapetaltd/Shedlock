import 'run_session.dart';

/// Score and locks at a point in simulated time. Recorded whenever either
/// changes; used for the share-result emoji grid.
class ScoreMark {
  const ScoreMark(this.simTimeMs, this.score, this.locks);
  final int simTimeMs;
  final int score;
  final int locks;
}

/// Summary of a finished run, for the game-over screen, analytics and sharing.
class RunResult {
  const RunResult({
    required this.mode,
    required this.ranked,
    required this.seed,
    required this.dailyNumber,
    required this.score,
    required this.foodEaten,
    required this.sheds,
    required this.locks,
    required this.rewindsUsed,
    required this.continuesUsed,
    required this.simDurationMs,
    required this.timeline,
  });

  final GameMode mode;
  final bool ranked;
  final int seed;
  final int? dailyNumber;
  final int score;
  final int foodEaten;
  final int sheds;
  final int locks;
  final int rewindsUsed;
  final int continuesUsed;
  final int simDurationMs;
  final List<ScoreMark> timeline;
}
