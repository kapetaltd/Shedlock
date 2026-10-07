import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/core.dart';
import 'components/board_component.dart';
import 'components/effects_component.dart';

enum PlayPhase {
  /// Board shown, waiting for the first swipe or tap.
  waiting,
  playing,

  /// 3-2-1 before resuming (after pause, rewind or continue).
  countdown,
  paused,

  /// The snake died; the game-over overlay decides what happens next.
  over,
}

/// What the Flutter HUD shows. Rebuilt once per tick, not per frame.
@immutable
class HudData {
  const HudData({
    required this.score,
    required this.best,
    required this.multiplierPercent,
    required this.length,
    required this.locks,
    required this.shedCharge,
    required this.canShed,
  });

  factory HudData.of(GameState s, int best) {
    final c = s.config;
    final charge = ((s.simTimeMs - s.lastShedAtMs) / c.shedCooldownMs).clamp(0.0, 1.0);
    return HudData(
      score: s.score,
      best: math.max(best, s.score),
      multiplierPercent: s.multiplierPercent,
      length: s.length,
      locks: s.locks,
      shedCharge: charge,
      canShed: s.canShedNow,
    );
  }

  final int score;
  final int best;
  final int multiplierPercent;
  final int length;
  final int locks;

  /// 0..1 progress of the shed cooldown.
  final double shedCharge;
  final bool canShed;

  @override
  bool operator ==(Object other) =>
      other is HudData &&
      other.score == score &&
      other.best == best &&
      other.multiplierPercent == multiplierPercent &&
      other.length == length &&
      other.locks == locks &&
      other.shedCharge == shedCharge &&
      other.canShed == canShed;

  @override
  int get hashCode =>
      Object.hash(score, best, multiplierPercent, length, locks, shedCharge, canShed);
}

/// Board placement on screen, recomputed on resize.
class BoardMetrics {
  const BoardMetrics({required this.cell, required this.origin});
  final double cell;
  final Offset origin;

  Rect cellRect(double x, double y) =>
      Rect.fromLTWH(origin.dx + x * cell, origin.dy + y * cell, cell, cell);
}

/// The Flame game. Owns the fixed-step clock and drives a [RunSession];
/// everything it draws is read from the session's immutable state.
class ShedlockGame extends FlameGame with KeyboardEvents {
  ShedlockGame({
    required RunSession session,
    this.best = 0,
    this.onEvents,
    this.onDeath,
    this.onStart,
    this.loadout = const Loadout(),
  })  : _session = session,
        previous = session.state;

  RunSession _session;
  RunSession get session => _session;

  /// Best score shown in the HUD (the screen persists it).
  int best;

  /// Every tick's events, for sound, haptics and analytics.
  final void Function(List<GameEvent> events)? onEvents;

  /// Called once when the snake dies.
  final VoidCallback? onDeath;

  /// Called when a run's first move is made.
  final VoidCallback? onStart;

  /// Cosmetics (snake skin, trail). Purely visual.
  Loadout loadout;

  /// Cells the tail recently left, with the [animTime] they were left at.
  /// Drives the trail cosmetic.
  final List<(GridPos, double)> trail = [];
  static const double trailSeconds = 0.6;

  /// The state before the most recent tick, for interpolation.
  GameState previous;

  final FixedStepClock clock = FixedStepClock();
  final ValueNotifier<PlayPhase> phase = ValueNotifier(PlayPhase.waiting);
  final ValueNotifier<int> countdown = ValueNotifier(0);
  late final ValueNotifier<HudData> hud =
      ValueNotifier(HudData.of(_session.state, best));

  static const double countdownSeconds = 1.8;
  double _countdownLeft = 0;

  BoardMetrics metrics = const BoardMetrics(cell: 16, origin: Offset.zero);

  late final BoardComponent board;
  late final EffectsComponent effects;

  /// Seconds of play, for the visual animations (blink, pulse).
  double animTime = 0;

  /// Screen shake.
  double _shakeLeft = 0;
  double _shakeStrength = 0;
  Offset shakeOffset = Offset.zero;
  final math.Random _fxRandom = math.Random();

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    board = BoardComponent();
    effects = EffectsComponent();
    await addAll([board, effects]);
    _layout(size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _layout(size);
  }

  void _layout(Vector2 size) {
    final c = _session.state.config;
    // Leave room for the 3px frame on each side.
    final cell = math.max(
      4.0,
      math.min((size.x - 8) / c.width, (size.y - 8) / c.height).floorToDouble(),
    );
    final w = cell * c.width;
    final h = cell * c.height;
    metrics = BoardMetrics(
      cell: cell,
      origin: Offset(((size.x - w) / 2).floorToDouble(), ((size.y - h) / 2).floorToDouble()),
    );
  }

  /// 0..1 progress towards the next tick, for smooth movement.
  double get alpha => phase.value == PlayPhase.playing
      ? clock.alpha(_session.state.tickMs)
      : 1.0;

  /// Simulated time "now", including the partial tick, for fades.
  double get renderTimeMs =>
      previous.simTimeMs + (_session.state.simTimeMs - previous.simTimeMs) * alpha;

