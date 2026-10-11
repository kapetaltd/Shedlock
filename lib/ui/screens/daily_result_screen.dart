import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../services/daily_service.dart';
import '../../services/services.dart';
import '../format.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
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
                  Txt('Shedlock #${record.dailyNumber}', role: TextRole.heading),
                  SizedBox(height: Palette.retro ? 22 : 12),
                  Text(formatScore(record.score), style: textStyle(TextRole.display)),
                  const SizedBox(height: 6),
                  Txt('Points', role: TextRole.caption),
                  const SizedBox(height: 20),
                  SliceGrid(slices: record.slices, cell: 30),
                  const SizedBox(height: 20),
                  Txt(
                    'Food ${record.foodEaten}  ·  Locks ${record.locks}  ·  Sheds ${record.sheds}'
                    '${record.rewindsUsed > 0 ? '  ·  Rewinds ${record.rewindsUsed}' : ''}',
                    align: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Txt(
                    'Streak ${daily.currentStreak}  ·  Best ${daily.bestStreak}',
                    role: TextRole.label,
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: 'Share',
                    filled: true,
                    onPressed: () {
                      Services.of(context).analytics.log(Events.dailyShared(record.dailyNumber));
                      share.shareText(record.shareText);
                    },
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    label: 'Practice',
                    sublabel: 'Unranked',
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const GameScreen(mode: GameMode.daily, ranked: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    label: 'Done',
                    compact: true,
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
