import 'package:flutter/foundation.dart';

import '../core/monetization/ad_policy.dart';
import '../core/monetization/catalog.dart';

/// Every ad unit ID and store product ID in the app.
///
/// The ad IDs below are Google's official TEST IDs. They always fill and
/// never pay out. Before release, replace them with your own AdMob IDs, and
/// replace the AdMob *app* IDs in the two native files noted below (the SDK
/// reads those before any Dart code runs, so they can't live here):
///   - android/app/build.gradle.kts → manifestPlaceholders["admobAppId"]
///   - ios/Runner/Info.plist        → GADApplicationIdentifier
class MonetizationConfig {
  // --- AdMob app IDs (reference copy of the native values) -----------------
  static const androidAdMobAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const iosAdMobAppId = 'ca-app-pub-3940256099942544~1458002511';

  // --- Ad units ---------------------------------------------------------------
  static const _androidRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const _iosRewarded = 'ca-app-pub-3940256099942544/1712485313';
  static const _androidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _iosInterstitial = 'ca-app-pub-3940256099942544/4411468910';

  static String get rewardedUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS ? _iosRewarded : _androidRewarded;

  static String get interstitialUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS ? _iosInterstitial : _androidInterstitial;

  // --- In-app products (create these in Play Console / App Store Connect) ----
  /// All non-consumable (one-time) purchases.
  static const productIds = <Pack, String>{
    Pack.removeAds: 'shedlock_remove_ads',
    Pack.skins: 'shedlock_pack_skins',
    Pack.trails: 'shedlock_pack_trails',
    Pack.themes: 'shedlock_pack_themes',
  };

  static Pack? packForProduct(String productId) {
    for (final e in productIds.entries) {
      if (e.value == productId) return e.key;
    }
    return null;
  }

  // --- Ad frequency ------------------------------------------------------------
  static const interstitialPolicy = InterstitialPolicy(runsBetween: 3, graceSessions: 2);
  static const sessionRules = SessionRules(timeout: Duration(minutes: 30));
}
