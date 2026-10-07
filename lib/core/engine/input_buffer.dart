import '../model/direction.dart';

/// Holds the next turn plus one buffered turn, so two quick swipes inside a
/// single tick (e.g. up then left to U-turn) both register.
///
/// Each turn is validated against the turn queued before it, so a fast
/// double-swipe can never reverse the snake into itself.
class InputBuffer {
  InputBuffer({this.capacity = 2});

  final int capacity;
  final List<Direction> _queue = [];

  int get length => _queue.length;
  bool get isEmpty => _queue.isEmpty;

  /// Queues [d] if it is a real turn. Returns whether it was accepted.
  bool push(Direction d, Direction currentHeading) {
    final last = _queue.isEmpty ? currentHeading : _queue.last;
    if (d == last || d.isOppositeOf(last)) return false;
    if (_queue.length >= capacity) return false;
    _queue.add(d);
    return true;
  }

  Direction? pop() => _queue.isEmpty ? null : _queue.removeAt(0);

  void clear() => _queue.clear();
}
