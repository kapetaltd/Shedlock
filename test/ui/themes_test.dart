import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/core/core.dart';
import 'package:shedlock/services/storage_service.dart';
import 'package:shedlock/ui/screens/daily_screen.dart';
import 'package:shedlock/ui/screens/game_screen.dart';
import 'package:shedlock/ui/screens/home_screen.dart';
import 'package:shedlock/ui/screens/settings_screen.dart';
import 'package:shedlock/ui/screens/shop_screen.dart';
import 'package:shedlock/ui/theme/app_theme.dart';

import '../support/fonts.dart';
import 'test_env.dart';

TestEnv _env(BoardTheme theme) => TestEnv(
      storage: MemoryStorageService()
        ..ownedPacks = Pack.values.toSet()
        ..endlessBest = 123456
        ..loadout = Loadout(theme: theme, skin: SnakeSkin.striped, trail: Trail.dust),
    );

void main() {
  setUpAll(loadAppFonts);
  tearDown(() => Palette.apply(BoardTheme.paper));

  // Real fonts on a small phone: layouts must not overflow in any look.
  for (final theme in BoardTheme.values) {
    testWidgets('every screen lays out in ${theme.name}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final screen in const [
        HomeScreen(),
        DailyScreen(),
        ShopScreen(),
        SettingsScreen(),
        GameScreen(seed: 4),
      ]) {
        await tester.pumpWidget(_env(theme).app(screen));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '${screen.runtimeType}');
      }
      expect(Palette.retro, theme.retro);
    });
  }

  testWidgets('auto follows the device dark mode, live', (tester) async {
    final env = TestEnv();
    await tester.pumpWidget(env.app(const HomeScreen()));
    expect(Palette.theme, BoardTheme.paper);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pump();
    expect(Palette.theme, BoardTheme.dusk);
    await tester.pump(const Duration(milliseconds: 400)); // theme cross-fade
    final bg = Theme.of(tester.element(find.byType(Scaffold))).scaffoldBackgroundColor;
    expect(bg, Palette.looks[BoardTheme.dusk]!.background);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pump();
    expect(Palette.theme, BoardTheme.paper);
  });

  testWidgets('a chosen theme ignores dark mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(_env(BoardTheme.sand).app(const HomeScreen()));
    expect(Palette.theme, BoardTheme.sand);
  });

  testWidgets('refunding the theme pack falls back to Auto', (tester) async {
    final env = _env(BoardTheme.mono);
    await tester.pumpWidget(env.app(const HomeScreen()));
    expect(Palette.theme, BoardTheme.mono);
    expect(find.text('ENDLESS'), findsOneWidget, reason: 'retro copy is upper case');

    env.iap.ownedNotifier.value = {};
    await tester.pump();
    expect(env.storage.loadout.theme, BoardTheme.auto);
    expect(Palette.theme, BoardTheme.paper);
    expect(find.text('Endless'), findsOneWidget);
  });
}
