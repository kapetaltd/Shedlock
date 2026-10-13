import 'direction.dart';

/// An immutable cell coordinate on the board.
class GridPos {
  const GridPos(this.x, this.y);

  final int x;
  final int y;

  GridPos step(Direction d) => GridPos(x + d.dx, y + d.dy);

  /// The four orthogonal neighbours, in [Direction] order.
  List<GridPos> get neighbours => [for (final d in Direction.values) step(d)];

  int manhattanTo(GridPos other) => (x - other.x).abs() + (y - other.y).abs();

  @override
  bool operator ==(Object other) =>
      other is GridPos && other.x == x && other.y == y;

  @override
  int get hashCode => x * 7919 + y;

  @override
  String toString() => '($x,$y)';
}
