/// The interstitial rules, as one pure function.
///
/// - never during play (callers only ask at a run-to-menu transition, and
///   [inGameplay] guards against mistakes);
/// - at most one per [runsBetween] completed runs;
/// - never right after the daily share screen;
/// - never in the player's first [graceSessions] sessions;
/// - never for players who bought Remove Ads.
class InterstitialPolicy {
  const InterstitialPolicy({this.runsBetween = 3, this.graceSessions = 2});

  final int runsBetween;
  final int graceSessions;

  bool shouldShow({
    required int sessionNumber,
    required int completedRunsSinceLastInterstitial,
    required bool removeAdsOwned,
    required bool comingFromDailyShare,
    required bool inGameplay,
  }) =>
      !inGameplay &&
      !removeAdsOwned &&
      !comingFromDailyShare &&
      sessionNumber > graceSessions &&
      completedRunsSinceLastInterstitial >= runsBetween;
}

/// When does an app launch or resume count as a new session?
class SessionRules {
  const SessionRules({this.timeout = const Duration(minutes: 30)});

  /// Background time after which coming back starts a new session.
  final Duration timeout;

  bool isNewSession({required DateTime? lastActive, required DateTime now}) =>
      lastActive == null || now.difference(lastActive) >= timeout;
}
