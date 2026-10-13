import 'dart:collection';

import '../model/game_state.dart';

/// Rolling buffer of game states covering the last [windowMs] of simulated
/// time. States are immutable, so a snapshot is just a reference.
class SnapshotBuffer {
  SnapshotBuffer({required this.windowMs});

  final int windowMs;
  final ListQueue<GameState> _states = ListQueue();

  int get length => _states.length;
  bool get isEmpty => _states.isEmpty;
  GameState? get oldest => _states.isEmpty ? null : _states.first;
  GameState? get newest => _states.isEmpty ? null : _states.last;

  void push(GameState s) {
    _states.addLast(s);
    // Keep the oldest state that is still at least windowMs back, so a rewind
    // can always reach a full window when the run is long enough.
    while (_states.length > 1 &&
        s.simTimeMs - _states.elementAt(1).simTimeMs >= windowMs) {
      _states.removeFirst();
    }
  }

  /// The state a rewind from [nowMs] would restore: the latest snapshot that
  /// is at least [windowMs] older than [nowMs], or the oldest one held if the
  /// run is younger than that.
  GameState? targetFor(int nowMs) {
    if (_states.isEmpty) return null;
    GameState target = _states.first;
    for (final s in _states) {
      if (nowMs - s.simTimeMs >= windowMs) {
        target = s;
      } else {
        break;
      }
    }
    return target;
  }

  /// Returns the rewind target and drops everything newer than it.
  GameState? restore(int nowMs) {
    final target = targetFor(nowMs);
    if (target == null) return null;
    while (!identical(_states.last, target)) {
      _states.removeLast();
    }
    return target;
  }

  void clear() => _states.clear();
}
