// Formatting helpers shared across features.
//
// The ones that print dates, numbers or words take an optional `l10n` — pass
// `context.l10n`. Without it they format exactly as the app always has:
// English, day first, "3 Oct 2026", "41,040". With it they format for that
// language, so German reads "3. Okt. 2026" and "41.040". Optional so one
// helper serves a widget, a test, and code that has to stay language-neutral
// (an export file, a file name).

import 'package:intl/intl.dart';
import 'package:intl/number_symbols_data.dart';

import '../../l10n/l10n.dart';

/// The locale to format dates in when it isn't the app's English, else null.
///
/// Null means "use the hand-written English": callers keep their own English
/// patterns, which are what the app has always shown, and hand anything else
/// to intl's CLDR data for this locale.
///
/// English keeps the app's own day-first patterns, formatted with the en_US
/// symbols intl carries built in — the one locale it can format without
/// loading anything, which is all a widget test with no localisation delegates
/// has. Every other language uses its CLDR skeleton, so German comes out the
/// way German is written without a pattern spelled out here.
///
/// The other languages' symbols arrive with the Material localisations
/// delegate. Before that (a bare widget test, a unit test that didn't load
/// them) formatting in that locale would throw, so it stays English instead.
String? otherDateLocale(AppLocalizations? l10n) {
  final name = l10n?.localeName;
  if (name == null || name == 'en' || name.startsWith('en_')) return null;
  try {
    return DateFormat.localeExists(name) ? name : null;
  } catch (_) {
    return null;
  }
}

/// [english] with its separators swapped for [l10n]'s: `41,040.5` becomes
/// `41.040,5` in German.
///
/// The digits are worked out once, in English, by the callers — only the
/// punctuation belongs to the language.
String _localiseSeparators(String english, AppLocalizations? l10n) {
  final name = l10n?.localeName;
  if (name == null) return english;
  final symbols =
      numberFormatSymbols[name] ?? numberFormatSymbols[name.split('_').first];
  if (symbols == null) return english;
  final group = symbols.GROUP_SEP;
  final decimal = symbols.DECIMAL_SEP;
  if (group == ',' && decimal == '.') return english;
  final buffer = StringBuffer();
  for (final char in english.split('')) {
    buffer.write(switch (char) {
      ',' => group,
      '.' => decimal,
      _ => char,
    });
  }
  return buffer.toString();
}

/// The decimal separator [l10n]'s language writes: `.` in English, `,` in
/// German.
///
/// For numbers put together a piece at a time, like the ".25" drum beside a
/// weight wheel's whole number, where [formatWeight] doesn't apply.
String decimalSeparator({AppLocalizations? l10n}) =>
    _localiseSeparators('.', l10n);

/// [value] with exactly [fractionDigits] decimals, in [l10n]'s separators:
/// "1.25" in English, "1,25" in German.
///
/// For ratios, multipliers and averages — "1.25× bodyweight", "2.3× a rhino"
/// — which are never big enough to need grouping. A weight goes through
/// [formatWeight].
String formatDecimal(
  double value,
  int fractionDigits, {
  AppLocalizations? l10n,
}) => _localiseSeparators(value.toStringAsFixed(fractionDigits), l10n);

/// Formats a weight for display: whole numbers show without a decimal (60),
/// fractional plates show one decimal place (62.5). Keeps the UI tidy while
/// still supporting half-kilo / half-pound increments.
///
/// Thousands are grouped, because a weight on the bar and a season's volume are
/// the same function's output: "62.5" needs nothing, and "41040" is a number you
/// have to count the digits of. Grouping is what makes the second readable at a
/// glance, and it costs the first nothing. In German the same two read "62,5"
/// and "41.040".
String formatWeight(double weight, {AppLocalizations? l10n}) {
  final text = weight == weight.roundToDouble()
      ? weight.toStringAsFixed(0)
      : weight.toStringAsFixed(1);
  return _localiseSeparators(_groupThousands(text), l10n);
}

/// Puts a comma every three digits, left of the decimal point.
///
/// By hand rather than through `NumberFormat`: the digits have to be exactly
/// the ones `toStringAsFixed` gives above, and a pattern rounds by rules of its
/// own. Only the separators are left to the language.
String _groupThousands(String number) {
  final dot = number.indexOf('.');
  final whole = dot == -1 ? number : number.substring(0, dot);
  final rest = dot == -1 ? '' : number.substring(dot);
  if (whole.length <= 3) return number;

  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    // Counted from the right: the first group is whatever is left over.
    final fromRight = whole.length - i;
    if (i > 0 && fromRight % 3 == 0) buffer.write(',');
    buffer.write(whole[i]);
  }
  return '$buffer$rest';
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

