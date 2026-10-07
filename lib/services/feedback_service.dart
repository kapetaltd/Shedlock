import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/core.dart';
import 'settings.dart';

enum Sfx { eat, shed, lock, death, rewind, tick }

abstract class SoundPlayer {
  Future<void> preload();
  void play(Sfx sfx);
}

/// Low-latency playback: one small pool per effect, loaded up front.
class FlameSoundPlayer implements SoundPlayer {
  final Map<Sfx, AudioPool> _pools = {};

  @override
  Future<void> preload() async {
    for (final s in Sfx.values) {
      try {
        _pools[s] = await FlameAudio.createPool('${s.name}.wav', maxPlayers: s == Sfx.eat ? 4 : 2);
      } on Object catch (e) {
        debugPrint('[sound] could not load ${s.name}: $e');
      }
    }
  }

  @override
  void play(Sfx sfx) => _pools[sfx]?.start(volume: 0.8);
}

abstract class Haptics {
  void light();
  void medium();
  void heavy();
  void selection();
}

class SystemHaptics implements Haptics {
  const SystemHaptics();
  @override
  void light() => HapticFeedback.lightImpact();
  @override
  void medium() => HapticFeedback.mediumImpact();
  @override
  void heavy() => HapticFeedback.heavyImpact();
  @override
  void selection() => HapticFeedback.selectionClick();
}

/// Turns game events into sound and haptics, honouring the player's
/// settings.
class FeedbackService {
  FeedbackService({required this.sound, required this.haptics, required this.settings});

  final SoundPlayer sound;
  final Haptics haptics;
  final ValueListenable<GameSettings> settings;

  void _play(Sfx s) {
    if (settings.value.sound) sound.play(s);
  }

  void _buzz(void Function(Haptics) f) {
    if (settings.value.haptics) f(haptics);
  }

  void onEvents(List<GameEvent> events) {
    for (final e in events) {
      switch (e) {
        case FoodEaten():
          _play(Sfx.eat);
          _buzz((h) => h.light());
        case Shed():
          _play(Sfx.shed);
          _buzz((h) => h.medium());
        case ShedDenied():
          _buzz((h) => h.selection());
        case RunnerLocked():
          _play(Sfx.lock);
          _buzz((h) => h.heavy());
        case Died():
          _play(Sfx.death);
          _buzz((h) => h.heavy());
        default:
          break;
      }
    }
  }

  void rewind() {
    _play(Sfx.rewind);
    _buzz((h) => h.medium());
  }

  void tick() => _play(Sfx.tick);
}

/// Records calls. For tests (and the web build, which has no haptics).
class RecordingSoundPlayer implements SoundPlayer {
  final List<Sfx> played = [];
  @override
  Future<void> preload() async {}
  @override
  void play(Sfx sfx) => played.add(sfx);
}

class RecordingHaptics implements Haptics {
  final List<String> calls = [];
  @override
  void light() => calls.add('light');
  @override
  void medium() => calls.add('medium');
  @override
  void heavy() => calls.add('heavy');
  @override
  void selection() => calls.add('selection');
}
