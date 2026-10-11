import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shedlock/core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/game/shedlock_game.dart';
import 'package:shedlock/services/storage_service.dart';
import 'package:shedlock/ui/format.dart';
import 'package:shedlock/ui/theme/app_theme.dart';
import 'package:shedlock/ui/screens/game_screen.dart';
import 'package:shedlock/ui/screens/home_screen.dart';

import 'test_env.dart';

Widget app(Widget home, {MemoryStorageService? storage}) =>
    TestEnv(storage: storage).app(home);

void main() {
  test('score formatting', () {
    expect(formatScore(0), '0');
    expect(formatScore(1240), '1,240');
    expect(formatScore(1234567), '1,234,567');
    expect(formatMultiplier(100), '×1.0');
    expect(formatMultiplier(140), '×1.4');
    Palette.apply(BoardTheme.lime);
    expect(formatMultiplier(140), 'x1.4', reason: 'the pixel font look uses a plain x');
    Palette.apply(BoardTheme.paper);
  });

  testWidgets('home shows the name, tagline and menu', (tester) async {
    await tester.pumpWidget(app(const HomeScreen()));
    expect(find.text('Shedlock'), findsOneWidget);
    expect(find.text('Shed your tail. Lock your prey.'), findsOneWidget);
    for (final label in ['Daily', 'Endless', 'Shop', 'Settings']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('home shows the stored best score', (tester) async {
    final storage = MemoryStorageService()..endlessBest = 1240;
    await tester.pumpWidget(app(const HomeScreen(), storage: storage));
    expect(find.text('Best 1,240'), findsOneWidget);
  });

  testWidgets('game screen: start hint, then play, then game over', (tester) async {
    final storage = MemoryStorageService();
    await tester.pumpWidget(app(const GameScreen(seed: 4), storage: storage));
    await tester.pump();
    expect(find.text('Swipe to move'), findsOneWidget);

    final game = tester
        .widget<GameWidget<ShedlockGame>>(find.byType(GameWidget<ShedlockGame>))
        .game!;
    game.turn(Direction.left);
    // Run the snake into the left wall.
    for (var i = 0; i < 60 && game.phase.value != PlayPhase.over; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(game.phase.value, PlayPhase.over);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Game over'), findsOneWidget);
    expect(find.text('Rewind 3s'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);
  });
}
