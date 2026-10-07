import 'grid_pos.dart';

enum FoodKind {
  /// Sits still until eaten.
  normal,

  /// Moves every few ticks. Can be eaten, or locked for a bonus.
  runner,
}

class Food {
  const Food({
    required this.id,
    required this.pos,
    required this.kind,
    required this.spawnTick,
  });

  final int id;
  final GridPos pos;
  final FoodKind kind;

  /// Tick the food appeared on. Runners move relative to this so they don't
  /// all step on the same tick.
  final int spawnTick;

  bool get isRunner => kind == FoodKind.runner;

  Food movedTo(GridPos p) =>
      Food(id: id, pos: p, kind: kind, spawnTick: spawnTick);

  @override
  bool operator ==(Object other) =>
      other is Food &&
      other.id == id &&
      other.pos == pos &&
      other.kind == kind &&
      other.spawnTick == spawnTick;

  @override
  int get hashCode => Object.hash(id, pos, kind, spawnTick);

  @override
  String toString() => 'Food#$id(${kind.name} $pos)';
}
