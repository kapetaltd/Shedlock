import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../core/core.dart';
import '../../services/daily_service.dart';
import '../../services/services.dart';
import '../format.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/logo_art.dart';
import 'daily_screen.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // The daily puzzle (and streak) can roll over while the app is in the
  // background; refresh when coming back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

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
      DailyStatus.available => '${dailyTag(daily.todayNumber)} · Play',
      DailyStatus.completed => '${dailyTag(daily.todayNumber)} · ${formatScore(daily.todayRecord!.score)} pts',
      DailyStatus.abandoned => '${dailyTag(daily.todayNumber)} · Practice',
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
                  const LogoArt(size: 132),
                  SizedBox(height: Palette.retro ? 20 : 12),
                  FittedBox(child: Txt(AppConfig.appName, role: TextRole.hero)),
                  SizedBox(height: Palette.retro ? 12 : 6),
                  Txt(AppConfig.tagline, role: TextRole.caption, align: TextAlign.center),
                  const SizedBox(height: 36),
                  AppButton(
                    label: 'Daily',
                    sublabel: streak > 0 ? '$dailySub · Streak $streak' : dailySub,
                    filled: daily.status == DailyStatus.available,
                    onPressed: () => _open(const DailyScreen()),
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    label: 'Endless',
                    sublabel: best > 0 ? 'Best ${formatScore(best)}' : null,
                    filled: daily.status != DailyStatus.available,
                    onPressed: () => _open(const GameScreen()),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Shop',
                          compact: true,
                          onPressed: () => _open(const ShopScreen()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'Settings',
                          compact: true,
                          onPressed: () => _open(const SettingsScreen()),
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
