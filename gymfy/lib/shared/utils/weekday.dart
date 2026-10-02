// Labels for ISO-8601 weekdays (1 = Monday … 7 = Sunday).
//
// ISO numbering rather than 0-based, so these line up with `DateTime.weekday`
// and "is this today?" is a plain `==` with no off-by-one to get wrong.
//
// The names take an optional `l10n` like the helpers in format.dart: English
// without it, the language's own names (CLDR, through intl) with it.

import 'dart:ui' show Locale;

import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import 'format.dart';

/// A day that falls on [weekday], for handing to a [DateFormat].
///
/// 1 January 2024 was a Monday, so the first week of that year is ISO order.
DateTime _onWeekday(int weekday) => DateTime(2024, 1, weekday);

/// Every weekday in week order, for building pickers.
const List<int> weekdays = [1, 2, 3, 4, 5, 6, 7];

/// Two letters, e.g. `Mo`. For the seven-across weekday picker, where a full
/// name doesn't fit.
///
/// Two rather than one: a column of M T W T F S S makes Tuesday and Thursday
/// (and Saturday and Sunday) indistinguishable at a glance, which matters when
/// you're tapping to schedule rather than reading.
///
/// German is `Mo`, `Di`, `Mi` …: CLDR's stand-alone abbreviation, which is
/// already two letters there. Any dot a language writes after it is dropped —
/// seven of them across a row of chips are noise.
String weekdayInitial(int weekday, {AppLocalizations? l10n}) {
  final locale = otherDateLocale(l10n);
  if (locale != null) {
    return DateFormat.E(locale).format(_onWeekday(weekday)).replaceAll('.', '');
  }
  return switch (weekday) {
    1 => 'Mo',
    2 => 'Tu',
    3 => 'We',
    4 => 'Th',
    5 => 'Fr',
    6 => 'Sa',
    _ => 'Su',
  };
}

/// Three letters, e.g. `Mon`. For summaries like "Mon, Thu" (German: "Mo,
/// Do").
String weekdayShort(int weekday, {AppLocalizations? l10n}) {
  final locale = otherDateLocale(l10n);
  if (locale != null) return DateFormat.E(locale).format(_onWeekday(weekday));
  return switch (weekday) {
    1 => 'Mon',
    2 => 'Tue',
    3 => 'Wed',
    4 => 'Thu',
    5 => 'Fri',
    6 => 'Sat',
    _ => 'Sun',
  };
}

/// The full name, e.g. `Monday`.
String weekdayName(int weekday, {AppLocalizations? l10n}) {
  final locale = otherDateLocale(l10n);
  if (locale != null) {
    return DateFormat.EEEE(locale).format(_onWeekday(weekday));
  }
  return switch (weekday) {
    1 => 'Monday',
    2 => 'Tuesday',
    3 => 'Wednesday',
    4 => 'Thursday',
    5 => 'Friday',
    6 => 'Saturday',
    _ => 'Sunday',
  };
}

/// A day's schedule as one line, e.g. `Mon, Thu` — or null when it isn't on the
/// calendar at all, so callers can choose their own wording for that.
String? weekdaySummary(List<int> days, {AppLocalizations? l10n}) {
  if (days.isEmpty) return null;
  final sorted = [...days]..sort();
  return sorted.map((day) => weekdayShort(day, l10n: l10n)).join(', ');
}

/// The weekday a week starts on where [locale] is, as an ISO weekday.
///
/// Read from the country, not the language: English in the UK starts on a
/// Monday and English in the US on a Sunday. The table is CLDR's, written out
/// by hand: intl only knows it per locale, and only once the localisation
/// delegates have loaded its data, while this is read from the phone's region
/// whatever language the app is shown in.
///
/// No country, or one not listed, means Monday: the ISO week, and the one the
/// activity heatmap's rows already follow.
int firstWeekdayFor(Locale locale) {
  final country = locale.countryCode?.toUpperCase();
  if (country == null) return DateTime.monday;
  if (_sundayFirst.contains(country)) return DateTime.sunday;
  if (_saturdayFirst.contains(country)) return DateTime.saturday;
  if (country == 'MV') return DateTime.friday;
  return DateTime.monday;
}

const _sundayFirst = {
  'AG', 'AS', 'BD', 'BR', 'BS', 'BT', 'BW', 'BZ', 'CA', 'CN', 'CO', 'DM', //
  'DO', 'ET', 'GT', 'GU', 'HK', 'HN', 'ID', 'IL', 'IN', 'JM', 'JP', 'KE', //
  'KH', 'KR', 'LA', 'MH', 'MM', 'MO', 'MT', 'MX', 'MZ', 'NI', 'NP', 'PA', //
  'PE', 'PH', 'PK', 'PR', 'PT', 'PY', 'SA', 'SG', 'SV', 'TH', 'TT', 'TW', //
  'UM', 'US', 'VE', 'VI', 'WS', 'YE', 'ZA', 'ZW', //
};

const _saturdayFirst = {
  'AE', 'AF', 'BH', 'DJ', 'DZ', 'EG', 'IQ', 'IR', 'JO', 'KW', 'LY', 'OM', //
  'QA', 'SD', 'SY', //
};

/// The seven weekdays in the order a week starting on [first] runs.
List<int> weekdaysFrom(int first) => [
  for (var i = 0; i < 7; i++) (first - 1 + i) % 7 + 1,
];
