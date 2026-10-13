import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/core/core.dart';
import 'package:shedlock/services/feedback_service.dart';
import 'package:shedlock/services/settings.dart';

void main() {
  const food = Food(id: 1, pos: GridPos(0, 0), kind: FoodKind.normal, spawnTick: 0);

  (FeedbackService, RecordingSoundPlayer, RecordingHaptics, ValueNotifier<GameSettings>) rig() {
    final sound = RecordingSoundPlayer();
    final haptics = RecordingHaptics();
    final settings = ValueNotifier(const GameSettings());
    return (FeedbackService(sound: sound, haptics: haptics, settings: settings), sound, haptics, settings);
  }

  test('each event has its sound and haptic', () {
    final (fb, sound, haptics, _) = rig();
    fb.onEvents(const [
      FoodEaten(food, 10),
      Shed([GridPos(1, 1)]),
      RunnerLocked(food, 100),
      Died(DeathCause.wall, GridPos(-1, 0)),
      ShedDenied(ShedDeniedReason.cooldown),
      WallsExpired([GridPos(1, 1)]),
    ]);
    expect(sound.played, [Sfx.eat, Sfx.shed, Sfx.lock, Sfx.death]);
    expect(haptics.calls, ['light', 'medium', 'heavy', 'heavy', 'selection']);
    fb.rewind();
    expect(sound.played.last, Sfx.rewind);
  });

  test('mute and haptics toggles are respected independently', () {
    final (fb, sound, haptics, settings) = rig();
    settings.value = const GameSettings(sound: false);
    fb.onEvents(const [FoodEaten(food, 10)]);
    expect(sound.played, isEmpty);
    expect(haptics.calls, ['light']);

    settings.value = const GameSettings(haptics: false);
    fb.onEvents(const [FoodEaten(food, 10)]);
    expect(sound.played, [Sfx.eat]);
    expect(haptics.calls, ['light']);
  });

  test('settings json round trip with defaults for missing keys', () {
    const s = GameSettings(sound: false, haptics: true, screenShake: false);
    final back = GameSettings.fromJson(s.toJson());
    expect((back.sound, back.haptics, back.screenShake), (false, true, false));
    final d = GameSettings.fromJson(const {});
    expect((d.sound, d.haptics, d.screenShake), (true, true, true));
  });
}
