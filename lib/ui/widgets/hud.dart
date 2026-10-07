import 'package:flutter/material.dart';

import '../../game/shedlock_game.dart';
import '../format.dart';
import '../theme/lcd_theme.dart';

/// Score, multiplier, best, and the pause button.
class Hud extends StatelessWidget {
  const Hud({super.key, required this.game});

  final ShedlockGame game;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
        child: ValueListenableBuilder<HudData>(
          valueListenable: game.hud,
          builder: (context, h, _) => Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SCORE', style: pixelStyle(8, color: LcdPalette.inkMid)),
                    const SizedBox(height: 4),
                    Text(h.score.toString().padLeft(6, '0'), style: pixelStyle(18)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('BEST ${formatScore(h.best)}', style: pixelStyle(8, color: LcdPalette.inkMid)),
                  const SizedBox(height: 6),
                  Text(formatMultiplier(h.multiplierPercent), style: pixelStyle(14)),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Pause',
                onPressed: game.pauseGame,
                icon: Text('II', style: pixelStyle(14)),
              ),
            ],
          ),
        ),
      );
}

/// Bottom strip: shed cooldown meter, length and locks.
class ShedBar extends StatelessWidget {
  const ShedBar({super.key, required this.game});

  final ShedlockGame game;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: ValueListenableBuilder<HudData>(
          valueListenable: game.hud,
          builder: (context, h, _) {
            final ready = h.canShed;
            return Row(
              children: [
                Text('SHED', style: pixelStyle(8, color: ready ? LcdPalette.ink : LcdPalette.inkSoft)),
                const SizedBox(width: 8),
                Expanded(child: _Meter(fraction: h.length > 3 ? h.shedCharge : 0, ready: ready)),
                const SizedBox(width: 12),
                Text('LEN ${h.length}', style: pixelStyle(8)),
                const SizedBox(width: 12),
                Text('LOCK ${h.locks}', style: pixelStyle(8)),
              ],
            );
          },
        ),
      );
}

class _Meter extends StatelessWidget {
  const _Meter({required this.fraction, required this.ready});
  final double fraction;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    const segments = 10;
    final lit = (fraction * segments).floor();
    return Row(
      children: [
        for (var i = 0; i < segments; i++)
          Expanded(
            child: Container(
              height: 10,
              margin: const EdgeInsets.only(right: 2),
              color: i < lit
                  ? (ready ? LcdPalette.ink : LcdPalette.inkMid)
                  : LcdPalette.ghost,
            ),
          ),
      ],
    );
  }
}
