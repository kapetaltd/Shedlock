import 'package:flutter/widgets.dart';

import '../core/core.dart';
import 'ads_service.dart';
import 'analytics_service.dart';
import 'feedback_service.dart';
import 'iap_service.dart';
import 'settings.dart';
import 'share_service.dart';
import 'storage_service.dart';

DateTime _systemNow() => DateTime.now();

/// Gives every screen access to the app's services.
class Services extends InheritedWidget {
  const Services({
    super.key,
    required this.storage,
    required this.ads,
    required this.share,
    required this.analytics,
    required this.iap,
    required this.loadout,
    required this.settings,
    required this.feedback,
    this.clock = _systemNow,
    required super.child,
  });

  final StorageService storage;
  final AdsService ads;
  final ShareService share;
  final AnalyticsService analytics;
  final IapService iap;

  /// The selected cosmetics. Changing it re-themes the app live.
  final ValueNotifier<Loadout> loadout;

  /// Player preferences (sound, haptics, screen shake). Persisted on change.
  final ValueNotifier<GameSettings> settings;

  /// Sound and haptics for game events.
  final FeedbackService feedback;

  /// Current time. Injected so tests can pin the daily date.
  final DateTime Function() clock;

  static Services of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<Services>();
    assert(s != null, 'No Services above this context');
    return s!;
  }

  @override
  bool updateShouldNotify(Services oldWidget) =>
      storage != oldWidget.storage ||
      ads != oldWidget.ads ||
      share != oldWidget.share ||
      analytics != oldWidget.analytics ||
      iap != oldWidget.iap ||
      loadout != oldWidget.loadout ||
      settings != oldWidget.settings ||
      feedback != oldWidget.feedback ||
      clock != oldWidget.clock;
}
