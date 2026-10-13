import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/core/core.dart';
import 'package:shedlock/services/ad_coordinator.dart';
import 'package:shedlock/services/ads_service.dart';
import 'package:shedlock/services/analytics_service.dart';
import 'package:shedlock/services/iap_service.dart';
import 'package:shedlock/services/session_service.dart';
import 'package:shedlock/services/storage_service.dart';

class Rig {
  Rig({int sessions = 3, bool fill = true}) {
    storage.sessionCount = sessions;
    ads = PlaceholderAdsService(delay: Duration.zero, fill: fill);
    iap = FakeIapService(storage: storage, analytics: analytics);
    coord = AdCoordinator(ads: ads, storage: storage, analytics: analytics, iap: iap);
  }

  final storage = MemoryStorageService();
  final analytics = RecordingAnalyticsService();
  late final PlaceholderAdsService ads;
  late final FakeIapService iap;
  late final AdCoordinator coord;

  Future<void> finishRuns(int n, {bool fromShare = false}) async {
    for (var i = 0; i < n; i++) {
      await coord.onRunCompleted();
      await coord.maybeShowInterstitial(comingFromDailyShare: fromShare);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdCoordinator', () {
    test('one interstitial per 3 finished runs, logged as ad_shown', () async {
      final r = Rig();
      await r.finishRuns(2);
      expect(r.ads.interstitialsShown, 0);
      await r.finishRuns(1);
      expect(r.ads.interstitialsShown, 1);
      expect(r.storage.runsSinceInterstitial, 0);
      await r.finishRuns(5);
      expect(r.ads.interstitialsShown, 2);
      expect(r.analytics.names.where((n) => n == 'ad_shown'), hasLength(2));
    });

    test('nothing in the first 2 sessions', () async {
      final r = Rig(sessions: 2);
      await r.finishRuns(9);
      expect(r.ads.interstitialsShown, 0);
    });

    test('Remove Ads stops interstitials but rewarded ads still work', () async {
      final r = Rig();
      await r.iap.init();
      await r.iap.buy(Pack.removeAds);
      await r.finishRuns(9);
      expect(r.ads.interstitialsShown, 0);
      expect(await r.coord.rewarded(RewardedPlacement.rewind), isTrue);
      expect(r.ads.rewardedShown, 1);
    });

    test('not when leaving the daily share screen', () async {
      final r = Rig()..storage.runsSinceInterstitial = 5;
      await r.coord.maybeShowInterstitial(comingFromDailyShare: true);
      expect(r.ads.interstitialsShown, 0);
    });

    test('rewarded: logs ad_shown + ad_rewarded only when earned', () async {
      final ok = Rig();
      expect(await ok.coord.rewarded(RewardedPlacement.continueRun), isTrue);
      expect(ok.analytics.names, ['ad_shown', 'ad_rewarded']);
      expect(ok.analytics.events.last.params, {'placement': 'continueRun'});

      final noFill = Rig(fill: false);
      expect(await noFill.coord.rewarded(RewardedPlacement.rewind), isFalse);
      expect(noFill.analytics.events, isEmpty);
    });
  });

  group('FakeIapService', () {
    test('buying grants, persists and logs iap_purchase once', () async {
      final r = Rig();
      await r.iap.init();
      expect(r.iap.offers.value[Pack.skins]!.available, isTrue);
      await r.iap.buy(Pack.skins);
      await r.iap.buy(Pack.skins);
      expect(r.iap.owned.value, {Pack.skins});
      expect(r.storage.ownedPacks, {Pack.skins});
      expect(r.analytics.names, ['iap_purchase']);
    });

    test('ownership survives a restart (read from storage)', () async {
      final r = Rig()..storage.ownedPacks = {Pack.themes};
      final again = FakeIapService(storage: r.storage, analytics: r.analytics);
      expect(again.owned.value, {Pack.themes});
    });
  });

  group('SessionService', () {
    test('counts a session on start and after 30 minutes away', () async {
      final storage = MemoryStorageService();
      final analytics = RecordingAnalyticsService();
      var now = DateTime.utc(2026, 10, 7, 9);
      final s = SessionService(storage: storage, analytics: analytics, clock: () => now);
      await s.start();
      expect(storage.sessionCount, 1);
      expect(analytics.names, ['game_session_start']);

      now = now.add(const Duration(minutes: 10));
      s.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 5));
      s.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(storage.sessionCount, 1, reason: 'short break');

      s.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 45));
      s.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(storage.sessionCount, 2);
      expect(analytics.names, ['game_session_start', 'game_session_start']);
    });
  });
}
