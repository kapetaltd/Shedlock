import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'services/ads_service.dart';
import 'services/services.dart';
import 'services/storage_service.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/theme/lcd_theme.dart';

class ShedlockApp extends StatelessWidget {
  const ShedlockApp({
    super.key,
    required this.storage,
    required this.ads,
    this.home = const SplashScreen(),
  });

  final StorageService storage;
  final AdsService ads;
  final Widget home;

  @override
  Widget build(BuildContext context) => Services(
        storage: storage,
        ads: ads,
        child: MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: buildLcdTheme(),
          home: home,
        ),
      );
}
