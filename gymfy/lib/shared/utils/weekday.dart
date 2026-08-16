// Labels for ISO-8601 weekdays (1 = Monday … 7 = Sunday).
//
// ISO numbering rather than 0-based, so these line up with `DateTime.weekday`
// and "is this today?" is a plain `==` with no off-by-one to get wrong.

/// Every weekday in week order, for building pickers.
const List<int> weekdays = [1, 2, 3, 4, 5, 6, 7];

/// Two letters, e.g. `Mo`. For the seven-across weekday picker, where a full
/// name doesn't fit.
///
/// Two rather than one: a column of M T W T F S S makes Tuesday and Thursday
/// (and Saturday and Sunday) indistinguishable at a glance, which matters when
/// you're tapping to schedule rather than reading.
String weekdayInitial(int weekday) => switch (weekday) {
  1 => 'Mo',
  2 => 'Tu',
  3 => 'We',
  4 => 'Th',
  5 => 'Fr',
  6 => 'Sa',
  _ => 'Su',
};

/// Three letters, e.g. `Mon`. For summaries like "Mon, Thu".
String weekdayShort(int weekday) => switch (weekday) {
  1 => 'Mon',
  2 => 'Tue',
  3 => 'Wed',
  4 => 'Thu',
  5 => 'Fri',
  6 => 'Sat',
  _ => 'Sun',
};

/// The full name, e.g. `Monday`.
String weekdayName(int weekday) => switch (weekday) {
  1 => 'Monday',
  2 => 'Tuesday',
  3 => 'Wednesday',
  4 => 'Thursday',
  5 => 'Friday',
  6 => 'Saturday',
  _ => 'Sunday',
};

/// A day's schedule as one line, e.g. `Mon, Thu` — or null when it isn't on the
/// calendar at all, so callers can choose their own wording for that.
String? weekdaySummary(List<int> days) {
  if (days.isEmpty) return null;
  final sorted = [...days]..sort();
  return sorted.map(weekdayShort).join(', ');
}
