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
import 'ui/theme/app_theme.dart';

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

class _ShedlockAppState extends State<ShedlockApp> with WidgetsBindingObserver {
  late final ValueNotifier<Loadout> _loadout;
  late final ValueNotifier<GameSettings> _settings;
  late final FeedbackService _feedback;

  @override
  void initState() {
    super.initState();
    _loadout = ValueNotifier(widget.storage.loadout.restrictTo(widget.iap.owned.value));
    _loadout.addListener(_onLoadoutChanged);
    widget.iap.owned.addListener(_onOwnedChanged);
    Palette.apply(_loadout.value.theme, systemDark: _systemDark);
    WidgetsBinding.instance.addObserver(this);
    _settings = ValueNotifier(widget.storage.settings)
      ..addListener(() => widget.storage.setSettings(_settings.value));
    _feedback = FeedbackService(sound: widget.sound, haptics: widget.haptics, settings: _settings);
  }

  bool get _systemDark =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;

  void _onLoadoutChanged() {
    widget.storage.setLoadout(_loadout.value);
    _applyTheme();
  }

  // "Auto" follows the device's dark mode, live.
  @override
  void didChangePlatformBrightness() => _applyTheme();

  void _applyTheme() {
    if (!Palette.apply(_loadout.value.theme, systemDark: _systemDark)) return;
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
    WidgetsBinding.instance.removeObserver(this);
    widget.iap.owned.removeListener(_onOwnedChanged);
    _loadout.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Palette.dark;
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
          theme: buildAppTheme(),
          // Cap system text scaling so layouts don't overflow, while still
          // honouring the setting (the pixel font is already large).
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            maxScaleFactor: Palette.retro ? 1.3 : 1.4,
            child: child!,
          ),
          home: widget.home,
        ),
      ),
    );
  }
}
