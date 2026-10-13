import '../monetization/catalog.dart';
import '../run/run_result.dart';
import '../run/run_session.dart';

/// One analytics event. Names and parameters follow Firebase's limits
/// (snake_case, ≤40 chars, string or number values).
class AnalyticsEvent {
  const AnalyticsEvent(this.name, [this.params = const {}]);
  final String name;
  final Map<String, Object> params;

  @override
  String toString() => '$name $params';
}

enum AdType { rewarded, interstitial }

/// Builders for every event the app logs, so names and parameters are
/// defined (and tested) in one place.
class Events {
  /// Firebase reserves `session_start` for its own automatic event (custom
  /// events with reserved names are dropped), so ours is prefixed. It uses
  /// the game's own session rule (30 min in background), which D1/D7
  /// cohorts can be built on.
  static const sessionStart = AnalyticsEvent('game_session_start');

  static AnalyticsEvent runStart(GameMode mode, {required bool ranked}) =>
      AnalyticsEvent('run_start', {'mode': _mode(mode, ranked)});

  static AnalyticsEvent runEnd(RunResult r, {required int realDurationMs}) => AnalyticsEvent(
        'run_end',
        {
          'mode': _mode(r.mode, r.ranked),
          'score': r.score,
          'duration': (realDurationMs / 1000).round(),
          'sheds': r.sheds,
          'locks': r.locks,
          'rewinds_used': r.rewindsUsed,
        },
      );

  static AnalyticsEvent dailyShared(int dailyNumber) =>
      AnalyticsEvent('daily_shared', {'daily_number': dailyNumber});

  static AnalyticsEvent adShown(AdType type, {required String placement}) =>
      AnalyticsEvent('ad_shown', {'type': type.name, 'placement': placement});

  static AnalyticsEvent adRewarded({required String placement}) =>
      AnalyticsEvent('ad_rewarded', {'placement': placement});

  static AnalyticsEvent iapPurchase(Pack pack, {required String productId}) =>
      AnalyticsEvent('iap_purchase', {'pack': pack.name, 'product_id': productId});

  static AnalyticsEvent streakLength(int length) =>
      AnalyticsEvent('streak_length', {'length': length});

  static String _mode(GameMode mode, bool ranked) => switch (mode) {
        GameMode.endless => 'endless',
        GameMode.daily => ranked ? 'daily_ranked' : 'daily_practice',
      };
}
