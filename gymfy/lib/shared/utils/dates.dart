// Date helpers shared across features.

/// Strips the time off a [DateTime], returning midnight of the same calendar
/// day. Used so all of a day's rows share one comparable value.
DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Counts consecutive days ending at [today], walking backwards until a gap.
///
/// If today isn't in the set the count starts at yesterday, so a streak isn't
/// broken until a full day has been missed — at 9am you haven't failed to train
/// today, you just haven't trained yet, and a counter that resets overnight
/// would be wrong for most of every day.
int streakEndingAt(Set<DateTime> days, DateTime today) {
  if (days.isEmpty) return 0;

  var cursor = days.contains(today)
      ? today
      : DateTime(today.year, today.month, today.day - 1);

  var count = 0;
  while (days.contains(cursor)) {
    count++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return count;
}

/// The longest run of consecutive days in [days], anywhere in the history.
///
/// The counterpart to [streakEndingAt]: one says how you are doing now, the
/// other what you have ever done. Shown together, the current number stops
/// being a verdict — a short streak beside a long best reads as "you have done
/// this before", which is the opposite of what a lone "3 days" says after a
/// week off.
///
/// Walks the sorted days once and only counts a run from its first day, so the
/// cost is the sort rather than the walk.
int longestStreak(Set<DateTime> days) {
  if (days.isEmpty) return 0;

  final sorted = days.toList()..sort();
  var best = 1;
  var run = 1;

  for (var i = 1; i < sorted.length; i++) {
    final previous = sorted[i - 1];
    final expected = DateTime(previous.year, previous.month, previous.day + 1);
    // Compared as dates rather than with `difference`, which measures elapsed
    // hours and is off by one across a daylight-saving boundary.
    if (sorted[i] == expected) {
      run++;
      if (run > best) best = run;
    } else {
      run = 1;
    }
  }

  return best;
}
