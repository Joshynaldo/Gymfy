// Formatting helpers shared across features.

const _monthAbbr = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats a weight for display: whole numbers show without a decimal (60),
/// fractional plates show one decimal place (62.5). Keeps the UI tidy while
/// still supporting half-kilo / half-pound increments.
String formatWeight(double weight) {
  return weight == weight.roundToDouble()
      ? weight.toStringAsFixed(0)
      : weight.toStringAsFixed(1);
}

/// Parses a user-typed weight, accepting a comma as the decimal separator
/// (German keyboards put comma on the number row). Returns null for anything
/// that isn't a positive number.
///
/// Unit-agnostic: this just reads the number. Use `parseWeightAsKilograms` in
/// `units.dart` when the value is going into the database, so a weight typed in
/// pounds isn't stored as kilograms.
double? parseWeight(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  if (value == null || value <= 0) return null;
  return value;
}

/// Formats a date + time like "23 Jul 2026 • 18:05". Kept dependency-free (no
/// intl package) since the app is single-locale for now.
String formatDateTime(DateTime dt) {
  final day = dt.day;
  final month = _monthAbbr[dt.month - 1];
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$day $month ${dt.year} • $hh:$mm';
}

/// Formats a short day + month like "23 Jul" — used for chart axis labels.
String formatShortDate(DateTime dt) => '${dt.day} ${_monthAbbr[dt.month - 1]}';

const _weekdayAbbr = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// Formats just the weekday like "Fri" — used by the weekly chart axes.
String formatWeekdayAbbr(DateTime day) => _weekdayAbbr[day.weekday - 1];

/// Formats a day like "Fri 24 Jul", or "Today" / "Yesterday" relative to
/// [today] (defaults to now). Used by the day-by-day tracking screens.
String formatDayLabel(DateTime day, {DateTime? today}) {
  final ref = today ?? DateTime.now();
  final refDay = DateTime(ref.year, ref.month, ref.day);
  final target = DateTime(day.year, day.month, day.day);
  final diff = target.difference(refDay).inDays;
  if (diff == 0) return 'Today';
  if (diff == -1) return 'Yesterday';
  // DateTime.weekday is 1 (Mon) .. 7 (Sun).
  return '${_weekdayAbbr[day.weekday - 1]} '
      '${day.day} ${_monthAbbr[day.month - 1]}';
}

/// Formats a duration compactly: "45 min" under an hour, otherwise "1 h 05 min".
String formatDuration(Duration d) {
  final totalMinutes = d.inMinutes;
  if (totalMinutes < 60) return '$totalMinutes min';
  final hours = totalMinutes ~/ 60;
  final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
  return '$hours h $minutes min';
}

/// Formats a rep target: `10` for a fixed number, `8–12` for a range.
///
/// A null [max] means no range. An en dash rather than a hyphen — it's the
/// range dash, and at small text sizes a hyphen reads as a minus sign.
String formatRepTarget(int reps, int? max) =>
    max == null || max <= reps ? '$reps' : '$reps–$max';

/// Formats a full set target, e.g. `3 × 10` or `3 × 8–12`.
String formatSetTarget(int sets, int reps, int? max) =>
    '$sets × ${formatRepTarget(reps, max)}';
