import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../theme/lcd_theme.dart';
import '../widgets/blink.dart';
import '../widgets/logo_art.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1600), _go);
  }

  void _go() {
    _timer?.cancel();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: _go,
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LogoArt(pixel: 8),
                const SizedBox(height: 28),
                Text(AppConfig.appName.toUpperCase(), style: pixelStyle(28)),
                const SizedBox(height: 16),
                Blink(
                  child: Text(AppConfig.tagline.toUpperCase(),
                      textAlign: TextAlign.center, style: pixelStyle(8, color: LcdPalette.inkMid)),
                ),
              ],
            ),
          ),
        ),
      );
}
