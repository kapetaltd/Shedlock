import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/blink.dart';

/// Shown before the first move. Touches pass through to the game.
class StartHint extends StatelessWidget {
  const StartHint({super.key, this.title});

  /// Optional mode line (e.g. "Daily #42 · Ranked").
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
                    Txt(title!, role: TextRole.label),
                    SizedBox(height: Palette.retro ? 12 : 6),
                  ],
                  Txt('Swipe to move', role: Palette.retro ? TextRole.label : TextRole.body),
                  SizedBox(height: Palette.retro ? 8 : 2),
                  Txt('Tap to shed', role: Palette.retro ? TextRole.label : TextRole.body),
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
              child: Text(
                n > 0 ? '$n' : say('Go'),
                style: textStyle(TextRole.display, size: Palette.retro ? 40 : 56),
              ),
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
    this.homeLabel = 'Home',
  });
  final VoidCallback onResume;
  final VoidCallback onHome;
  final String homeLabel;

  @override
  Widget build(BuildContext context) => Scrim(
        child: SizedBox(
          width: 280,
          child: _Panel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Txt('Paused', role: TextRole.title),
                const SizedBox(height: 20),
                AppButton(label: 'Resume', filled: true, onPressed: onResume),
                const SizedBox(height: 12),
                AppButton(label: homeLabel, compact: true, onPressed: onHome),
              ],
            ),
          ),
        ),
      );
}

/// Dims (and in modern looks, softly blurs) the game behind a panel, and
/// fades in.
class Scrim extends StatelessWidget {
  const Scrim({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Palette.retro) {
      return ColoredBox(
        color: Palette.background.withValues(alpha: 0.75),
        child: Center(child: child),
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, t, child) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6 * t, sigmaY: 6 * t),
        child: ColoredBox(
          color: Palette.background.withValues(alpha: 0.55 * t),
          child: Opacity(
            opacity: t,
            child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
          ),
        ),
      ),
      child: Center(child: child),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: Palette.retro ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(22, 18, 22, 18),
        child: child,
      );
}
