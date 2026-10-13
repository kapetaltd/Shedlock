// Renders raw app screens for the Google Play store listing:
//
//   flutter test tool/store_assets_test.dart
//   python3 tool/store_assets.py        # frames them, adds captions,
//                                       # makes the feature graphic
//
// Output goes to build/store/raw (1080×2280 PNGs). Lives in tool/ so a
// normal `flutter test` doesn't run it.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/core/core.dart';
import 'package:shedlock/config/app_config.dart';
import 'package:shedlock/game/shedlock_game.dart';
import 'package:shedlock/services/storage_service.dart';
import 'package:shedlock/ui/screens/daily_screen.dart';
import 'package:shedlock/ui/screens/home_screen.dart';
import 'package:shedlock/ui/screens/shop_screen.dart';
import 'package:shedlock/ui/theme/app_theme.dart';
import 'package:shedlock/ui/widgets/hud.dart';

import '../test/core/helpers.dart';
import '../test/support/fonts.dart';
import '../test/ui/test_env.dart';

const _size = Size(360, 760);
const _out = 'build/store/raw';

/// A bot run with a long snake and a runner on the board (no shed).
RunSession _longSnakeRun() {
  const cfg = GameConfig(runnerSpawnPercent: 100, runnerMinNormalFood: 1);
  for (var seed = 1; seed < 400; seed++) {
    final s = RunSession(mode: GameMode.endless, seed: seed, config: cfg);
    final bot = Bot(shedEvery: 0);
    while (!s.isOver && s.state.tick < 6000) {
      final input = bot.decide(s.state);
      if (input.turn != null) s.turn(input.turn!);
      s.tick();
      if (s.state.length >= 24 && s.state.foods.any((f) => f.isRunner)) return s;
    }
  }
  throw StateError('no long-snake run found');
}

/// A bot run with a long snake, fading shed walls and a fleeing runner.
RunSession _showcaseRun() {
  const cfg = GameConfig(runnerSpawnPercent: 100, runnerMinNormalFood: 1);
  for (var seed = 1; seed < 400; seed++) {
    final s = RunSession(mode: GameMode.endless, seed: seed, config: cfg);
    final bot = Bot(shedEvery: 0);
    var shedAt = -1;
    while (!s.isOver && s.state.tick < 6000) {
      final st = s.state;
      final input = bot.decide(st);
      if (input.turn != null) s.turn(input.turn!);
      if (shedAt < 0 && st.length >= 16) {
        s.requestShed();
        shedAt = st.tick;
      }
      s.tick();
      final now = s.state;
      if (shedAt > 0 &&
          now.tick - shedAt > 20 &&
          now.shedWalls.length >= 8 &&
          now.foods.any((f) => f.isRunner) &&
          now.length >= 8) {
        return s;
      }
    }
  }
  throw StateError('no showcase run found');
}

/// The in-game screen as players see it: HUD, board and shed bar.
class _GameShot extends StatelessWidget {
  const _GameShot({required this.game});
  final ShedlockGame game;

  @override
  Widget build(BuildContext context) {
    final c = game.session.state.config;
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hud(game: game),
            Flexible(
              child: AspectRatio(
                aspectRatio: c.width / c.height,
                child: GameWidget(game: game),
              ),
            ),
            ShedBar(game: game),
          ],
        ),
      ),
    );
  }
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

TestEnv _env(AppTheme theme, {DateTime? now, void Function(MemoryStorageService s)? setup}) {
  final storage = MemoryStorageService()
    ..ownedPacks = {Pack.themes, Pack.skins, Pack.trails}
    ..endlessBest = 4280
    ..loadout = Loadout(theme: theme);
  setup?.call(storage);
  return TestEnv(storage: storage, now: now);
}

Future<void> _shotScreen(
  WidgetTester tester,
  String name,
  TestEnv env,
  Widget screen, {
  Future<void> Function()? before,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(RepaintBoundary(key: key, child: env.app(screen)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  if (before != null) await before();
  await _capture(tester, key, name);
}

Future<void> _shotGame(
  WidgetTester tester,
  String name,
  AppTheme theme, {
  Loadout? loadout,
  bool lockFx = false,
  bool longSnake = false,
}) async {
  final session = longSnake ? _longSnakeRun() : _showcaseRun();
  final env = _env(theme);
  final game = ShedlockGame(
    session: session,
    best: 4280,
    loadout: loadout ?? Loadout(theme: theme),
  );
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: env.app(_GameShot(game: game)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  final s = session.state;
  game.hud.value = HudData.of(s, 4280);
  if (lockFx) {
    final runner = s.foods.firstWhere((f) => f.isRunner);
    game.effects.handle([RunnerLocked(runner, 100)]);
    game.update(0.15);
  }
  await tester.pump(const Duration(milliseconds: 16));
  await _capture(tester, key, name);
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    final icons = File(
      '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/sdk/flutter'}'
      '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ).readAsBytesSync();
    await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(icons.buffer)))).load();
    Directory(_out).createSync(recursive: true);
  });
  tearDown(() => Palette.apply(AppTheme.paper));

  testWidgets('store screenshots', (tester) async {
    await tester.binding.setSurfaceSize(_size);

    await _shotGame(tester, '1-game-paper', AppTheme.paper, lockFx: true);
    await _shotGame(
      tester,
      '2-game-dusk',
      AppTheme.dusk,
      loadout: const Loadout(theme: AppTheme.dusk, skin: SnakeSkin.striped),
      longSnake: true,
    );
    await _shotGame(tester, '5-game-retro', AppTheme.lime);

    // Daily hub with today's result and a streak.
    final today = AppConfig.dailyEpoch.add(const Duration(days: 11, hours: 9));
    final key = dailyKey(today);
    final dailyEnv = _env(
      AppTheme.paper,
      now: today,
      setup: (s) {
        s
          ..dailyAttemptStarted = key
          ..streak = Streak(current: 6, best: 9, lastDayKey: key)
          ..lastDailyRecord = DailyRecord(
            dayKey: key,
            dailyNumber: 12,
            score: 1240,
            foodEaten: 37,
            locks: 3,
            sheds: 5,
            rewindsUsed: 0,
            slices: const [SliceKind.warm, SliceKind.hot, SliceKind.lock, SliceKind.blazing, SliceKind.lock],
            shareText: '',
          );
      },
    );
    await _shotScreen(tester, '3-daily', dailyEnv, const DailyScreen());

    // Shop, scrolled to the theme pickers.
    await _shotScreen(
      tester,
      '4-shop',
      _env(AppTheme.sage),
      const ShopScreen(),
      before: () async {
        await tester.scrollUntilVisible(find.text('Retro LCD'), 300);
        await tester.pump(const Duration(milliseconds: 300));
      },
    );

    await _shotScreen(
      tester,
      '6-home',
      _env(
        AppTheme.paper,
        now: today,
        setup: (s) => s.streak = Streak(
          current: 6,
          best: 9,
          lastDayKey: dailyKey(today.subtract(const Duration(days: 1))),
        ),
      ),
      const HomeScreen(),
    );
    expect(tester.takeException(), isNull);
  });
}
