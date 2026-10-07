import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/core/core.dart';
import 'package:shedlock/game/shedlock_game.dart';
import 'package:shedlock/services/feedback_service.dart';
import 'package:shedlock/services/storage_service.dart';
import 'package:shedlock/services/settings.dart';
import 'package:shedlock/ui/screens/game_screen.dart';
import 'package:shedlock/ui/screens/settings_screen.dart';

import 'test_env.dart';

void main() {
  testWidgets('toggles persist; privacy options only when required', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1600));
    final env = TestEnv();
    await tester.pumpWidget(env.app(const SettingsScreen()));
    await tester.pump();
    expect(find.text('PRIVACY OPTIONS'), findsNothing);

    await tester.tap(find.text('SOUND'));
    await tester.pump();
    expect(env.storage.settings.sound, isFalse);
    await tester.tap(find.text('SCREEN SHAKE'));
    await tester.pump();
    expect(env.storage.settings.screenShake, isFalse);
    expect(find.text('OFF'), findsNWidgets(2));

    final env2 = TestEnv()..ads.privacyRequired = true;
    await tester.pumpWidget(env2.app(const SettingsScreen()));
    await tester.pump();
    await tester.tap(find.text('PRIVACY OPTIONS'));
    await tester.pump();
    expect(env2.ads.privacyFormsShown, 1);
  });

  testWidgets('in game: events play sounds; mute and no-shake are honoured', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    final env = TestEnv(
      storage: MemoryStorageService()..settings = const GameSettings(screenShake: false),
    );
    await tester.pumpWidget(env.app(const GameScreen(seed: 4)));
    await tester.pump();
    final game = tester.widget<GameWidget<ShedlockGame>>(find.byType(GameWidget<ShedlockGame>)).game!;
    expect(game.shakeEnabled, isFalse);
    game.turn(Direction.left);
    for (var i = 0; i < 80 && game.phase.value != PlayPhase.over; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(env.sound.played, contains(Sfx.death));
    expect(env.haptics.calls, contains('heavy'));
    expect(game.shakeOffset, Offset.zero);

    // Free rewind plays the rewind sound and ticks through the countdown.
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('REWIND 3S'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(env.sound.played, contains(Sfx.rewind));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(env.sound.played.where((s) => s == Sfx.tick), hasLength(3), reason: '3, 2, 1');
  });
}
