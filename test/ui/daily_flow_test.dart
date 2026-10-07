import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/config/app_config.dart';
import 'package:shedlock/core/core.dart';
import 'package:shedlock/game/shedlock_game.dart';
import 'package:shedlock/services/share_service.dart';
import 'package:shedlock/services/storage_service.dart';
import 'package:shedlock/ui/screens/home_screen.dart';

import 'test_env.dart';

/// Daily #3, whatever the configured epoch is.
final today = AppConfig.dailyEpoch.add(const Duration(days: 2, hours: 12));
final todayKey = dailyKey(today);

Widget app(MemoryStorageService storage, FakeShareService share, {DateTime? now}) {
  final env = TestEnv(storage: storage, now: now ?? today);
  env.share.shared.clear();
  _lastEnv = env;
  return env.app(const HomeScreen());
}

late TestEnv _lastEnv;

/// The share service of the most recent [app].
FakeShareService get lastShare => _lastEnv.share;

/// Taps [label] and lets the route transition finish.
Future<void> tapAndSettle(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

ShedlockGame gameOf(WidgetTester tester) => tester
    .widget<GameWidget<ShedlockGame>>(find.byType(GameWidget<ShedlockGame>))
    .game!;

Future<void> dieNow(WidgetTester tester, ShedlockGame game) async {
  game.turn(Direction.left);
  for (var i = 0; i < 80 && game.phase.value != PlayPhase.over; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(game.phase.value, PlayPhase.over);
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('ranked daily: play, end run, share, then practice only', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    final storage = MemoryStorageService();
    final share = FakeShareService();
    await tester.pumpWidget(app(storage, share));

    expect(find.text('#3 · PLAY'), findsOneWidget);
    await tapAndSettle(tester, 'DAILY');
    expect(find.text('#3'), findsOneWidget);
    expect(find.text('$todayKey UTC'), findsOneWidget);

    await tapAndSettle(tester, 'PLAY RANKED');
    expect(find.text('DAILY #3 · RANKED'), findsOneWidget);
    expect(storage.dailyAttemptStarted, todayKey, reason: 'attempt used on start');

    final game = gameOf(tester);
    expect(game.session.ranked, isTrue);
    expect(game.session.state.layout.obstacles, isNotEmpty);
    await dieNow(tester, game);

    // Ranked: free rewind or end the run. No ads, no continue, no replay.
    expect(find.text('REWIND 3S'), findsOneWidget);
    expect(find.text('END RUN'), findsOneWidget);
    expect(find.text('CONTINUE'), findsNothing);
    expect(find.text('PLAY AGAIN'), findsNothing);

    await tapAndSettle(tester, 'END RUN');
    expect(find.text('SHEDLOCK #3'), findsOneWidget);
    expect(find.text('STREAK 1  ·  BEST 1'), findsOneWidget);
    expect(storage.lastDailyRecord?.dayKey, todayKey);
    expect(storage.streak.current, 1);

    await tester.tap(find.text('SHARE'));
    await tester.pump();
    expect(lastShare.shared, hasLength(1));
    expect(lastShare.shared.single, startsWith('Shedlock #3 🐍 '));
    expect(lastShare.shared.single, endsWith('Shed your tail. Lock your prey.'));

    // Analytics for the ranked run, and never an interstitial on this path.
    final names = _lastEnv.analytics.names;
    expect(names, containsAllInOrder(['run_start', 'run_end', 'streak_length', 'daily_shared']));
    final start = _lastEnv.analytics.events.firstWhere((e) => e.name == 'run_start');
    expect(start.params['mode'], 'daily_ranked');
    expect(_lastEnv.ads.interstitialsShown, 0);

    await tapAndSettle(tester, 'DONE');
    // Back on the hub: already played, so share or practice.
    expect(find.text('SHARE RESULT'), findsOneWidget);
    expect(find.text('PLAY RANKED'), findsNothing);
    expect(find.text('PRACTICE'), findsOneWidget);

    await tapAndSettle(tester, 'PRACTICE');
    expect(find.text('DAILY #3 · PRACTICE'), findsOneWidget);
    expect(gameOf(tester).session.ranked, isFalse);
  });

  testWidgets('a ranked run abandoned mid-way still uses the attempt', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    final storage = MemoryStorageService()..dailyAttemptStarted = todayKey;
    await tester.pumpWidget(app(storage, FakeShareService()));
    expect(find.text('#3 · PRACTICE'), findsOneWidget);
    await tapAndSettle(tester, 'DAILY');
    expect(find.text('PLAY RANKED'), findsNothing);
    expect(find.textContaining('NOT FINISHED'), findsOneWidget);
  });

  testWidgets('a new UTC day brings a new ranked attempt and keeps the streak', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    final storage = MemoryStorageService()
      ..dailyAttemptStarted = todayKey
      ..streak = Streak().record(todayKey);
    final tomorrow = AppConfig.dailyEpoch.add(const Duration(days: 3, seconds: 5));
    await tester.pumpWidget(app(storage, FakeShareService(), now: tomorrow));
    expect(find.text('#4 · PLAY · STREAK 1'), findsOneWidget);
  });
}
