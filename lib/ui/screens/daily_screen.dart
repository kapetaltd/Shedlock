import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../services/daily_service.dart';
import '../format.dart';
import '../theme/lcd_theme.dart';
import '../widgets/lcd_button.dart';
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
                  Text('DAILY', style: pixelStyle(12, color: LcdPalette.inkMid)),
                  const SizedBox(height: 10),
                  Text('#${daily.todayNumber}', style: pixelStyle(36)),
                  const SizedBox(height: 10),
                  Text('${daily.todayKey} UTC', style: pixelStyle(8, color: LcdPalette.inkMid)),
                  const SizedBox(height: 24),
                  Text(
                    streak > 0 ? 'STREAK $streak  ·  BEST ${daily.bestStreak}' : 'NO STREAK YET',
                    style: pixelStyle(10),
                  ),
                  const SizedBox(height: 28),
                  ...switch (status) {
                    DailyStatus.available => [
                        Text(
                          'ONE RANKED ATTEMPT.\nSAME BOARD FOR EVERYONE.\nONE FREE REWIND, NO ADS.',
                          textAlign: TextAlign.center,
                          style: pixelStyle(8, height: 2),
                        ),
                        const SizedBox(height: 24),
                        LcdButton(
                          label: 'PLAY RANKED',
                          filled: true,
                          onPressed: () => _play(ranked: true),
                        ),
                      ],
                    DailyStatus.completed => [
                        Text(formatScore(record!.score), style: pixelStyle(28)),
                        const SizedBox(height: 14),
                        SliceGrid(slices: record.slices, cell: 26),
                        const SizedBox(height: 24),
                        LcdButton(
                          label: 'SHARE RESULT',
                          filled: true,
                          onPressed: () => _showResult(record),
                        ),
                        const SizedBox(height: 14),
                        LcdButton(
                          label: 'PRACTICE',
                          sublabel: 'UNRANKED',
                          onPressed: () => _play(ranked: false),
                        ),
                      ],
                    DailyStatus.abandoned => [
                        Text(
                          'RANKED ATTEMPT\nNOT FINISHED',
                          textAlign: TextAlign.center,
                          style: pixelStyle(10, height: 1.8),
                        ),
                        const SizedBox(height: 24),
                        LcdButton(
                          label: 'PRACTICE',
                          sublabel: 'UNRANKED',
                          filled: true,
                          onPressed: () => _play(ranked: false),
                        ),
                      ],
                  },
                  const SizedBox(height: 28),
                  Text('NEXT PUZZLE IN $countdown', style: pixelStyle(8, color: LcdPalette.inkMid)),
                  const SizedBox(height: 20),
                  LcdButton(label: 'BACK', fontSize: 12, onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
