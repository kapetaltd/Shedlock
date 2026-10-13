import 'package:flutter/widgets.dart';

import '../config/monetization_config.dart';
import '../core/core.dart';
import 'ads_service.dart';
import 'analytics_service.dart';
import 'iap_service.dart';
import 'services.dart';
import 'storage_service.dart';

/// Applies the ad rules on top of the raw [AdsService]: interstitial
/// pacing, Remove Ads, and analytics for every ad.
class AdCoordinator {
  AdCoordinator({
    required this.ads,
    required this.storage,
    required this.analytics,
    required this.iap,
    this.policy = MonetizationConfig.interstitialPolicy,
  });

  factory AdCoordinator.of(BuildContext context) {
    final s = Services.of(context);
    return AdCoordinator(ads: s.ads, storage: s.storage, analytics: s.analytics, iap: s.iap);
  }

  final AdsService ads;
  final StorageService storage;
  final AnalyticsService analytics;
  final IapService iap;
  final InterstitialPolicy policy;

  bool get removeAdsOwned => iap.owned.value.contains(Pack.removeAds);

  /// Player-initiated rewarded ad. True if the reward was earned.
  Future<bool> rewarded(RewardedPlacement placement) async {
    final earned = await ads.showRewarded(placement);
    // Only count ads that actually appeared: "no fill" returns false
    // immediately and is reported to the player instead.
    if (earned) {
      await analytics.log(Events.adShown(AdType.rewarded, placement: placement.name));
      await analytics.log(Events.adRewarded(placement: placement.name));
    }
    return earned;
  }

  /// Call once per finished run (any mode).
  Future<void> onRunCompleted() =>
      storage.setRunsSinceInterstitial(storage.runsSinceInterstitial + 1);

  /// Call at a run-to-menu transition (never during play). Shows an
  /// interstitial only if every rule allows it.
  Future<void> maybeShowInterstitial({bool comingFromDailyShare = false}) async {
    final allowed = policy.shouldShow(
      sessionNumber: storage.sessionCount,
      completedRunsSinceLastInterstitial: storage.runsSinceInterstitial,
      removeAdsOwned: removeAdsOwned,
      comingFromDailyShare: comingFromDailyShare,
      inGameplay: false,
    );
    if (!allowed) return;
    if (await ads.showInterstitial()) {
      await storage.setRunsSinceInterstitial(0);
      await analytics.log(Events.adShown(AdType.interstitial, placement: 'run_end'));
    }
  }
}
