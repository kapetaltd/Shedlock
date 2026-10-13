import '../core/core.dart';

/// Turns an accumulated drag delta into a direction once it passes
/// [threshold] pixels along its dominant axis. Returns null until then.
Direction? swipeDirection(double dx, double dy, double threshold) {
  final ax = dx.abs();
  final ay = dy.abs();
  if (ax < threshold && ay < threshold) return null;
  if (ax >= ay) return dx > 0 ? Direction.right : Direction.left;
  return dy > 0 ? Direction.down : Direction.up;
}

/// Tracks one drag gesture. Emits a turn each time the finger travels
/// [threshold] pixels, so one continuous swipe can chain two turns
/// (e.g. an L-shaped swipe).
class SwipeTracker {
  SwipeTracker({required this.threshold});

  double threshold;
  double _dx = 0;
  double _dy = 0;

  void start() {
    _dx = 0;
    _dy = 0;
  }

  Direction? update(double dx, double dy) {
    _dx += dx;
    _dy += dy;
    final d = swipeDirection(_dx, _dy, threshold);
    if (d != null) start();
    return d;
  }
}
