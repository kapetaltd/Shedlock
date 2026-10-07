import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/app_config.dart';
import 'core/core.dart';
import 'services/ads_service.dart';
import 'services/analytics_service.dart';
import 'services/iap_service.dart';
import 'services/services.dart';
import 'services/share_service.dart';
import 'services/storage_service.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/theme/lcd_theme.dart';

class ShedlockApp extends StatefulWidget {
  const ShedlockApp({
    super.key,
    required this.storage,
    required this.ads,
    required this.share,
    required this.analytics,
    required this.iap,
    this.clock,
    this.home = const SplashScreen(),
  });

  final StorageService storage;
  final AdsService ads;
  final ShareService share;
  final AnalyticsService analytics;
  final IapService iap;

  /// Overrides the current time (tests).
  final DateTime Function()? clock;
  final Widget home;

  @override
  State<ShedlockApp> createState() => _ShedlockAppState();
}

class _ShedlockAppState extends State<ShedlockApp> {
  late final ValueNotifier<Loadout> _loadout;

  @override
  void initState() {
    super.initState();
    _loadout = ValueNotifier(widget.storage.loadout.restrictTo(widget.iap.owned.value));
    _loadout.addListener(_onLoadoutChanged);
    widget.iap.owned.addListener(_onOwnedChanged);
    LcdPalette.apply(_loadout.value.theme);
  }

  void _onLoadoutChanged() {
    widget.storage.setLoadout(_loadout.value);
    final theme = _loadout.value.theme;
    if (LcdPalette.active == LcdPalette.themes[theme]) return;
    LcdPalette.apply(theme);
    // Palette colours are read at build time everywhere, so rebuild the
    // whole tree in place (navigation state is kept).
    void rebuild(Element e) {
      e.markNeedsBuild();
      e.visitChildren(rebuild);
    }

    if (mounted) (context as Element).visitChildren(rebuild);
    setState(() {});
  }

  // A refunded pack falls back to the free cosmetics.
  void _onOwnedChanged() => _loadout.value = _loadout.value.restrictTo(widget.iap.owned.value);

  @override
  void dispose() {
    widget.iap.owned.removeListener(_onOwnedChanged);
    _loadout.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = _loadout.value.theme == BoardTheme.night;
    return Services(
      storage: widget.storage,
      ads: widget.ads,
      share: widget.share,
      analytics: widget.analytics,
      iap: widget.iap,
      loadout: _loadout,
      clock: widget.clock ?? DateTime.now,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: buildLcdTheme(),
          home: widget.home,
        ),
      ),
    );
  }
}
