import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../services/daily_service.dart';
import '../../services/services.dart';
import '../format.dart';
import '../theme/lcd_theme.dart';
import '../widgets/lcd_button.dart';
import '../widgets/slice_grid.dart';
import 'game_screen.dart';

/// Shown when the ranked daily ends (and from the daily hub afterwards).
class DailyResultScreen extends StatelessWidget {
  const DailyResultScreen({super.key, required this.record});

  final DailyRecord record;

  @override
  Widget build(BuildContext context) {
    final daily = DailyService.of(context);
    final share = Services.of(context).share;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('SHEDLOCK #${record.dailyNumber}', style: pixelStyle(16)),
                  const SizedBox(height: 22),
                  Text(formatScore(record.score), style: pixelStyle(36)),
                  const SizedBox(height: 6),
                  Text('POINTS', style: pixelStyle(8, color: LcdPalette.inkMid)),
                  const SizedBox(height: 20),
                  SliceGrid(slices: record.slices, cell: 30),
                  const SizedBox(height: 20),
                  Text(
                    'FOOD ${record.foodEaten}  LOCKS ${record.locks}  SHEDS ${record.sheds}'
                    '${record.rewindsUsed > 0 ? '  REWINDS ${record.rewindsUsed}' : ''}',
                    textAlign: TextAlign.center,
                    style: pixelStyle(8, height: 1.8),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'STREAK ${daily.currentStreak}  ·  BEST ${daily.bestStreak}',
                    style: pixelStyle(10),
                  ),
                  const SizedBox(height: 28),
                  LcdButton(
                    label: 'SHARE',
                    filled: true,
                    onPressed: () {
                      Services.of(context).analytics.log(Events.dailyShared(record.dailyNumber));
                      share.shareText(record.shareText);
                    },
                  ),
                  const SizedBox(height: 14),
                  LcdButton(
                    label: 'PRACTICE',
                    sublabel: 'UNRANKED',
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const GameScreen(mode: GameMode.daily, ranked: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  LcdButton(
                    label: 'DONE',
                    fontSize: 12,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
