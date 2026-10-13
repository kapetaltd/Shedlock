/// Turns variable frame times into fixed simulation steps.
///
/// The step length can change between steps (the snake speeds up), so it is
/// read through [stepMs] before every step. Rendering uses [alpha] to
/// interpolate between the previous and current state.
class FixedStepClock {
  FixedStepClock({this.maxFrameMs = 250});

  /// Frames longer than this (app paused, debugger, hitch) are clamped so the
  /// game never fast-forwards through a burst of ticks.
  final double maxFrameMs;

  /// Absorbs floating-point drift from summing frame times like 1000/60.
  static const double _epsilonMs = 1e-6;

  double _accumulatorMs = 0;

  double get accumulatorMs => _accumulatorMs;

  /// Adds [dtMs] of real time and runs as many steps as fit.
  /// [onStep] returns false to stop stepping (e.g. the snake died); leftover
  /// time is then discarded.
  /// Returns the number of steps run.
  int advance(double dtMs, int Function() stepMs, bool Function() onStep) {
    if (dtMs <= 0) return 0;
    _accumulatorMs += dtMs > maxFrameMs ? maxFrameMs : dtMs;
    var steps = 0;
    while (_accumulatorMs + _epsilonMs >= stepMs()) {
      _accumulatorMs = (_accumulatorMs - stepMs()).clamp(0.0, double.infinity);
      steps++;
      if (!onStep()) {
        _accumulatorMs = 0;
        break;
      }
    }
    return steps;
  }

  /// How far (0..1) we are between the last step and the next.
  double alpha(int stepMs) => (_accumulatorMs / stepMs).clamp(0.0, 1.0);

  void reset() => _accumulatorMs = 0;
}
