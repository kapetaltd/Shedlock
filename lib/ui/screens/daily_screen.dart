import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../services/daily_service.dart';
import '../format.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/slice_grid.dart';
import 'daily_result_screen.dart';
import 'game_screen.dart';

/// Daily Challenge hub: today's puzzle number, the ranked attempt, result,
/// streak and the countdown to the next puzzle.
class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Refresh the countdown (and roll over to a new day at midnight UTC).
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _play({required bool ranked}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GameScreen(mode: GameMode.daily, ranked: ranked)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _showResult(DailyRecord record) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => DailyResultScreen(record: record)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final daily = DailyService.of(context);
    final status = daily.status;
    final record = daily.todayRecord;
    final streak = daily.currentStreak;
    final left = daily.untilNextPuzzle;
    String two(int v) => v.toString().padLeft(2, '0');
    final countdown =
        '${two(left.inHours)}:${two(left.inMinutes % 60)}:${two(left.inSeconds % 60)}';

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
                  Txt('Daily', role: TextRole.heading, color: Palette.inkMid),
                  SizedBox(height: Palette.retro ? 10 : 0),
                  FittedBox(child: Text(say(dailyTag(daily.todayNumber)), style: textStyle(TextRole.display))),
                  SizedBox(height: Palette.retro ? 10 : 4),
                  Txt('${daily.todayKey} UTC', role: TextRole.caption),
                  const SizedBox(height: 24),
                  Txt(
                    streak > 0 ? 'Streak $streak  ·  Best ${daily.bestStreak}' : 'No streak yet',
                    role: TextRole.label,
                  ),
                  const SizedBox(height: 28),
                  ...switch (status) {
                    DailyStatus.available => [
                        Txt(
                          'One ranked attempt.\nSame board for everyone.\nOne free rewind, no ads.',
                          align: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          label: 'Play ranked',
                          filled: true,
                          onPressed: () => _play(ranked: true),
                        ),
                      ],
                    DailyStatus.completed => [
                        Text(formatScore(record!.score), style: textStyle(TextRole.title, size: Palette.retro ? 28 : 40)),
                        const SizedBox(height: 14),
                        SliceGrid(slices: record.slices, cell: 26),
                        const SizedBox(height: 24),
                        AppButton(
                          label: 'Share result',
                          filled: true,
                          onPressed: () => _showResult(record),
                        ),
                        const SizedBox(height: 14),
                        AppButton(
                          label: 'Practice',
                          sublabel: 'Unranked',
                          onPressed: () => _play(ranked: false),
                        ),
                      ],
                    DailyStatus.abandoned => [
                        Txt(
                          'Ranked attempt\nnot finished',
                          role: TextRole.label,
                          align: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          label: 'Practice',
                          sublabel: 'Unranked',
                          filled: true,
                          onPressed: () => _play(ranked: false),
                        ),
                      ],
                  },
                  const SizedBox(height: 28),
                  Txt('Next puzzle in $countdown', role: TextRole.caption),
                  const SizedBox(height: 20),
                  AppButton(label: 'Back', compact: true, onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
