/// A small, fast PRNG (mulberry32) whose output is identical on every
/// platform, including the web, where Dart ints are JavaScript doubles.
///
/// `dart:math`'s `Random(seed)` is not guaranteed to produce the same numbers
/// across platforms or SDK versions, which would break the Daily Challenge.
///
/// All arithmetic stays within unsigned 32 bits (and below 2^53 for
/// intermediate products), so the VM and JS produce the same values.
class SeededRng {
  SeededRng(int seed) : state = seed & _mask32;

  static const int _mask32 = 0xFFFFFFFF;
  static const int _two32 = 0x100000000;

  /// The full generator state. Store this to snapshot the stream.
  int state;

  /// Next unsigned 32-bit value.
  int nextUint32() {
    state = (state + 0x6D2B79F5) & _mask32;
    var t = state;
    t = imul32(t ^ (t >> 15), t | 1);
    t = (t ^ ((t + imul32(t ^ (t >> 7), t | 61)) & _mask32)) & _mask32;
    return (t ^ (t >> 14)) & _mask32;
  }

  /// Uniform integer in [0, max).
  int nextInt(int max) {
    assert(max > 0);
    return (nextUint32() * max) ~/ _two32;
  }

  /// Uniform double in [0, 1).
  double nextDouble() => nextUint32() / _two32;

  /// True with probability [percent]/100.
  bool chance(int percent) => nextInt(100) < percent;

  /// 32-bit integer multiply, equivalent to JavaScript's `Math.imul`, for
  /// unsigned 32-bit inputs. Result is unsigned 32-bit.
  static int imul32(int a, int b) {
    final aHi = (a >> 16) & 0xFFFF;
    final aLo = a & 0xFFFF;
    final bHi = (b >> 16) & 0xFFFF;
    final bLo = b & 0xFFFF;
    final cross = ((aHi * bLo + aLo * bHi) & 0xFFFF) * 0x10000;
    return (aLo * bLo + cross) & _mask32;
  }
}
