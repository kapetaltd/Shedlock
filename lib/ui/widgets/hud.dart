import 'package:flutter/material.dart';

import '../../game/shedlock_game.dart';
import '../format.dart';
import '../theme/app_theme.dart';

/// Score, multiplier, best, and the pause button.
class Hud extends StatelessWidget {
  const Hud({super.key, required this.game, this.label});

  final ShedlockGame game;

  /// Mode tag shown over the score (e.g. "#42 Practice").
  final String? label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: Palette.retro
            ? const EdgeInsets.fromLTRB(16, 10, 8, 4)
            : const EdgeInsets.fromLTRB(20, 12, 14, 6),
        child: ValueListenableBuilder<HudData>(
          valueListenable: game.hud,
          builder: (context, h, _) => Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Txt(label == null ? 'Score' : 'Score  ·  $label', role: TextRole.caption),
                    SizedBox(height: Palette.retro ? 4 : 0),
                    Text(
                      Palette.retro ? h.score.toString().padLeft(6, '0') : formatScore(h.score),
                      style: textStyle(TextRole.score),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Txt('Best ${formatScore(h.best)}', role: TextRole.caption),
                  SizedBox(height: Palette.retro ? 6 : 4),
                  _Multiplier(text: formatMultiplier(h.multiplierPercent)),
                ],
              ),
              const SizedBox(width: 10),
              _PauseButton(onPressed: game.pauseGame),
            ],
          ),
        ),
      );
}

class _Multiplier extends StatelessWidget {
  const _Multiplier({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    if (Palette.retro) return Text(text, style: textStyle(TextRole.button));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Palette.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text, style: textStyle(TextRole.label, color: Palette.accent)),
    );
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (Palette.retro) {
      return IconButton(
        tooltip: 'Pause',
        onPressed: onPressed,
        icon: Text('II', style: textStyle(TextRole.button)),
      );
    }
    Widget bar() => Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(color: Palette.ink, borderRadius: BorderRadius.circular(2)),
        );
    return Tooltip(
      message: 'Pause',
      child: Semantics(
        button: true,
        label: 'Pause',
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Palette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Palette.line, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [bar(), const SizedBox(width: 5), bar()],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom strip: shed cooldown meter, length and locks.
class ShedBar extends StatelessWidget {
  const ShedBar({super.key, required this.game});

  final ShedlockGame game;

  @override
  Widget build(BuildContext context) => Padding(
        padding: Palette.retro
            ? const EdgeInsets.fromLTRB(16, 6, 16, 12)
            : const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: ValueListenableBuilder<HudData>(
          valueListenable: game.hud,
          builder: (context, h, _) {
            final ready = h.canShed;
            final fraction = h.length > 3 ? h.shedCharge : 0.0;
            return Row(
              children: [
                Txt('Shed',
                    role: Palette.retro ? TextRole.caption : TextRole.label,
                    color: ready ? Palette.ink : Palette.inkSoft),
                const SizedBox(width: 10),
                Expanded(
                  child: Palette.retro
                      ? _RetroMeter(fraction: fraction, ready: ready)
                      : _Meter(fraction: fraction, ready: ready),
                ),
                const SizedBox(width: 14),
                Txt('Length ${h.length}', role: TextRole.caption, color: Palette.ink),
                const SizedBox(width: 12),
                Txt('Locks ${h.locks}', role: TextRole.caption, color: Palette.ink),
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
  Widget build(BuildContext context) => Container(
        height: 10,
        decoration: BoxDecoration(
          color: Palette.line,
          borderRadius: BorderRadius.circular(99),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction.clamp(0.0, 1.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: ready ? Palette.accent : Palette.inkSoft,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      );
}

class _RetroMeter extends StatelessWidget {
  const _RetroMeter({required this.fraction, required this.ready});
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
              color: i < lit ? (ready ? Palette.ink : Palette.inkMid) : Palette.boardAlt,
            ),
          ),
      ],
    );
  }
}
