import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/core/core.dart';

void main() {
  group('interstitial policy', () {
    const policy = InterstitialPolicy(runsBetween: 3, graceSessions: 2);
    bool show({
      int session = 3,
      int runs = 3,
      bool removeAds = false,
      bool fromShare = false,
      bool playing = false,
    }) =>
        policy.shouldShow(
          sessionNumber: session,
          completedRunsSinceLastInterstitial: runs,
          removeAdsOwned: removeAds,
          comingFromDailyShare: fromShare,
          inGameplay: playing,
        );

    test('shows once every rule allows it', () => expect(show(), isTrue));
    test('never in the first 2 sessions', () {
      expect(show(session: 1), isFalse);
      expect(show(session: 2), isFalse);
      expect(show(session: 3), isTrue);
    });
    test('at most one every 3 completed runs', () {
      expect(show(runs: 0), isFalse);
      expect(show(runs: 2), isFalse);
      expect(show(runs: 3), isTrue);
      expect(show(runs: 7), isTrue);
    });
    test('never during play', () => expect(show(playing: true), isFalse));
    test('never right after the daily share screen', () => expect(show(fromShare: true), isFalse));
    test('Remove Ads turns interstitials off', () => expect(show(removeAds: true), isFalse));
  });

  group('session rules', () {
    const rules = SessionRules(timeout: Duration(minutes: 30));
    final t0 = DateTime.utc(2026, 10, 7, 12);
    test('first launch is a new session', () {
      expect(rules.isNewSession(lastActive: null, now: t0), isTrue);
    });
    test('coming back within 30 minutes continues the session', () {
      expect(rules.isNewSession(lastActive: t0, now: t0.add(const Duration(minutes: 29))), isFalse);
    });
    test('30+ minutes away starts a new one', () {
      expect(rules.isNewSession(lastActive: t0, now: t0.add(const Duration(minutes: 30))), isTrue);
    });
  });

  group('cosmetics', () {
    test('every paid item belongs to a pack; free defaults have none', () {
      expect(SnakeSkin.classic.pack, isNull);
      expect(Trail.none.pack, isNull);
      expect(BoardTheme.lime.pack, isNull);
      for (final s in SnakeSkin.values.skip(1)) {
        expect(s.pack, Pack.skins);
      }
      for (final t in Trail.values.skip(1)) {
        expect(t.pack, Pack.trails);
      }
      for (final b in BoardTheme.values.skip(1)) {
        expect(b.pack, Pack.themes);
      }
    });

    test('items from packs the player no longer owns fall back to free ones', () {
      const l = Loadout(skin: SnakeSkin.hollow, trail: Trail.dust, theme: BoardTheme.night);
      final r = l.restrictTo({Pack.trails});
      expect((r.skin, r.trail, r.theme), (SnakeSkin.classic, Trail.dust, BoardTheme.lime));
      expect(identical(l.restrictTo(Pack.values.toSet()).skin, SnakeSkin.hollow), isTrue);
    });

    test('loadout json round trip, tolerant of unknown names', () {
      const l = Loadout(skin: SnakeSkin.dotted, trail: Trail.ghost, theme: BoardTheme.amber);
      final back = Loadout.fromJson(l.toJson());
      expect((back.skin, back.trail, back.theme), (l.skin, l.trail, l.theme));
      final junk = Loadout.fromJson({'skin': 'rainbow', 'theme': 7});
      expect((junk.skin, junk.trail, junk.theme), (SnakeSkin.classic, Trail.none, BoardTheme.lime));
    });
  });

  group('analytics events', () {
    final result = RunResult(
      mode: GameMode.daily,
      ranked: true,
      seed: 1,
      dailyNumber: 7,
      score: 1240,
      foodEaten: 37,
      sheds: 5,
      locks: 3,
      rewindsUsed: 1,
      continuesUsed: 0,
      simDurationMs: 61000,
      timeline: const [],
    );

    test('names and parameters match the spec', () {
      expect(Events.sessionStart.name, 'game_session_start');
      expect(Events.runStart(GameMode.endless, ranked: false).params, {'mode': 'endless'});
      final end = Events.runEnd(result, realDurationMs: 65400);
      expect(end.name, 'run_end');
      expect(end.params, {
        'mode': 'daily_ranked',
        'score': 1240,
        'duration': 65,
        'sheds': 5,
        'locks': 3,
        'rewinds_used': 1,
      });
      expect(Events.dailyShared(7).name, 'daily_shared');
      expect(Events.adShown(AdType.interstitial, placement: 'run_end').params,
          {'type': 'interstitial', 'placement': 'run_end'});
      expect(Events.adRewarded(placement: 'rewind').name, 'ad_rewarded');
      expect(Events.iapPurchase(Pack.skins, productId: 'x').params, {'pack': 'skins', 'product_id': 'x'});
      expect(Events.streakLength(4).params, {'length': 4});
    });

    test('all names and keys are valid Firebase identifiers', () {
      final valid = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{0,39}$');
      const reserved = {'session_start', 'first_open', 'in_app_purchase', 'screen_view', 'user_engagement'};
      final events = [
        Events.sessionStart,
        Events.runStart(GameMode.daily, ranked: false),
        Events.runEnd(result, realDurationMs: 1),
        Events.dailyShared(1),
        Events.adShown(AdType.rewarded, placement: 'rewind'),
        Events.adRewarded(placement: 'rewind'),
        Events.iapPurchase(Pack.removeAds, productId: 'p'),
        Events.streakLength(1),
      ];
      for (final e in events) {
        expect(valid.hasMatch(e.name), isTrue, reason: e.name);
        expect(reserved.contains(e.name), isFalse, reason: '${e.name} is reserved');
        for (final k in e.params.keys) {
          expect(valid.hasMatch(k), isTrue, reason: k);
        }
      }
    });
  });
}
