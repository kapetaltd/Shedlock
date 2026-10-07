import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/core/core.dart';
import 'package:shedlock/game/shedlock_game.dart';
import 'package:shedlock/ui/theme/lcd_theme.dart';

import '../core/helpers.dart';

/// Plays a bot run until the board shows shed walls and a runner.
RunSession interestingRun() {
  const cfg = GameConfig(runnerSpawnPercent: 100, runnerMinNormalFood: 1);
  for (var seed = 1; seed < 200; seed++) {
    final s = RunSession(mode: GameMode.endless, seed: seed, config: cfg);
    final bot = Bot(shedEvery: 0);
    var shedAt = -1;
    while (!s.isOver && s.state.tick < 3000) {
      final st = s.state;
      final input = bot.decide(st);
      if (input.turn != null) s.turn(input.turn!);
      if (shedAt < 0 && st.length >= 9) {
        s.requestShed();
        shedAt = st.tick;
      }
      s.tick();
      final now = s.state;
      if (shedAt > 0 &&
          now.tick - shedAt > 12 &&
          now.shedWalls.isNotEmpty &&
          now.foods.any((f) => f.isRunner) &&
          now.length >= 5) {
        return s;
      }
    }
  }
  throw StateError('no interesting run found');
}

void main() {
  setUpAll(() async {
    final font = File('assets/fonts/PressStart2P-Regular.ttf').readAsBytesSync();
    final loader = FontLoader(pixelFont)..addFont(Future.value(ByteData.view(font.buffer)));
    await loader.load();
  });

  testWidgets('renders a mid-game board with walls, runner and effects', (tester) async {
    final session = interestingRun();
    final game = ShedlockGame(session: session);
    final key = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(400, 600));
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ColoredBox(color: LcdPalette.screen, child: GameWidget(game: game)),
      ),
    );
    await tester.pump();
    final s = session.state;
    game.effects.handle([
      FoodEaten(Food(id: -1, pos: s.head, kind: FoodKind.normal, spawnTick: 0), 14),
    ]);
    game.update(0.1);
    await tester.pump(const Duration(milliseconds: 16));

    expect(tester.takeException(), isNull);
    expect(s.shedWalls, isNotEmpty);

    final out = Platform.environment['SHEDLOCK_SHOTS'];
    if (out != null) {
      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$out/render-midgame.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }
  });
}
