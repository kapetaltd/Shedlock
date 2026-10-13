import '../engine/game_engine.dart';
import '../engine/input_buffer.dart';
import '../model/direction.dart';
import '../model/game_config.dart';
import '../model/game_event.dart';
import '../model/game_state.dart';
import '../rewind/snapshot_buffer.dart';
import '../rng/seeds.dart' as seeds;
import 'continue_resolver.dart';
import 'run_result.dart';

enum GameMode { daily, endless }

/// Second-chance allowances for one run.
class RunRules {
  const RunRules({
    this.freeRewinds = 1,
    this.maxAdRewinds = 2,
    this.maxContinues = 1,
    this.adsAllowed = true,
  });

  final int freeRewinds;
  final int maxAdRewinds;
  final int maxContinues;

  /// False for ranked daily attempts: no ad-bought advantages on the shared
  /// leaderboard day.
  final bool adsAllowed;

  static const standard = RunRules();
  static const rankedDaily = RunRules(adsAllowed: false);
}

/// One run: owns the state, input queue, rewind buffer and per-run counters.
/// The Flame layer drives it by calling [tick] from a fixed-step clock.
class RunSession {
  RunSession({
    required this.mode,
    required this.seed,
    GameConfig config = GameConfig.endless,
    this.rules = RunRules.standard,
    this.ranked = false,
    this.dailyNumber,
  })  : _state = GameEngine.newGame(config: config, seed: seed),
        snapshots = SnapshotBuffer(windowMs: config.rewindWindowMs) {
    snapshots.push(_state);
  }

  factory RunSession.endless({required int seed}) =>
      RunSession(mode: GameMode.endless, seed: seed);

  factory RunSession.daily({
    required DateTime now,
    required DateTime epoch,
    required bool ranked,
  }) =>
      RunSession(
        mode: GameMode.daily,
        seed: seeds.dailySeed(now),
        config: GameConfig.daily,
        rules: ranked ? RunRules.rankedDaily : RunRules.standard,
        ranked: ranked,
        dailyNumber: seeds.dailyNumber(now, epoch),
      );

  final GameMode mode;
  final int seed;
  final RunRules rules;
  final bool ranked;
  final int? dailyNumber;
  final SnapshotBuffer snapshots;
  final InputBuffer input = InputBuffer();

  GameState _state;
  GameState get state => _state;

  bool _shedRequested = false;
  int freeRewindsUsed = 0;
  int adRewindsUsed = 0;
  int continuesUsed = 0;
  final List<ScoreMark> _timeline = [const ScoreMark(0, 0, 0)];

  bool get isOver => _state.isDead;
  int get rewindsUsed => freeRewindsUsed + adRewindsUsed;

  /// Queues a swipe. Returns whether it was accepted.
  bool turn(Direction d) => input.push(d, _state.heading);

  /// Queues a shed for the next tick.
  void requestShed() => _shedRequested = true;

  List<GameEvent> tick() {
    if (_state.isDead) return const [];
    final result = GameEngine.step(
      _state,
      StepInput(turn: input.pop(), shed: _shedRequested),
    );
    _shedRequested = false;
    _state = result.state;
    if (!_state.isDead) snapshots.push(_state);
    final last = _timeline.last;
    if (_state.score != last.score || _state.locks != last.locks) {
      _timeline.add(ScoreMark(_state.simTimeMs, _state.score, _state.locks));
    }
    return result.events;
  }

  // --- Second chances ---------------------------------------------------------

  bool get canFreeRewind => isOver && freeRewindsUsed < rules.freeRewinds;

  bool get canAdRewind =>
      isOver &&
      !canFreeRewind &&
      rules.adsAllowed &&
      adRewindsUsed < rules.maxAdRewinds;

  bool get canContinue =>
      isOver && rules.adsAllowed && continuesUsed < rules.maxContinues;

  /// Restores the state from [GameConfig.rewindWindowMs] before death.
  /// Uses the free rewind if one is left, otherwise an ad rewind (the caller
  /// must have shown the rewarded ad).
  bool rewind() {
    final viaAd = !canFreeRewind;
    if (viaAd && !canAdRewind) return false;
    final target = snapshots.restore(_state.simTimeMs);
    if (target == null) return false;
    viaAd ? adRewindsUsed++ : freeRewindsUsed++;
    _resumeFrom(target);
    return true;
  }

  /// Puts a short snake back on the board where it died (see
  /// [ContinueResolver]). The caller must have shown the rewarded ad.
  bool continueRun() {
    if (!canContinue) return false;
    final revived = ContinueResolver.resolve(_state);
    if (revived == null) return false;
    continuesUsed++;
    snapshots.clear();
    _resumeFrom(revived);
    return true;
  }

  void _resumeFrom(GameState s) {
    _state = s;
    input.clear();
    _shedRequested = false;
    if (snapshots.newest != s) snapshots.push(s);
    _timeline.removeWhere((m) => m.simTimeMs > s.simTimeMs);
    final last = _timeline.last;
    if (last.score != s.score || last.locks != s.locks) {
      _timeline.add(ScoreMark(s.simTimeMs, s.score, s.locks));
    }
  }

  RunResult result() => RunResult(
        mode: mode,
        ranked: ranked,
        seed: seed,
        dailyNumber: dailyNumber,
        score: _state.score,
        foodEaten: _state.foodEaten,
        sheds: _state.sheds,
        locks: _state.locks,
        rewindsUsed: rewindsUsed,
        continuesUsed: continuesUsed,
        simDurationMs: _state.simTimeMs,
        timeline: List.unmodifiable(_timeline),
      );
}