  @override
  void update(double dt) {
    super.update(dt);
    animTime += dt;
    trail.removeWhere((t) => animTime - t.$2 > trailSeconds);
    _updateShake(dt);

    switch (phase.value) {
      case PlayPhase.countdown:
        _countdownLeft -= dt;
        final n = (_countdownLeft / (countdownSeconds / 3)).ceil();
        countdown.value = n.clamp(0, 3);
        if (_countdownLeft <= 0) {
          clock.reset();
          phase.value = PlayPhase.playing;
        }
      case PlayPhase.playing:
        clock.advance(dt * 1000, () => _session.state.tickMs, _step);
        hud.value = HudData.of(_session.state, best);
      case PlayPhase.waiting:
      case PlayPhase.paused:
      case PlayPhase.over:
        break;
    }
  }

  bool _step() {
    previous = _session.state;
    final events = _session.tick();
    if (loadout.trail != Trail.none) _recordTrail();
    effects.handle(events);
    onEvents?.call(events);
    if (_session.isOver) {
      previous = _session.state;
      phase.value = PlayPhase.over;
      shake(0.45, metrics.cell * 0.5);
      hud.value = HudData.of(_session.state, best);
      onDeath?.call();
      return false;
    }
    return true;
  }

  // --- Input ----------------------------------------------------------------

  void turn(Direction d) {
    switch (phase.value) {
      case PlayPhase.waiting:
        _session.turn(d);
        _start();
      case PlayPhase.playing:
      case PlayPhase.countdown:
        _session.turn(d);
      case PlayPhase.paused:
      case PlayPhase.over:
        break;
    }
  }

  void shed() {
    switch (phase.value) {
      case PlayPhase.waiting:
        _start();
      case PlayPhase.playing:
        _session.requestShed();
      case PlayPhase.countdown:
      case PlayPhase.paused:
      case PlayPhase.over:
        break;
    }
  }

  void _start() {
    clock.reset();
    phase.value = PlayPhase.playing;
    onStart?.call();
  }

  void _recordTrail() {
    final now = _session.state;
    final body = now.snake.toSet();
    final walls = {for (final w in now.shedWalls) w.pos};
    for (final p in previous.snake) {
      if (!body.contains(p) && !walls.contains(p)) trail.add((p, animTime));
    }
  }

  void pauseGame() {
    if (phase.value == PlayPhase.playing || phase.value == PlayPhase.countdown) {
      phase.value = PlayPhase.paused;
    }
  }

  void resumeGame() {
    if (phase.value == PlayPhase.paused) _beginCountdown();
  }

  void _beginCountdown() {
    _countdownLeft = countdownSeconds;
    countdown.value = 3;
    phase.value = PlayPhase.countdown;
  }

  // --- Second chances ---------------------------------------------------------

  /// Rewinds (free or ad: the caller shows the ad first). Returns success.
  bool rewind() => _resumeAfter(_session.rewind());

  /// Continues after a rewarded ad. Returns success.
  bool continueRun() => _resumeAfter(_session.continueRun());

  bool _resumeAfter(bool ok) {
    if (!ok) return false;
    previous = _session.state;
    effects.clear();
    trail.clear();
    hud.value = HudData.of(_session.state, best);
    _beginCountdown();
    return true;
  }

  /// Starts a brand new run on the same game instance.
  void restart(RunSession session) {
    _session = session;
    previous = session.state;
    effects.clear();
    trail.clear();
    clock.reset();
    hud.value = HudData.of(session.state, best);
    phase.value = PlayPhase.waiting;
  }

  // --- Effects --------------------------------------------------------------

  /// Players can turn shake off (motion sensitivity).
  bool shakeEnabled = true;

  void shake(double seconds, double strength) {
    if (!shakeEnabled) return;
    _shakeLeft = seconds;
    _shakeStrength = strength;
  }

  void _updateShake(double dt) {
    if (_shakeLeft <= 0) {
      shakeOffset = Offset.zero;
      return;
    }
    _shakeLeft -= dt;
    final k = _shakeStrength * (_shakeLeft.clamp(0.0, 1.0) / 0.45);
    shakeOffset = Offset(
      (_fxRandom.nextDouble() * 2 - 1) * k,
      (_fxRandom.nextDouble() * 2 - 1) * k,
    );
  }

  // --- Keyboard (web / desktop / emulator testing) --------------------------

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final dir = switch (key) {
      LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.keyW => Direction.up,
      LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.keyS => Direction.down,
      LogicalKeyboardKey.arrowLeft || LogicalKeyboardKey.keyA => Direction.left,
      LogicalKeyboardKey.arrowRight || LogicalKeyboardKey.keyD => Direction.right,
      _ => null,
    };
    if (dir != null) {
      turn(dir);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space) {
      shed();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyP || key == LogicalKeyboardKey.escape) {
      phase.value == PlayPhase.paused ? resumeGame() : pauseGame();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void onRemove() {
    phase.dispose();
    countdown.dispose();
    hud.dispose();
    super.onRemove();
  }
}
