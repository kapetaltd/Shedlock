import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'shedlock_game.dart';
import 'swipe.dart';

/// Whole-screen touch input: swipe anywhere to turn, tap anywhere to shed.
/// Buttons inside [child] still win their own taps.
class GameInput extends StatefulWidget {
  const GameInput({super.key, required this.game, required this.child});

  final ShedlockGame game;
  final Widget child;

  @override
  State<GameInput> createState() => _GameInputState();
}

class _GameInputState extends State<GameInput> {
  final SwipeTracker _swipe = SwipeTracker(threshold: 16);

  @override
  Widget build(BuildContext context) {
    // Scale the swipe distance with the board so it feels the same on every
    // screen size, but keep it short for responsiveness.
    _swipe.threshold = math.max(14, widget.game.metrics.cell * 0.6);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (_) => widget.game.shed(),
      onPanStart: (_) => _swipe.start(),
      onPanUpdate: (d) {
        final dir = _swipe.update(d.delta.dx, d.delta.dy);
        if (dir != null) widget.game.turn(dir);
      },
      child: widget.child,
    );
  }
}
