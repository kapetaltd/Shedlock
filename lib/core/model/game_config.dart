import 'dart:math' as math;

/// Every tunable gameplay number lives here.
///
/// All times are in simulated milliseconds (the sum of tick intervals), never
/// wall-clock time, so a run is fully determined by its seed and inputs.
class GameConfig {
  const GameConfig({
    this.width = 20,
    this.height = 30,
    this.startLength = 3,
    this.shedKeep = 3,
    this.startTickMs = 180,
    this.minTickMs = 70,
    this.tickMsDropPerFood = 3,
    this.shedWallLifetimeMs = 10000,
    this.shedCooldownMs = 1000,
    this.runnerMoveEveryTicks = 4,
    this.runnerMinNormalFood = 3,
    this.runnerSpawnPercent = 25,
    this.runnerFleePercent = 70,
    this.foodBasePoints = 10,
    this.multiplierPercentPerSegment = 10,
    this.lockBonus = 100,
    this.obstacleClusters = 2,
    this.rewindWindowMs = 3000,
  })  : assert(width >= 8 && height >= 8),
        assert(shedKeep >= 2 && startLength >= shedKeep),
        assert(minTickMs > 0 && startTickMs >= minTickMs);

  /// Board size in cells.
  final int width;
  final int height;

  /// Snake length at the start of a run.
  final int startLength;

  /// Segments kept (head included) when shedding.
  final int shedKeep;

  /// Tick interval: starts at [startTickMs], drops by [tickMsDropPerFood]
  /// per food eaten, never below [minTickMs].
  final int startTickMs;
  final int minTickMs;
  final int tickMsDropPerFood;

  /// How long shed walls stay solid.
  final int shedWallLifetimeMs;

  /// Minimum time between two sheds.
  final int shedCooldownMs;

  /// A runner moves once every this many ticks.
  final int runnerMoveEveryTicks;

  /// No runner can spawn before this many normal foods have been spawned.
  final int runnerMinNormalFood;

  /// Chance (0-100) that eating a normal food also spawns a runner, if none
  /// is on the board.
  final int runnerSpawnPercent;

  /// Chance (0-100) a runner picks the move that gets furthest from the
  /// snake's head instead of a random legal move.
  final int runnerFleePercent;

  /// Points for one food at multiplier x1.0.
  final int foodBasePoints;

  /// Multiplier gain per segment above [startLength], in percent
  /// (10 → +0.1x per segment).
  final int multiplierPercentPerSegment;

  /// Flat bonus for locking a runner.
  final int lockBonus;

  /// Number of obstacle clusters generated on the board.
  final int obstacleClusters;

  /// How far back a rewind goes.
  final int rewindWindowMs;

  static const GameConfig endless = GameConfig();
  static const GameConfig daily = GameConfig(obstacleClusters: 4);

  int tickMsFor(int foodEaten) =>
      math.max(minTickMs, startTickMs - foodEaten * tickMsDropPerFood);

  /// Score multiplier for a snake of [length], in percent (100 = x1.0).
  int multiplierPercent(int length) =>
      100 + multiplierPercentPerSegment * math.max(0, length - startLength);

  /// Points for eating one food with a snake of [length].
  int foodPoints(int length) =>
      foodBasePoints * multiplierPercent(length) ~/ 100;

  GameConfig copyWith({
    int? width,
    int? height,
    int? startLength,
    int? shedKeep,
    int? startTickMs,
    int? minTickMs,
    int? tickMsDropPerFood,
    int? shedWallLifetimeMs,
    int? shedCooldownMs,
    int? runnerMoveEveryTicks,
    int? runnerMinNormalFood,
    int? runnerSpawnPercent,
    int? runnerFleePercent,
    int? foodBasePoints,
    int? multiplierPercentPerSegment,
    int? lockBonus,
    int? obstacleClusters,
    int? rewindWindowMs,
  }) =>
      GameConfig(
        width: width ?? this.width,
        height: height ?? this.height,
        startLength: startLength ?? this.startLength,
        shedKeep: shedKeep ?? this.shedKeep,
        startTickMs: startTickMs ?? this.startTickMs,
        minTickMs: minTickMs ?? this.minTickMs,
        tickMsDropPerFood: tickMsDropPerFood ?? this.tickMsDropPerFood,
        shedWallLifetimeMs: shedWallLifetimeMs ?? this.shedWallLifetimeMs,
        shedCooldownMs: shedCooldownMs ?? this.shedCooldownMs,
        runnerMoveEveryTicks: runnerMoveEveryTicks ?? this.runnerMoveEveryTicks,
        runnerMinNormalFood: runnerMinNormalFood ?? this.runnerMinNormalFood,
        runnerSpawnPercent: runnerSpawnPercent ?? this.runnerSpawnPercent,
        runnerFleePercent: runnerFleePercent ?? this.runnerFleePercent,
        foodBasePoints: foodBasePoints ?? this.foodBasePoints,
        multiplierPercentPerSegment:
            multiplierPercentPerSegment ?? this.multiplierPercentPerSegment,
        lockBonus: lockBonus ?? this.lockBonus,
        obstacleClusters: obstacleClusters ?? this.obstacleClusters,
        rewindWindowMs: rewindWindowMs ?? this.rewindWindowMs,
      );
}