/// Formats a date + time like "23 Jul 2026 • 18:05" (German: "23. Juli 2026 •
/// 18:05").
String formatDateTime(DateTime dt, {AppLocalizations? l10n}) {
  final locale = otherDateLocale(l10n);
  if (locale == null) return DateFormat('d MMM y • HH:mm', 'en_US').format(dt);
  return '${DateFormat.yMMMd(locale).format(dt)} • '
      '${DateFormat.Hm(locale).format(dt)}';
}

/// Formats a short day + month like "23 Jul" — used for chart axis labels.
String formatShortDate(DateTime dt, {AppLocalizations? l10n}) {
  final locale = otherDateLocale(l10n);
  final format = locale == null
      ? DateFormat('d MMM', 'en_US')
      : DateFormat.MMMd(locale);
  return format.format(dt);
}

/// Just the month, like "Jul" — used along the top of the activity heatmap.
String formatMonthAbbr(DateTime dt, {AppLocalizations? l10n}) {
  final locale = otherDateLocale(l10n);
  final format = locale == null
      ? DateFormat('MMM', 'en_US')
      : DateFormat.LLL(locale);
  return format.format(dt);
}

/// The month's full name, like "September" — for headings, where there is
/// room to spell it out.
String formatMonthName(DateTime dt, {AppLocalizations? l10n}) {
  final locale = otherDateLocale(l10n);
  final format = locale == null
      ? DateFormat('MMMM', 'en_US')
      : DateFormat.LLLL(locale);
  return format.format(dt);
}

/// Month and year, like "September 2026" — the calendar's and the monthly
/// review's heading.
String formatMonthYear(DateTime dt, {AppLocalizations? l10n}) {
  final locale = otherDateLocale(l10n);
  final format = locale == null
      ? DateFormat('MMMM y', 'en_US')
      : DateFormat.yMMMM(locale);
  return format.format(dt);
}

/// A short date with the year, like "3 Oct 2026" — for a day that may not be
/// in this year, such as a goal's deadline.
String formatDate(DateTime dt, {AppLocalizations? l10n}) {
  final locale = otherDateLocale(l10n);
  final format = locale == null
      ? DateFormat('d MMM y', 'en_US')
      : DateFormat.yMMMd(locale);
  return format.format(dt);
}

/// Formats just the weekday like "Fri" — used by the weekly chart axes.
String formatWeekdayAbbr(DateTime day, {AppLocalizations? l10n}) {
  final locale = otherDateLocale(l10n);
  final format = locale == null
      ? DateFormat('EEE', 'en_US')
      : DateFormat.E(locale);
  return format.format(day);
}

/// Formats a day like "Fri 24 Jul", or "Today" / "Yesterday" relative to
/// [today] (defaults to now). Used by the day-by-day tracking screens.
String formatDayLabel(DateTime day, {DateTime? today, AppLocalizations? l10n}) {
  final ref = today ?? DateTime.now();
  final refDay = DateTime(ref.year, ref.month, ref.day);
  final target = DateTime(day.year, day.month, day.day);
  final diff = target.difference(refDay).inDays;
  final strings = l10n ?? englishLocalizations;
  if (diff == 0) return strings.commonToday;
  if (diff == -1) return strings.commonYesterday;
  final locale = otherDateLocale(l10n);
  final format = locale == null
      ? DateFormat('EEE d MMM', 'en_US')
      : DateFormat.MMMEd(locale);
  return format.format(day);
}

/// Formats a duration compactly: "45 min" under an hour, otherwise "1 h 05 min".
///
/// The same in German: `min` and `h` are unit symbols, not English words.
String formatDuration(Duration d) {
  final totalMinutes = d.inMinutes;
  if (totalMinutes < 60) return '$totalMinutes min';
  final hours = totalMinutes ~/ 60;
  final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
  return '$hours h $minutes min';
}

/// Formats how long a set was held: `0:45`, `1:30`, `12:05`.
///
/// Not [formatDuration], which rounds to whole minutes for session lengths —
/// a 45-second plank would read as "0 min" there, and the seconds are the
/// whole content of a timed set.
String formatSetDuration(int seconds) {
  final minutes = seconds ~/ 60;
  return '$minutes:${(seconds % 60).toString().padLeft(2, '0')}';
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

/// Describes the result of adding exercises to a workout day.
///
/// `addExercisesToDay` skips exercises the day already has, so a flat
/// "4 exercises added" would sometimes be a lie. Shared by the Exercises tab's
/// bulk add and the day builder's picker, so both report it the same way.
String addedToDayMessage({
  required int added,
  required int asked,
  AppLocalizations? l10n,
}) {
  final strings = l10n ?? englishLocalizations;
  if (added == 0) return strings.sharedAddedToDayNone(asked);
  final addedText = strings.sharedAddedToDayAdded(added);
  final skipped = asked - added;
  return skipped == 0
      ? addedText
      : strings.sharedAddedToDaySkipped(addedText, skipped);
}
