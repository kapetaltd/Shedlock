import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../core/core.dart';
import '../../game/game_input.dart';
import '../../game/shedlock_game.dart';
import '../../services/ad_coordinator.dart';
import '../../services/analytics_service.dart';
import '../../services/daily_service.dart';
import '../../services/services.dart';
import '../overlays/game_over_overlay.dart';
import '../overlays/play_overlays.dart';
import '../widgets/hud.dart';
import 'daily_result_screen.dart';

/// Hosts the Flame game plus the Flutter HUD and overlays, for Endless and
/// Daily (ranked or practice).
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.mode = GameMode.endless,
    this.ranked = false,
    this.seed,
  });

  final GameMode mode;

  /// Daily only: the day's single ranked attempt.
  final bool ranked;

  /// Endless only: fixed seed for tests; random otherwise.
  final int? seed;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late ShedlockGame _game;
  late DailyService _daily;
  bool _initialised = false;
  final _random = math.Random();

  /// The moment the screen opened: a daily run belongs to that UTC day even
  /// if it crosses midnight.
  late DateTime _runDate;
  late bool _ranked;
  bool _finishing = false;
  Timer? _autoFinish;

  late AdCoordinator _adsCoord;
  late AnalyticsService _analytics;

  /// A run is "active" from its first move until it is ended (the player
  /// leaves game over, quits from pause, or the ranked run is finished).
  bool _runActive = false;
  final Stopwatch _runClock = Stopwatch();

  bool get _isDaily => widget.mode == GameMode.daily;

  RunSession _newSession() => _isDaily
      ? RunSession.daily(now: _runDate, epoch: AppConfig.dailyEpoch, ranked: _ranked)
      : RunSession.endless(seed: widget.seed ?? _random.nextInt(0x7FFFFFFF));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final services = Services.of(context);
    _daily = DailyService.of(context);
    _runDate = services.clock();
    _ranked = _isDaily && widget.ranked;
    if (_ranked) _daily.markStarted(dailyKey(_runDate));

    final best = switch (widget.mode) {
      GameMode.endless => services.storage.endlessBest,
      GameMode.daily => _daily.todayRecord?.score ?? 0,
    };
    _adsCoord = AdCoordinator.of(context);
    _analytics = services.analytics;
    _game = ShedlockGame(
      session: _newSession(),
      best: best,
      onDeath: _onDeath,
      onStart: _onRunStart,
      loadout: services.loadout.value,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  void _onRunStart() {
    _runActive = true;
    _runClock
      ..reset()
      ..start();
    _analytics.log(Events.runStart(widget.mode, ranked: _game.session.ranked));
  }

  /// Logs run_end and counts the run for ad pacing. Safe to call twice.
  Future<void> _endRun() async {
    if (!_runActive) return;
    _runActive = false;
    _runClock.stop();
    await _analytics.log(
      Events.runEnd(_game.session.result(), realDurationMs: _runClock.elapsedMilliseconds),
    );
    await _adsCoord.onRunCompleted();
  }

  /// Run over → menu or next run: the only place interstitials may appear.
  Future<void> _leaveRun(VoidCallback then) async {
    await _endRun();
    await _adsCoord.maybeShowInterstitial();
    if (mounted) then();
  }

  void _onDeath() {
    final score = _game.session.state.score;
    if (widget.mode == GameMode.endless) {
      final storage = Services.of(context).storage;
      if (score > storage.endlessBest) storage.setEndlessBest(score);
    }
    _game.best = math.max(_game.best, score);

    // A ranked run with no free rewind left is over: go straight to results
    // once the death animation has played.
    if (_ranked && !_game.session.canFreeRewind) {
      _autoFinish = Timer(const Duration(milliseconds: 900), _finishRanked);
    }
  }

  /// Ends the ranked attempt, stores it and shows the result.
  Future<void> _finishRanked() async {
    if (_finishing || !_ranked) return;
    _finishing = true;
    _game.pauseGame();
    await _endRun();
    final record = await _daily.complete(_game.session.result(), dayKey: dailyKey(_runDate));
    await _analytics.log(Events.streakLength(_daily.currentStreak));
    if (!mounted) return;
    // No interstitial here: the next screen is the daily share screen.
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => DailyResultScreen(record: record)),
    );
  }

  void _playAgain() => _leaveRun(() {
        // After the ranked attempt, any replay of the daily is practice.
        _ranked = false;
        _game.restart(_newSession());
      });

  void _home() => _leaveRun(() => Navigator.of(context).pop());

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _game.pauseGame();
  }

  @override
  void dispose() {
    _autoFinish?.cancel();
    _endRun(); // e.g. system back from game over
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _game.session.state.config;
    return PopScope(
      // System back pauses a ranked run instead of silently abandoning it.
      canPop: !_ranked,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _game.pauseGame();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              GameInput(
                game: _game,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hud(game: _game, label: _modeLabel),
                    Flexible(
                      child: AspectRatio(
                        aspectRatio: c.width / c.height,
                        child: GameWidget(game: _game, autofocus: true),
                      ),
                    ),
                    ShedBar(game: _game),
                  ],
                ),
              ),
              ValueListenableBuilder<PlayPhase>(
                valueListenable: _game.phase,
                builder: (context, phase, _) => switch (phase) {
                  PlayPhase.waiting => StartHint(title: _startTitle),
                  PlayPhase.countdown => Countdown(value: _game.countdown),
                  PlayPhase.paused => _finishing
                      ? const SizedBox.shrink()
                      : PausePanel(
                          onResume: _game.resumeGame,
                          homeLabel: _ranked ? 'END RUN' : 'HOME',
                          onHome: _ranked ? _finishRanked : _home,
                        ),
                  PlayPhase.over => GameOverOverlay(
                      game: _game,
                      ranked: _ranked,
                      onEndRun: _finishRanked,
                      onPlayAgain: _playAgain,
                      onHome: _home,
                    ),
                  PlayPhase.playing => const SizedBox.shrink(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? get _modeLabel => switch (widget.mode) {
        GameMode.endless => null,
        GameMode.daily => '#${_game.session.dailyNumber}${_ranked ? '' : ' PRACTICE'}',
      };

  String? get _startTitle => switch (widget.mode) {
        GameMode.endless => null,
        GameMode.daily => _ranked
            ? 'DAILY #${_game.session.dailyNumber} · RANKED'
            : 'DAILY #${_game.session.dailyNumber} · PRACTICE',
      };
}
