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

/// Where a running superset goes after a *working* set of [item]: whether the
/// rest timer starts, and which member the card moves to.
///
/// Null when [item] is not in a superset — it rests like any other exercise,
/// and the card stays where it is.
///
/// [hasSetsLeft] says whether a member still has planned working sets to do,
/// counting the set just logged. The rules:
///
/// - The card goes straight on, without rest, to the next member *after*
///   [item] that still has sets left. A member already finished is skipped:
///   with four planned sets of one and three of the other, the fourth set of
///   the first has no partner left to go to.
/// - With no member after it left to do, the round is over: rest, and the
///   card goes back to the first member that still has sets left. [next] is
///   null when none has — the superset is done.
///
/// Warm-ups never come through here: you ramp one exercise up on its own
/// before the rounds start, so the card should not bounce between partners.
({bool rests, T? next})? supersetStepAfter<T>(
  List<T> ordered,
  T item,
  int? Function(T) groupOf, {
  required bool Function(T) hasSetsLeft,
}) {
  for (final block in supersetBlocks(ordered, groupOf)) {
    final index = block.indexOf(item);
    if (index == -1) continue;
    if (block.length < 2) return null;

    for (final later in block.skip(index + 1)) {
      if (hasSetsLeft(later)) return (rests: false, next: later);
    }
    for (final member in block) {
      if (hasSetsLeft(member)) return (rests: true, next: member);
    }
    return (rests: true, next: null);
  }
  return null;
}
