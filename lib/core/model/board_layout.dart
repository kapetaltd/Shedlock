import 'grid_pos.dart';

/// The fixed part of a board: its size and static obstacles.
class BoardLayout {
  BoardLayout({
    required this.width,
    required this.height,
    Set<GridPos> obstacles = const {},
  }) : obstacles = Set.unmodifiable(obstacles);

  final int width;
  final int height;
  final Set<GridPos> obstacles;

  bool inBounds(GridPos p) => p.x >= 0 && p.y >= 0 && p.x < width && p.y < height;

  bool isObstacle(GridPos p) => obstacles.contains(p);

  int get cellCount => width * height;

  /// Row-major index of [p].
  int indexOf(GridPos p) => p.y * width + p.x;

  GridPos posOf(int index) => GridPos(index % width, index ~/ width);
}
