import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/core/core.dart';
import 'package:shedlock/game/shedlock_game.dart';
import 'package:shedlock/services/storage_service.dart';
import 'package:shedlock/ui/screens/game_screen.dart';
import 'package:shedlock/ui/screens/shop_screen.dart';
import 'package:shedlock/ui/theme/lcd_theme.dart';

import 'test_env.dart';

ShedlockGame gameOf(WidgetTester tester) => tester
    .widget<GameWidget<ShedlockGame>>(find.byType(GameWidget<ShedlockGame>))
    .game!;

Future<void> playAndDie(WidgetTester tester) async {
  final game = gameOf(tester);
  game.turn(Direction.left);
  for (var i = 0; i < 80 && game.phase.value != PlayPhase.over; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(game.phase.value, PlayPhase.over);
  await tester.pump(const Duration(seconds: 1));
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  setUp(() => LcdPalette.apply(BoardTheme.lime));

  testWidgets('endless: run events logged; interstitial after the 3rd run in session 3',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    final env = TestEnv(sessions: 3);
    await tester.pumpWidget(env.app(const GameScreen(seed: 4)));
    await tester.pump();

    for (var run = 1; run <= 3; run++) {
      await playAndDie(tester);
      await tapText(tester, 'PLAY AGAIN');
      expect(env.ads.interstitialsShown, run == 3 ? 1 : 0, reason: 'after run $run');
    }
    final names = env.analytics.names;
    expect(names.where((n) => n == 'run_start'), hasLength(3));
    expect(names.where((n) => n == 'run_end'), hasLength(3));
    final end = env.analytics.events.firstWhere((e) => e.name == 'run_end');
    expect(end.params.keys, containsAll(['mode', 'score', 'duration', 'sheds', 'locks', 'rewinds_used']));
    expect(end.params['mode'], 'endless');
    expect(names, contains('ad_shown'));
  });

  testWidgets('no interstitials for a new player (session 1)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    final env = TestEnv(sessions: 1);
    await tester.pumpWidget(env.app(const GameScreen(seed: 4)));
    await tester.pump();
    for (var run = 1; run <= 4; run++) {
      await playAndDie(tester);
      await tapText(tester, 'PLAY AGAIN');
    }
    expect(env.ads.interstitialsShown, 0);
  });

  testWidgets('rewarded continue logs the ad and revives the snake', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    final env = TestEnv();
    await tester.pumpWidget(env.app(const GameScreen(seed: 4)));
    await tester.pump();
    await playAndDie(tester);
    await tapText(tester, 'CONTINUE');
    await tester.pump(const Duration(milliseconds: 100));
    expect(gameOf(tester).phase.value, PlayPhase.countdown);
    expect(env.analytics.names, containsAllInOrder(['ad_shown', 'ad_rewarded']));
  });

  testWidgets('shop: locked items can not be picked; buying unlocks and equips', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 2400));
    final env = TestEnv(storage: MemoryStorageService());
    await tester.pumpWidget(env.app(const ShopScreen()));
    await tester.pump();

    expect(find.text('STRIPED ×'), findsOneWidget, reason: 'locked');
    await tester.tap(find.text('STRIPED ×'));
    await tester.pump();
    expect(env.storage.loadout.skin, SnakeSkin.classic);

    // Buy the skin pack (test store) and equip.
    await tester.tap(find.text('£1.99').at(0));
    await tester.pump();
    expect(env.iap.owned.value, contains(Pack.skins));
    expect(find.text('OWNED'), findsOneWidget);
    await tester.tap(find.text('STRIPED'));
    await tester.pump();
    expect(env.storage.loadout.skin, SnakeSkin.striped);
    expect(env.analytics.names, contains('iap_purchase'));

    // Buy themes and switch the whole app to NIGHT.
    await tester.tap(find.text('£1.99').last);
    await tester.pump();
    await tester.tap(find.text('NIGHT'));
    await tester.pump();
    expect(env.storage.loadout.theme, BoardTheme.night);
    expect(LcdPalette.active, LcdPalette.themes[BoardTheme.night]);
    expect(find.text('SHOP'), findsOneWidget, reason: 'still on the shop after re-theming');
  });

  testWidgets('remove ads shows as owned', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 2400));
    final env = TestEnv(storage: MemoryStorageService()..ownedPacks = {Pack.removeAds});
    await tester.pumpWidget(env.app(const ShopScreen()));
    await tester.pump();
    expect(find.text('OWNED'), findsOneWidget);
    expect(find.text('£2.99'), findsNothing);
  });
}
