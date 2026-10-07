import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'services/ads_service.dart';
import 'services/services.dart';
import 'services/share_service.dart';
import 'services/storage_service.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/theme/lcd_theme.dart';

class ShedlockApp extends StatelessWidget {
  const ShedlockApp({
    super.key,
    required this.storage,
    required this.ads,
    required this.share,
    this.clock,
    this.home = const SplashScreen(),
  });

  final StorageService storage;
  final AdsService ads;
  final ShareService share;

  /// Overrides the current time (tests).
  final DateTime Function()? clock;
  final Widget home;

  @override
  Widget build(BuildContext context) => Services(
        storage: storage,
        ads: ads,
        share: share,
        clock: clock ?? DateTime.now,
        child: MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: buildLcdTheme(),
          home: home,
        ),
      );
}
