import 'package:flutter/widgets.dart';

import '../config/monetization_config.dart';
import '../core/core.dart';
import 'analytics_service.dart';
import 'storage_service.dart';

/// Counts sessions (cold start, or returning after 30+ minutes in the
/// background) and logs `game_session_start`. The count drives the
/// "no interstitials in the first 2 sessions" rule.
class SessionService with WidgetsBindingObserver {
  SessionService({
    required this.storage,
    required this.analytics,
    required this.clock,
    this.rules = MonetizationConfig.sessionRules,
  });

  final StorageService storage;
  final AnalyticsService analytics;
  final DateTime Function() clock;
  final SessionRules rules;

  /// Call once at startup.
  Future<void> start() async {
    await _maybeNewSession();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _maybeNewSession() async {
    final now = clock().toUtc();
    if (rules.isNewSession(lastActive: storage.lastActiveAt, now: now)) {
      await storage.setSessionCount(storage.sessionCount + 1);
      await analytics.log(Events.sessionStart);
    }
    await storage.setLastActiveAt(now);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _maybeNewSession();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        storage.setLastActiveAt(clock().toUtc());
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }
}
