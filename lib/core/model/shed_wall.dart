import 'grid_pos.dart';

/// A solid block left behind by shedding. Expires after a fixed lifetime.
class ShedWall {
  const ShedWall({
    required this.pos,
    required this.createdAtMs,
    required this.expiresAtMs,
  });

  final GridPos pos;
  final int createdAtMs;
  final int expiresAtMs;

  bool isExpiredAt(int nowMs) => nowMs >= expiresAtMs;

  /// 1.0 when fresh, 0.0 when expired. Drives the fade animation.
  double remainingFraction(int nowMs) {
    final total = expiresAtMs - createdAtMs;
    if (total <= 0) return 0;
    return ((expiresAtMs - nowMs) / total).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      other is ShedWall &&
      other.pos == pos &&
      other.createdAtMs == createdAtMs &&
      other.expiresAtMs == expiresAtMs;

  @override
  int get hashCode => Object.hash(pos, createdAtMs, expiresAtMs);
}
