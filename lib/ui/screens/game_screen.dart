import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../game/game_input.dart';
import '../../game/shedlock_game.dart';
import '../../services/services.dart';
import '../overlays/game_over_overlay.dart';
import '../overlays/play_overlays.dart';
import '../widgets/hud.dart';

/// Hosts the Flame game plus the Flutter HUD and overlays.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.seed});

  /// Fixed seed for tests; random otherwise.
  final int? seed;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late ShedlockGame _game;
  bool _initialised = false;
  final _random = math.Random();

  RunSession _newSession() => RunSession.endless(
        seed: widget.seed ?? _random.nextInt(0x7FFFFFFF),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final storage = Services.of(context).storage;
    _game = ShedlockGame(
      session: _newSession(),
      best: storage.endlessBest,
      onDeath: _onDeath,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  void _onDeath() {
    final storage = Services.of(context).storage;
    final score = _game.session.state.score;
    if (score > storage.endlessBest) {
      storage.setEndlessBest(score);
    }
    _game.best = math.max(_game.best, score);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _game.pauseGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _game.session.state.config;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            GameInput(
              game: _game,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hud(game: _game),
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
                PlayPhase.waiting => const StartHint(),
                PlayPhase.countdown => Countdown(value: _game.countdown),
                PlayPhase.paused => PausePanel(
                    onResume: _game.resumeGame,
                    onHome: () => Navigator.of(context).pop(),
                  ),
                PlayPhase.over => GameOverOverlay(
                    game: _game,
                    onPlayAgain: () => _game.restart(_newSession()),
                    onHome: () => Navigator.of(context).pop(),
                  ),
                PlayPhase.playing => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
    );
  }
}
