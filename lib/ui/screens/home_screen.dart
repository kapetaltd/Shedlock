import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../services/services.dart';
import '../format.dart';
import '../theme/lcd_theme.dart';
import '../widgets/lcd_button.dart';
import '../widgets/logo_art.dart';
import 'game_screen.dart';
import 'placeholder_screen.dart';

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
                  const LcdButton(label: 'DAILY', sublabel: 'COMING SOON'),
                  const SizedBox(height: 14),
                  LcdButton(
                    label: 'ENDLESS',
                    sublabel: best > 0 ? 'BEST ${formatScore(best)}' : null,
                    filled: true,
                    onPressed: () => _open(const GameScreen()),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: LcdButton(
                          label: 'SHOP',
                          fontSize: 12,
                          onPressed: () => _open(const PlaceholderScreen(title: 'SHOP')),
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
