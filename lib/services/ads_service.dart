/// Why a rewarded ad is being shown (also the analytics placement name).
enum RewardedPlacement { rewind, continueRun }

/// Ad interface. Phase 5 adds the AdMob implementation; until then the
/// placeholder below grants rewards immediately so the flow is playable.
abstract class AdsService {
  /// Shows a rewarded ad. Completes with true only if the player earned the
  /// reward.
  Future<bool> showRewarded(RewardedPlacement placement);
}

/// Stand-in until AdMob is wired up: no ad, reward granted after a short
/// delay.
class PlaceholderAdsService implements AdsService {
  const PlaceholderAdsService({this.delay = const Duration(milliseconds: 400)});

  final Duration delay;

  @override
  Future<bool> showRewarded(RewardedPlacement placement) async {
    await Future<void>.delayed(delay);
    return true;
  }
}
