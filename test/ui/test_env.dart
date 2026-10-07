import 'package:flutter/widgets.dart';
import 'package:shedlock/app.dart';
import 'package:shedlock/services/ads_service.dart';
import 'package:shedlock/services/analytics_service.dart';
import 'package:shedlock/services/iap_service.dart';
import 'package:shedlock/services/share_service.dart';
import 'package:shedlock/services/storage_service.dart';

/// Fake services for widget tests, all inspectable.
class TestEnv {
  TestEnv({MemoryStorageService? storage, this.now, int sessions = 1})
      : storage = (storage ?? MemoryStorageService())..sessionCount = sessions {
    iap = FakeIapService(storage: this.storage, analytics: analytics)..init();
  }

  final MemoryStorageService storage;
  final ads = PlaceholderAdsService(delay: Duration.zero);
  final share = FakeShareService();
  final analytics = RecordingAnalyticsService();
  late final FakeIapService iap;
  final DateTime? now;

  Widget app(Widget home) => ShedlockApp(
        storage: storage,
        ads: ads,
        share: share,
        analytics: analytics,
        iap: iap,
        clock: now == null ? null : () => now!,
        home: home,
      );
}
