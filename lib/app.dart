import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/app_config.dart';
import 'core/core.dart';
import 'services/ads_service.dart';
import 'services/analytics_service.dart';
import 'services/feedback_service.dart';
import 'services/iap_service.dart';
import 'services/services.dart';
import 'services/settings.dart';
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
    required this.sound,
    required this.haptics,
    this.clock,
    this.home = const SplashScreen(),
  });

  final StorageService storage;
  final AdsService ads;
  final ShareService share;
  final AnalyticsService analytics;
  final IapService iap;
  final SoundPlayer sound;
  final Haptics haptics;

  /// Overrides the current time (tests).
  final DateTime Function()? clock;
  final Widget home;

  @override
  State<ShedlockApp> createState() => _ShedlockAppState();
}

class _ShedlockAppState extends State<ShedlockApp> {
  late final ValueNotifier<Loadout> _loadout;
  late final ValueNotifier<GameSettings> _settings;
  late final FeedbackService _feedback;

  @override
  void initState() {
    super.initState();
    _loadout = ValueNotifier(widget.storage.loadout.restrictTo(widget.iap.owned.value));
    _loadout.addListener(_onLoadoutChanged);
    widget.iap.owned.addListener(_onOwnedChanged);
    LcdPalette.apply(_loadout.value.theme);
    _settings = ValueNotifier(widget.storage.settings)
      ..addListener(() => widget.storage.setSettings(_settings.value));
    _feedback = FeedbackService(sound: widget.sound, haptics: widget.haptics, settings: _settings);
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
    _settings.dispose();
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
      settings: _settings,
      feedback: _feedback,
      clock: widget.clock ?? DateTime.now,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: buildLcdTheme(),
          // The pixel font is already large; cap system text scaling so
          // layouts don't overflow, while still honouring the setting.
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: child!,
          ),
          home: widget.home,
        ),
      ),
    );
  }
}
