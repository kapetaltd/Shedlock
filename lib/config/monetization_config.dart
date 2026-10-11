import 'package:flutter/foundation.dart';

import '../core/monetization/ad_policy.dart';
import '../core/monetization/catalog.dart';

/// Every ad unit ID and store product ID in the app.
///
/// Ads: debug and profile builds always use Google's official TEST ad
/// units (they always fill and never pay), so nobody can tap a real ad while
/// developing, which can get an AdMob account banned. Only release builds
/// use Kapeta's live units, and only once they are filled in below; an empty
/// live ID falls back to the test unit.
///
/// The AdMob *app* IDs also live in two native files (the SDK reads them
/// before any Dart code runs); a test checks they match the copies here:
///   - android/app/build.gradle.kts → manifestPlaceholders["admobAppId"]
///   - ios/Runner/Info.plist        → GADApplicationIdentifier
class MonetizationConfig {
  // --- AdMob app IDs (reference copy of the native values) -----------------
  /// Kapeta's AdMob app "Shedlock" (Android).
  static const androidAdMobAppId = 'ca-app-pub-1575340671876931~5932306262';

  /// Google's test app ID until Shedlock is added to AdMob for iOS.
  static const iosAdMobAppId = 'ca-app-pub-3940256099942544~1458002511';

  // --- Live ad units (Kapeta's AdMob account) ------------------------------
  static const androidRewardedLive = ''; // TODO: "Shedlock Android Rewarded"
  static const androidInterstitialLive = ''; // TODO: "Shedlock Android Interstitial"
  static const iosRewardedLive = '';
  static const iosInterstitialLive = '';

  // --- Google's test ad units --------------------------------------------------
  static const _androidRewardedTest = 'ca-app-pub-3940256099942544/5224354917';
  static const _iosRewardedTest = 'ca-app-pub-3940256099942544/1712485313';
  static const _androidInterstitialTest = 'ca-app-pub-3940256099942544/1033173712';
  static const _iosInterstitialTest = 'ca-app-pub-3940256099942544/4411468910';

  static bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  /// The live unit in release builds (when set), otherwise the test unit.
  static String pickUnit({required String live, required String test, bool release = kReleaseMode}) =>
      release && live.isNotEmpty ? live : test;

  static String get rewardedUnitId => _ios
      ? pickUnit(live: iosRewardedLive, test: _iosRewardedTest)
      : pickUnit(live: androidRewardedLive, test: _androidRewardedTest);

  static String get interstitialUnitId => _ios
      ? pickUnit(live: iosInterstitialLive, test: _iosInterstitialTest)
      : pickUnit(live: androidInterstitialLive, test: _androidInterstitialTest);

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
