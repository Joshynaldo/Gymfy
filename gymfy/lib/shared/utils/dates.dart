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
