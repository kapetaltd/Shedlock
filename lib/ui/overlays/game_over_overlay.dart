import 'dart:async';

import 'package:flutter/material.dart';

import '../../game/shedlock_game.dart';
import '../../services/ads_service.dart';
import '../../services/ad_coordinator.dart';
import '../format.dart';
import '../theme/lcd_theme.dart';
import '../widgets/lcd_button.dart';

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
      if (!earned) _adMessage = 'NO AD RIGHT NOW. TRY AGAIN SOON.';
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

    return ColoredBox(
      color: LcdPalette.screen.withValues(alpha: 0.82),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('GAME OVER', style: pixelStyle(20)),
                const SizedBox(height: 18),
                Text(formatScore(s.score), style: pixelStyle(32)),
                const SizedBox(height: 8),
                Text(isBest ? 'NEW BEST!' : 'BEST ${formatScore(widget.game.best)}',
                    style: pixelStyle(10, color: LcdPalette.inkMid)),
                const SizedBox(height: 14),
                Text(
                  'FOOD ${s.foodEaten}  LOCKS ${s.locks}  SHEDS ${s.sheds}',
                  textAlign: TextAlign.center,
                  style: pixelStyle(8),
                ),
                const SizedBox(height: 24),
                if (_adMessage != null) ...[
                  Text(_adMessage!, textAlign: TextAlign.center, style: pixelStyle(8)),
                  const SizedBox(height: 12),
                ],
                if (session.canFreeRewind) ...[
                  LcdButton(
                    label: 'REWIND 3S',
                    sublabel: 'FREE',
                    filled: true,
                    onPressed: _busy ? null : () => widget.game.rewind(),
                  ),
                  const SizedBox(height: 12),
                ] else if (session.canAdRewind) ...[
                  LcdButton(
                    label: 'REWIND 3S',
                    sublabel: 'WATCH AD · $adRewindsLeft LEFT',
                    filled: true,
                    onPressed: _busy
                        ? null
                        : () => _withAd(RewardedPlacement.rewind, widget.game.rewind),
                  ),
                  const SizedBox(height: 12),
                ],
                if (session.canContinue) ...[
                  LcdButton(
                    label: 'CONTINUE',
                    sublabel: 'WATCH AD · KEEP SCORE',
                    onPressed: _busy
                        ? null
                        : () => _withAd(RewardedPlacement.continueRun, widget.game.continueRun),
                  ),
                  const SizedBox(height: 12),
                ],
                if (widget.ranked)
                  LcdButton(
                    label: 'END RUN',
                    sublabel: 'SAVE RANKED SCORE',
                    onPressed: _busy ? null : widget.onEndRun,
                  )
                else ...[
                  LcdButton(label: 'PLAY AGAIN', onPressed: _busy ? null : widget.onPlayAgain),
                  const SizedBox(height: 12),
                  LcdButton(label: 'HOME', fontSize: 12, onPressed: _busy ? null : widget.onHome),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
