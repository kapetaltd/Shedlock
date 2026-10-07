import 'food.dart';
import 'grid_pos.dart';

/// Things that happened during a tick. The rendering layer turns these into
/// animations, sound and haptics; it never inspects state diffs itself.
sealed class GameEvent {
  const GameEvent();
}

class FoodEaten extends GameEvent {
  const FoodEaten(this.food, this.points);
  final Food food;
  final int points;
}

class FoodSpawned extends GameEvent {
  const FoodSpawned(this.food);
  final Food food;
}

class Shed extends GameEvent {
  const Shed(this.wallCells);
  final List<GridPos> wallCells;
}

enum ShedDeniedReason { tooShort, cooldown }

class ShedDenied extends GameEvent {
  const ShedDenied(this.reason);
  final ShedDeniedReason reason;
}

class WallsExpired extends GameEvent {
  const WallsExpired(this.cells);
  final List<GridPos> cells;
}

class RunnerMoved extends GameEvent {
  const RunnerMoved(this.foodId, this.from, this.to);
  final int foodId;
  final GridPos from;
  final GridPos to;
}

class RunnerLocked extends GameEvent {
  const RunnerLocked(this.food, this.bonus);
  final Food food;
  final int bonus;
}

enum DeathCause { wall, obstacle, shedWall, self }

class Died extends GameEvent {
  const Died(this.cause, this.at);
  final DeathCause cause;

  /// The cell the head tried to enter.
  final GridPos at;
}
