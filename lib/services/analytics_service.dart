import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../core/core.dart';

/// Where analytics events go.
abstract class AnalyticsService {
  Future<void> log(AnalyticsEvent event);
}

/// Firebase Analytics. Only used when Firebase initialised successfully
/// (i.e. the platform config files are present).
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._fa);
  final FirebaseAnalytics _fa;

  @override
  Future<void> log(AnalyticsEvent event) async {
    if (kDebugMode) debugPrint('[analytics] $event');
    try {
      await _fa.logEvent(name: event.name, parameters: event.params);
    } on Object catch (e) {
      debugPrint('[analytics] failed to log ${event.name}: $e');
    }
  }
}

/// Used until Firebase is configured: prints events in debug builds.
class DebugAnalyticsService implements AnalyticsService {
  const DebugAnalyticsService();

  @override
  Future<void> log(AnalyticsEvent event) async {
    if (kDebugMode) debugPrint('[analytics:not-configured] $event');
  }
}

/// Keeps every event. For tests.
class RecordingAnalyticsService implements AnalyticsService {
  final List<AnalyticsEvent> events = [];

  List<String> get names => [for (final e in events) e.name];

  @override
  Future<void> log(AnalyticsEvent event) async => events.add(event);
}
