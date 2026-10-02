// The shared formatting helpers in a second language: German dates, German
// separators, German words — and English left exactly as it was.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/home/data/recap.dart';
import 'package:gymfy/features/home/widgets/next_up_card.dart';
import 'package:gymfy/l10n/l10n.dart';
import 'package:gymfy/shared/models/equipment.dart';
import 'package:gymfy/shared/models/muscle_ids.dart';
import 'package:gymfy/shared/models/set_type.dart';
import 'package:gymfy/shared/utils/exercise_display.dart';
import 'package:gymfy/shared/utils/format.dart';
import 'package:gymfy/shared/utils/units.dart';
import 'package:gymfy/shared/utils/weekday.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final de = lookupAppLocalizations(const Locale('de'));

  // In the app the Material localisations delegate loads the date symbols. A
  // unit test has no delegate, so it loads them itself.
  setUpAll(() => initializeDateFormatting('de'));

  group('dates', () {
    final day = DateTime(2026, 10, 3, 18, 5); // a Saturday

    test('English reads as it always has, with or without l10n', () {
      for (final l10n in [null, en]) {
        expect(formatDate(day, l10n: l10n), '3 Oct 2026');
        expect(formatShortDate(day, l10n: l10n), '3 Oct');
        expect(formatDateTime(day, l10n: l10n), '3 Oct 2026 • 18:05');
        expect(formatMonthName(day, l10n: l10n), 'October');
        expect(formatMonthYear(day, l10n: l10n), 'October 2026');
        expect(formatMonthAbbr(day, l10n: l10n), 'Oct');
        expect(formatWeekdayAbbr(day, l10n: l10n), 'Sat');
      }
    });

    test('German is written the German way', () {
      expect(formatDate(day, l10n: de), '3. Okt. 2026');
      expect(formatShortDate(day, l10n: de), '3. Okt.');
      expect(formatDateTime(day, l10n: de), '3. Okt. 2026 • 18:05');
      expect(formatMonthName(day, l10n: de), 'Oktober');
      expect(formatMonthYear(day, l10n: de), 'Oktober 2026');
      expect(formatWeekdayAbbr(day, l10n: de), 'Sa');
    });

    test('today and yesterday are words, in the language', () {
      final today = DateTime(2026, 10, 3);
      expect(formatDayLabel(today, today: today, l10n: de), 'Heute');
      expect(
        formatDayLabel(DateTime(2026, 10, 2), today: today, l10n: de),
        'Gestern',
      );
      expect(
        formatDayLabel(DateTime(2026, 9, 25), today: today, l10n: de),
        'Fr., 25. Sept.',
      );
      expect(formatDayLabel(DateTime(2026, 9, 25), today: today), 'Fri 25 Sep');
    });
  });

  group('weekdays', () {
    test('English is unchanged', () {
      expect(weekdayName(1), 'Monday');
      expect(weekdayName(1, l10n: en), 'Monday');
      expect(weekdayInitial(2, l10n: en), 'Tu');
      expect(weekdaySummary([4, 1], l10n: en), 'Mon, Thu');
    });

    test('German names, and initials without the dot', () {
      expect(weekdayName(1, l10n: de), 'Montag');
      expect(weekdayName(7, l10n: de), 'Sonntag');
      expect(
        [for (final d in weekdays) weekdayInitial(d, l10n: de)],
        ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'],
      );
      expect(weekdaySummary([4, 1], l10n: de), 'Mo, Do');
    });

    test('the next-up label speaks German', () {
      expect(relativeDayLabel(1, 3, l10n: de), 'Morgen');
      expect(relativeDayLabel(3, 4, l10n: de), 'Donnerstag');
      expect(relativeDayLabel(7, 1, l10n: de), 'Nächsten Montag');
      expect(relativeDayLabel(7, 1), 'Next Monday');
    });

    test('the week bars get German letters', () {
      // 6 October 2026 is a Tuesday: D(ienstag), where English says T.
      final tuesday = DateTime(2026, 10, 6);
      expect(bucketLabel(tuesday, RecapGrain.day), 'T');
      expect(bucketLabel(tuesday, RecapGrain.day, l10n: de), 'D');
      expect(bucketLabel(tuesday, RecapGrain.month, l10n: de), 'O');
      expect(bucketLabel(tuesday, RecapGrain.week, l10n: de), '6');
    });
  });

  group('numbers', () {
    test('English separators stay as they were', () {
      expect(formatWeight(62.5, l10n: en), '62.5');
      expect(formatWeight(41040, l10n: en), '41,040');
      expect(formatWeight(1234.5, l10n: en), '1,234.5');
    });

    test('German swaps the separators, not the digits', () {
      expect(formatWeight(62.5, l10n: de), '62,5');
      expect(formatWeight(41040, l10n: de), '41.040');
      expect(formatWeight(1234.5, l10n: de), '1.234,5');
      expect(formatWeight(60, l10n: de), '60');
      expect(decimalSeparator(l10n: de), ',');
      expect(decimalSeparator(), '.');
    });

    test('a weight with its unit, and a logged set', () {
      expect(formatWeightUnit(62.5, WeightUnit.kg, l10n: de), '62,5 kg');
      expect(
        formatLoggedSet(
          weightKg: 82.5,
          reps: 8,
          seconds: null,
          unit: WeightUnit.kg,
          l10n: de,
        ),
        '82,5 kg × 8 Wdh.',
      );
      expect(
        formatLoggedSet(
          weightKg: 82.5,
          reps: 8,
          seconds: null,
          unit: WeightUnit.kg,
        ),
        '82.5 kg × 8 reps',
      );
    });

    test('the add-to-day message counts in German', () {
      expect(
        addedToDayMessage(added: 1, asked: 1, l10n: de),
        '1 Übung hinzugefügt',
      );
      expect(
        addedToDayMessage(added: 3, asked: 4, l10n: de),
        '3 Übungen hinzugefügt – 1 schon vorhanden',
      );
      expect(
        addedToDayMessage(added: 0, asked: 2, l10n: de),
        'Alle 2 waren schon in diesem Tag',
      );
      expect(
        addedToDayMessage(added: 3, asked: 4),
        '3 exercises added — 1 already there',
      );
    });
  });

  group('names from the shared models', () {
    test('every muscle has a German name', () {
      for (final id in MuscleId.all) {
        expect(muscleLabel(id, l10n: en), muscleLabel(id), reason: id);
        expect(muscleLabel(id, l10n: de), isNot(isEmpty), reason: id);
      }
      expect(muscleLabel(MuscleId.frontDeltoid, l10n: de), 'Vordere Schulter');
      expect(muscleLabel(MuscleId.hamstrings, l10n: de), 'Beinbeuger');
    });

    test('an id the app does not know falls back to its title case', () {
      expect(muscleLabel('serratus_anterior', l10n: de), 'Serratus Anterior');
    });

    test('equipment and set types, English matching their old labels', () {
      for (final equipment in Equipment.values) {
        expect(equipment.localizedLabel(en), equipment.label);
      }
      for (final type in SetType.values) {
        expect(type.localizedLabel(en), type.label);
      }
      expect(Equipment.barbell.localizedLabel(de), 'Langhantel');
      expect(Equipment.cable.localizedLabel(de), 'Kabelzug');
      expect(SetType.warmup.localizedLabel(de), 'Aufwärmsatz');
    });
  });
}
