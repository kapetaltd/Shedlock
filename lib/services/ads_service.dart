import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/monetization_config.dart';

/// Why a rewarded ad is being shown (also the analytics placement name).
enum RewardedPlacement { rewind, continueRun }

/// Raw ad SDK access. Pacing rules and analytics live in `AdCoordinator`.
abstract class AdsService {
  Future<void> init();

  /// Shows a rewarded ad. Completes with true only if the reward was earned.
  /// False if no ad is ready or the player closed it early.
  Future<bool> showRewarded(RewardedPlacement placement);

  /// Shows an interstitial if one is loaded. Completes with true if shown,
  /// once it has been dismissed.
  Future<bool> showInterstitial();
}

/// AdMob via google_mobile_ads, with Google's UMP consent flow.
/// Keeps one rewarded and one interstitial preloaded.
class AdMobAdsService implements AdsService {
  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  bool _canRequestAds = false;
  int _rewardedRetries = 0;
  int _interstitialRetries = 0;

  @override
  Future<void> init() async {
    await _gatherConsent();
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    if (!_canRequestAds) return;
    await MobileAds.instance.initialize();
    _loadRewarded();
    _loadInterstitial();
  }

  /// UMP: asks for consent where the law requires it (EEA/UK), no-op
  /// elsewhere. Never blocks startup for more than the form itself.
  Future<void> _gatherConsent() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) debugPrint('[ads] consent form: ${error.message}');
        });
        if (!done.isCompleted) done.complete();
      },
      (error) {
        debugPrint('[ads] consent info: ${error.message}');
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future;
  }

  Duration _backoff(int retries) => Duration(seconds: (2 << retries.clamp(0, 5)));

  void _loadRewarded() {
    if (!_canRequestAds) return;
    RewardedAd.load(
      adUnitId: MonetizationConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedRetries = 0;
          _rewarded = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[ads] rewarded failed to load: ${error.message}');
          _rewarded = null;
          Timer(_backoff(_rewardedRetries++), _loadRewarded);
        },
      ),
    );
  }

  void _loadInterstitial() {
    if (!_canRequestAds) return;
    InterstitialAd.load(
      adUnitId: MonetizationConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialRetries = 0;
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[ads] interstitial failed to load: ${error.message}');
          _interstitial = null;
          Timer(_backoff(_interstitialRetries++), _loadInterstitial);
        },
      ),
    );
  }

  @override
  Future<bool> showRewarded(RewardedPlacement placement) {
    final ad = _rewarded;
    if (ad == null) return Future.value(false);
    _rewarded = null;
    final result = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        if (!result.isCompleted) result.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[ads] rewarded failed to show: ${error.message}');
        ad.dispose();
        _loadRewarded();
        if (!result.isCompleted) result.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (_, _) => earned = true);
    return result.future;
  }

  @override
  Future<bool> showInterstitial() {
    final ad = _interstitial;
    if (ad == null) return Future.value(false);
    _interstitial = null;
    final result = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
        if (!result.isCompleted) result.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[ads] interstitial failed to show: ${error.message}');
        ad.dispose();
        _loadInterstitial();
        if (!result.isCompleted) result.complete(false);
      },
    );
    ad.show();
    return result.future;
  }
}

/// No real ads: used on platforms without AdMob (web) and in tests.
/// Rewarded ads grant the reward after [delay]; interstitials "show" and
/// are counted so tests can assert on pacing.
class PlaceholderAdsService implements AdsService {
  PlaceholderAdsService({this.delay = const Duration(milliseconds: 400), this.fill = true});

  final Duration delay;

  /// False simulates "no ad available".
  final bool fill;
  int interstitialsShown = 0;
  int rewardedShown = 0;

  @override
  Future<void> init() async {}

  @override
  Future<bool> showRewarded(RewardedPlacement placement) async {
    if (!fill) return false;
    rewardedShown++;
    await Future<void>.delayed(delay);
    return true;
  }

  @override
  Future<bool> showInterstitial() async {
    if (!fill) return false;
    interstitialsShown++;
    return true;
  }
}
