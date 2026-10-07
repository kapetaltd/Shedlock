import 'package:flutter/material.dart';

import '../theme/lcd_theme.dart';
import '../widgets/blink.dart';
import '../widgets/lcd_button.dart';

/// Shown before the first move. Touches pass through to the game.
class StartHint extends StatelessWidget {
  const StartHint({super.key, this.title});

  /// Optional mode line (e.g. "DAILY #42 · RANKED").
  final String? title;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Align(
          alignment: const Alignment(0, 0.55),
          child: Blink(
            child: _Panel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null) ...[
                    Text(title!, style: pixelStyle(10)),
                    const SizedBox(height: 12),
                  ],
                  Text('SWIPE TO MOVE', style: pixelStyle(10)),
                  const SizedBox(height: 8),
                  Text('TAP TO SHED', style: pixelStyle(10)),
                ],
              ),
            ),
          ),
        ),
      );
}

class Countdown extends StatelessWidget {
  const Countdown({super.key, required this.value});
  final ValueNotifier<int> value;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Align(
          // Upper third, so it doesn't cover the snake (usually mid-board).
          alignment: const Alignment(0, -0.55),
          child: ValueListenableBuilder<int>(
            valueListenable: value,
            builder: (context, n, _) => _Panel(
              child: Text(n > 0 ? '$n' : 'GO', style: pixelStyle(40)),
            ),
          ),
        ),
      );
}

class PausePanel extends StatelessWidget {
  const PausePanel({
    super.key,
    required this.onResume,
    required this.onHome,
    this.homeLabel = 'HOME',
  });
  final VoidCallback onResume;
  final VoidCallback onHome;
  final String homeLabel;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: LcdPalette.screen.withValues(alpha: 0.7),
        child: Center(
          child: SizedBox(
            width: 260,
            child: _Panel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('PAUSED', style: pixelStyle(18)),
                  const SizedBox(height: 20),
                  LcdButton(label: 'RESUME', filled: true, onPressed: onResume),
                  const SizedBox(height: 12),
                  LcdButton(label: homeLabel, fontSize: 12, onPressed: onHome),
                ],
              ),
            ),
          ),
        ),
      );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LcdPalette.screen,
          border: Border.all(color: LcdPalette.ink, width: 3),
          boxShadow: const [BoxShadow(color: LcdPalette.shadow, offset: Offset(4, 4))],
        ),
        child: child,
      );
}
