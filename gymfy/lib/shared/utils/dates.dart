// Date helpers shared across features.

/// Strips the time off a [DateTime], returning midnight of the same calendar
/// day. Used so all of a day's rows (calorie entries, habit completions) share
/// one comparable value.
DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
