// The shape of a month on a calendar: which days go in which cells.
//
// Pure, so the edge cases — a month that starts on the first day of the week,
// one that needs six rows, a week starting on Sunday or Saturday — are tested
// as arithmetic rather than by tapping a grid.

/// The cells of [month]'s grid, row by row, seven to a row, for a week that
/// starts on [firstWeekday] (ISO: 1 = Monday … 7 = Sunday).
///
/// Null cells are the blanks before the 1st and after the last day, so every
/// row is full and every column is one weekday. Never more rows than the month
/// needs: four, five or six.
List<DateTime?> monthGrid(DateTime month, int firstWeekday) {
  final first = DateTime(month.year, month.month);
  final days = DateTime(month.year, month.month + 1, 0).day;
  final leading = (first.weekday - firstWeekday) % 7;

  final cells = <DateTime?>[
    for (var i = 0; i < leading; i++) null,
    for (var day = 1; day <= days; day++)
      DateTime(month.year, month.month, day),
  ];
  while (cells.length % 7 != 0) {
    cells.add(null);
  }
  return cells;
}

/// Midnight on the first of the month [day] is in.
DateTime monthOf(DateTime day) => DateTime(day.year, day.month);
