import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shedlock/core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/game/shedlock_game.dart';
import 'package:shedlock/services/storage_service.dart';
import 'package:shedlock/ui/format.dart';
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
    expect(formatMultiplier(100), 'x1.0');
    expect(formatMultiplier(140), 'x1.4');
  });

  testWidgets('home shows the name, tagline and menu', (tester) async {
    await tester.pumpWidget(app(const HomeScreen()));
    expect(find.text('SHEDLOCK'), findsOneWidget);
    expect(find.text('SHED YOUR TAIL. LOCK YOUR PREY.'), findsOneWidget);
    for (final label in ['DAILY', 'ENDLESS', 'SHOP', 'SETTINGS']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('home shows the stored best score', (tester) async {
    final storage = MemoryStorageService()..endlessBest = 1240;
    await tester.pumpWidget(app(const HomeScreen(), storage: storage));
    expect(find.text('BEST 1,240'), findsOneWidget);
  });

  testWidgets('game screen: start hint, then play, then game over', (tester) async {
    final storage = MemoryStorageService();
    await tester.pumpWidget(app(const GameScreen(seed: 4), storage: storage));
    await tester.pump();
    expect(find.text('SWIPE TO MOVE'), findsOneWidget);

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
    expect(find.text('GAME OVER'), findsOneWidget);
    expect(find.text('REWIND 3S'), findsOneWidget);
    expect(find.text('FREE'), findsOneWidget);
  });
}
