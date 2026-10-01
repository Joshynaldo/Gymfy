// Supersets: planned exercises done back to back, with rest only after the
// last one.
//
// Stored as a shared `superset_group` number on the planned exercises (see
// workout_plan.dart). These two functions are how every screen reads it, so
// the rules about what makes a group live in one place:
//
// - Only exercises *next to each other* in order form a group. Two members
//   split apart by a standalone exercise are two groups, not one — a superset
//   you have to walk across the gym in the middle of is not a superset.
// - A group of one is just an exercise. Removing a partner shouldn't leave the
//   survivor behaving differently from any other standalone exercise.
//
// Generic over the item type, because the plan (PlannedExercise) and a running
// session (SessionExerciseEntry) both need it and differ only in where the
// group number sits.

/// Splits an ordered list into the blocks it is performed in: each superset
/// is one block, each standalone exercise a block of its own.
///
/// [groupOf] reads an item's superset group (null for standalone).
List<List<T>> supersetBlocks<T>(List<T> ordered, int? Function(T) groupOf) {
  final blocks = <List<T>>[];
  int? openGroup;
  for (final item in ordered) {
    final group = groupOf(item);
    if (group != null && group == openGroup) {
      blocks.last.add(item);
    } else {
      blocks.add([item]);
    }
    openGroup = group;
  }
  return blocks;
}

/// Whether the rest timer should start after a set of [item] — true unless
/// another member of its superset still follows it.
///
/// An item not found in [ordered] rests, which is the behaviour before
/// supersets existed and the safe default.
bool restsAfter<T>(List<T> ordered, T item, int? Function(T) groupOf) {
  for (final block in supersetBlocks(ordered, groupOf)) {
    final index = block.indexOf(item);
    if (index != -1) return index == block.length - 1;
  }
  return true;
}
