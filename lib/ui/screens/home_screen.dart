import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../core/core.dart';
import '../../services/daily_service.dart';
import '../../services/services.dart';
import '../format.dart';
import '../theme/lcd_theme.dart';
import '../widgets/lcd_button.dart';
import '../widgets/logo_art.dart';
import 'daily_screen.dart';
import 'game_screen.dart';
import 'placeholder_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) setState(() {}); // refresh best score
  }

  @override
  Widget build(BuildContext context) {
    final best = Services.of(context).storage.endlessBest;
    final daily = DailyService.of(context);
    final streak = daily.currentStreak;
    final dailySub = switch (daily.status) {
      DailyStatus.available => '#${daily.todayNumber} · PLAY',
      DailyStatus.completed => '#${daily.todayNumber} · ${formatScore(daily.todayRecord!.score)} PTS',
      DailyStatus.abandoned => '#${daily.todayNumber} · PRACTICE',
    };
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
                  const LogoArt(pixel: 6),
                  const SizedBox(height: 20),
                  FittedBox(
                    child: Text(AppConfig.appName.toUpperCase(), style: pixelStyle(32)),
                  ),
                  const SizedBox(height: 12),
                  Text(AppConfig.tagline.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: pixelStyle(8, color: LcdPalette.inkMid)),
                  const SizedBox(height: 36),
                  LcdButton(
                    label: 'DAILY',
                    sublabel: streak > 0 ? '$dailySub · STREAK $streak' : dailySub,
                    filled: daily.status == DailyStatus.available,
                    onPressed: () => _open(const DailyScreen()),
                  ),
                  const SizedBox(height: 14),
                  LcdButton(
                    label: 'ENDLESS',
                    sublabel: best > 0 ? 'BEST ${formatScore(best)}' : null,
                    filled: daily.status != DailyStatus.available,
                    onPressed: () => _open(const GameScreen()),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: LcdButton(
                          label: 'SHOP',
                          fontSize: 12,
                          onPressed: () => _open(const ShopScreen()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LcdButton(
                          label: 'SETTINGS',
                          fontSize: 12,
                          onPressed: () => _open(const PlaceholderScreen(title: 'SETTINGS')),
                        ),
                      ),
                    ],
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
