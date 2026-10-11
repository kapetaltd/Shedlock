import 'dart:async';

import 'package:flutter/material.dart';

import '../../game/shedlock_game.dart';
import '../../services/ads_service.dart';
import '../../services/ad_coordinator.dart';
import '../../services/services.dart';
import '../format.dart';
import '../theme/app_theme.dart';
import 'play_overlays.dart';
import '../widgets/app_button.dart';

/// Score summary plus every second-chance option the run still has.
/// Appears after a short delay so the death shake is visible.
class GameOverOverlay extends StatefulWidget {
  const GameOverOverlay({
    super.key,
    required this.game,
    required this.onPlayAgain,
    required this.onHome,
    this.ranked = false,
    this.onEndRun,
  });

  final ShedlockGame game;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  /// Ranked daily: the only choices are the free rewind or ending the run.
  final bool ranked;
  final VoidCallback? onEndRun;

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay> {
  bool _visible = false;
  bool _busy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String? _adMessage;

  /// Plays the rewind sound when [action] succeeds.
  bool Function() _withSound(bool Function() action) => () {
        final ok = action();
        if (ok) Services.of(context).feedback.rewind();
        return ok;
      };

  Future<void> _withAd(RewardedPlacement placement, bool Function() grant) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _adMessage = null;
    });
    final earned = await AdCoordinator.of(context).rewarded(placement);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!earned) _adMessage = 'No ad right now. Try again soon.';
    });
    if (earned) grant();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.expand();
    final session = widget.game.session;
    final s = session.state;
    final isBest = s.score > 0 && s.score >= widget.game.best;
    final adRewindsLeft = session.rules.maxAdRewinds - session.adRewindsUsed;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Txt('Game over', role: TextRole.title),
        SizedBox(height: Palette.retro ? 18 : 8),
        Text(formatScore(s.score), style: textStyle(TextRole.display, size: Palette.retro ? 32 : null)),
        SizedBox(height: Palette.retro ? 8 : 2),
        Txt(isBest ? 'New best!' : 'Best ${formatScore(widget.game.best)}',
            role: TextRole.caption, color: isBest ? Palette.accent : null),
        const SizedBox(height: 14),
        Txt(
          'Food ${s.foodEaten}  ·  Locks ${s.locks}  ·  Sheds ${s.sheds}',
          role: TextRole.caption,
          color: Palette.ink,
          align: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (_adMessage != null) ...[
          Txt(_adMessage!, role: TextRole.caption, color: Palette.ink, align: TextAlign.center),
          const SizedBox(height: 12),
        ],
        if (session.canFreeRewind) ...[
          AppButton(
            label: 'Rewind 3s',
            sublabel: 'Free',
            filled: true,
            onPressed: _busy ? null : () => _withSound(widget.game.rewind)(),
          ),
          const SizedBox(height: 12),
        ] else if (session.canAdRewind) ...[
          AppButton(
            label: 'Rewind 3s',
            sublabel: 'Watch ad · $adRewindsLeft left',
            filled: true,
            onPressed: _busy
                ? null
                : () => _withAd(RewardedPlacement.rewind, _withSound(widget.game.rewind)),
          ),
          const SizedBox(height: 12),
        ],
        if (session.canContinue) ...[
          AppButton(
            label: 'Continue',
            sublabel: 'Watch ad · Keep score',
            onPressed: _busy
                ? null
                : () => _withAd(RewardedPlacement.continueRun, _withSound(widget.game.continueRun)),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.ranked)
          AppButton(
            label: 'End run',
            sublabel: 'Save ranked score',
            onPressed: _busy ? null : widget.onEndRun,
          )
        else ...[
          AppButton(label: 'Play again', onPressed: _busy ? null : widget.onPlayAgain),
          const SizedBox(height: 12),
          AppButton(label: 'Home', compact: true, onPressed: _busy ? null : widget.onHome),
        ],
      ],
    );

    return Scrim(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Palette.retro
              ? content
              : AppCard(padding: const EdgeInsets.fromLTRB(20, 24, 20, 20), child: content),
        ),
      ),
    );
  }
}
