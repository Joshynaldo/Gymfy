// Reading a workout export from another app.
//
// The layouts here are written to match what Hevy and Strong produce, but the
// importer is deliberately not built around either of them: it matches columns
// by name from a list of aliases. So these tests are about the *behaviour*
// that has to hold whatever the file looks like — the unit is never guessed
// silently, a row that is not a set is skipped rather than invented, and a
// file it cannot read says what it found.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/import/data/import_format.dart';
import 'package:gymfy/shared/utils/units.dart';

/// Shaped like a Hevy export: snake_case, explicit kilograms, a set type.
const _hevy = '''
title,start_time,end_time,exercise_title,set_index,set_type,weight_kg,reps
Push,2026-01-15 18:00:00,2026-01-15 19:05:00,Bench Press,0,warmup,40,10
Push,2026-01-15 18:00:00,2026-01-15 19:05:00,Bench Press,1,normal,80,8
Push,2026-01-15 18:00:00,2026-01-15 19:05:00,Bench Press,2,normal,80,7
Pull,2026-01-17 18:00:00,2026-01-17 19:00:00,Barbell Row,0,normal,70,10
''';

/// Shaped like a Strong export: title case, spaces, and a bare "Weight"
/// column that does not say what unit it is in.
const _strong = '''
Date,Workout Name,Exercise Name,Set Order,Weight,Reps
2026-01-15 18:00:00,Push,Bench Press,1,80,8
2026-01-15 18:00:00,Push,Bench Press,2,80,7
''';

/// Shaped like a StrengthLog export, and every line of it is a lesson from a
/// real one that did not import.
///
/// - `start` is a Unix timestamp in milliseconds, not a date string.
/// - Warm-ups are a boolean `warmup` column, not a set *type*.
/// - Bodyweight work splits into `bodyweight` + `extraWeight`, with the plain
///   `weight` column empty.
/// - The template's unperformed sets are exported as 0 × 0.
/// - Workout names contain commas, so the file genuinely needs a CSV parser.
const _strengthlog = '''
workout,start,end,exercise,weight,bodyweight,extraWeight,distanceM,reps,time,warmup,max,fail
"Push: Chest, Shoulders",1757507640000,1757513236938,Incline Bench Press,30,,,,6,,true,false,false
"Push: Chest, Shoulders",1757507640000,1757513236938,Incline Bench Press,45,,,,7,,false,false,false
"Push: Chest, Shoulders",1757507640000,1757513236938,Leg Extension,0,,,,0,,true,false,false
"Push: Chest, Shoulders",1757507640000,1757513236938,Leg Extension,0,,,,0,,false,false,false
Full,1758114395924,1758116943983,Crunch,,58,10,,8,,false,false,false
Full,1758114395924,1758116943983,Doomscrolling,,,,0,,00:00:00,false,false,false
''';

void main() {
  group('a StrengthLog export', () {
    test('reads its millisecond timestamps as dates', () {
      // The one that decides whether such a file imports at all. Without it
      // every row fails its date, and the screen truthfully reports that a
      // year of training contains no sets.
      final result = parseWorkoutCsv(_strengthlog);

      expect(result.sessions, hasLength(2));
      expect(
        result.sessions.first.start,
        DateTime.fromMillisecondsSinceEpoch(1757507640000),
      );
      expect(
        result.sessions.first.end,
        DateTime.fromMillisecondsSinceEpoch(1757513236938),
      );
    });

    test('reads the boolean warm-up column', () {
      // Not a set *type* string. Read as one, a year of ramp-up sets arrives
      // as working sets — dragging every chart down and feeding progressive
      // overload the lightest set of each exercise as though it counted.
      final sets = parseWorkoutCsv(_strengthlog).sessions.first.sets;

      expect(sets.first.isWarmup, isTrue);
      expect(sets[1].isWarmup, isFalse);
    });

    test('skips the template rows that were never performed', () {
      // An exporter writes out a workout template's planned rows whether or
      // not they happened, so a day cut short leaves sets of 0 × 0. Importing
      // those adds phantom sets and puts 0 kg entries in the charts.
      final result = parseWorkoutCsv(_strengthlog);

      expect(result.exerciseNames, isNot(contains('Leg Extension')));
      expect(result.skippedRows, 3, reason: 'two 0x0 rows and the cardio one');
    });

    test('takes the added load of a bodyweight movement, not the body', () {
      // A weighted crunch at bodyweight 58 plus 10. Gymfy logs bodyweight
      // work as the *added* load; adding the 58 would make it a 68 kg lift
      // and put a personal record on it.
      final crunch = parseWorkoutCsv(_strengthlog).sessions.last.sets
          .firstWhere((s) => s.exerciseName == 'Crunch');

      expect(crunch.weightKg, 10);
      expect(crunch.reps, 8);
    });

    test('keeps a workout name that contains a comma', () {
      // Which is why this file needs a real CSV parser and not a split.
      expect(
        parseWorkoutCsv(_strengthlog).sessions.first.name,
        'Push: Chest, Shoulders',
      );
    });

    test('does not claim to know the unit', () {
      // StrengthLog's column is just `weight`. The screen has to ask.
      expect(parseWorkoutCsv(_strengthlog).unitWasStated, isFalse);
    });

    test('is recognised by name', () {
      expect(parseWorkoutCsv(_strengthlog).source, 'StrengthLog');
    });
  });

  group('recognising where a file came from', () {
    // Recognition only: nothing depends on the answer and an unrecognised
    // file still imports on its column names. It is shown on the preview
    // because that is the moment somebody commits a year of training.
    test('names the apps it knows', () {
      expect(parseWorkoutCsv(_hevy).source, 'Hevy');
      expect(parseWorkoutCsv(_strong).source, 'Strong');
    });

    test('an unfamiliar file still imports, just unnamed', () {
      const csv = '''
Date,Exercise,Weight,Reps
2026-01-15 18:00:00,Bench Press,80,8
''';
      final result = parseWorkoutCsv(csv);

      expect(result.source, isNull);
      expect(result.setCount, 1);
    });
  });

  group('a unit column per row', () {
    // FitNotes on Android writes one. A history that switched units halfway
    // through — someone who travelled, or changed the setting — would
    // otherwise have half of it silently rescaled.
    const mixed = '''
Date,Exercise,Weight,Weight Unit,Reps
2026-01-15 18:00:00,Bench Press,100,kg,5
2026-01-22 18:00:00,Bench Press,225,lbs,5
''';

    test('each row converts by its own unit', () {
      final result = parseWorkoutCsv(mixed, assumedUnit: WeightUnit.kg);

      expect(result.sessions.first.sets.single.weightKg, 100);
      expect(result.sessions.last.sets.single.weightKg, closeTo(102.06, 0.01));
    });

    test('counts as the file stating its unit, so the screen stops asking', () {
      expect(parseWorkoutCsv(mixed).unitWasStated, isTrue);
    });

    test('a row that says nothing falls back to the file', () {
      const partial = '''
Date,Exercise,Weight,Weight Unit,Reps
2026-01-15 18:00:00,Bench Press,100,,5
''';
      final result = parseWorkoutCsv(partial, assumedUnit: WeightUnit.lbs);

      expect(result.sessions.single.sets.single.weightKg, closeTo(45.36, 0.01));
    });
  });

  group('a file that names its unit', () {
    test('reads the sets, grouped into workouts', () {
      final result = parseWorkoutCsv(_hevy);

      expect(result.sessions, hasLength(2));
      expect(result.sessions.first.name, 'Push');
      expect(result.sessions.first.sets, hasLength(3));
      expect(result.sessions.last.name, 'Pull');
      expect(result.setCount, 4);
    });

    test('is read as kilograms whatever the caller assumed', () {
      // The file said `weight_kg`. An assumption must never override a fact —
      // getting this backwards would multiply a whole history by 2.2.
      final result = parseWorkoutCsv(_hevy, assumedUnit: WeightUnit.lbs);

      expect(result.unit, WeightUnit.kg);
      expect(result.unitWasStated, isTrue);
      expect(result.sessions.first.sets[1].weightKg, 80);
    });

    test('keeps the warm-up flag where the file states one', () {
      final sets = parseWorkoutCsv(_hevy).sessions.first.sets;

      expect(sets[0].isWarmup, isTrue);
      expect(sets[1].isWarmup, isFalse);
    });

    test('sessions come back oldest first', () {
      // So importing in order gives sessions increasing ids, and "last
      // workout" means what it says afterwards.
      final result = parseWorkoutCsv(_hevy);

      expect(
        result.sessions.first.start.isBefore(result.sessions.last.start),
        isTrue,
      );
    });

    test('carries the end time through', () {
      final session = parseWorkoutCsv(_hevy).sessions.first;

      expect(session.end, DateTime(2026, 1, 15, 19, 5));
    });
  });

  group('a file that does not name its unit', () {
    test('takes the caller word for it, and says that it did', () {
      final result = parseWorkoutCsv(_strong, assumedUnit: WeightUnit.lbs);

      expect(result.unit, WeightUnit.lbs);
      expect(
        result.unitWasStated,
        isFalse,
        reason: 'the UI has to be able to warn that this was an assumption',
      );
      // 80 lbs stored as kilograms.
      expect(result.sessions.first.sets.first.weightKg, closeTo(36.29, 0.01));
    });

    test('and converts nothing when told kilograms', () {
      final result = parseWorkoutCsv(_strong, assumedUnit: WeightUnit.kg);

      expect(result.sessions.first.sets.first.weightKg, 80);
    });
  });

  group('rows that are not sets', () {
    test('are skipped and counted, not invented', () {
      // A summary line, a cardio row logged by distance, a blank. Turning
      // these into zero-rep sets would put phantom work in the history.
      const csv = '''
Date,Exercise Name,Weight,Reps
2026-01-15 18:00:00,Bench Press,80,8
2026-01-15 18:00:00,Treadmill,,
,,,
2026-01-15 18:00:00,Bench Press,80,7
''';
      final result = parseWorkoutCsv(csv);

      expect(result.setCount, 2);
      expect(result.skippedRows, 2);
    });

    test('a bodyweight set is kept at zero, not skipped', () {
      // No *added* load is a fact about the set, and the reps are real.
      const csv = '''
Date,Exercise Name,Weight,Reps
2026-01-15 18:00:00,Pull Up,,12
''';
      final result = parseWorkoutCsv(csv);

      expect(result.setCount, 1);
      expect(result.sessions.single.sets.single.weightKg, 0);
      expect(result.sessions.single.sets.single.reps, 12);
    });
  });

  group('a file it cannot read', () {
    test('says what was missing and what it found', () {
      // The only genuinely useful thing to say. It turns "it did not work"
      // into something the user can forward and a one-line fix here.
      const csv = 'Foo,Bar\n1,2';

      expect(
        () => parseWorkoutCsv(csv),
        throwsA(
          isA<ImportFormatException>().having(
            (e) => e.message,
            'message',
            allOf(contains('Foo, Bar'), contains('exercise name')),
          ),
        ),
      );
    });
  });

  group('isTrueish', () {
    test('accepts the spellings exporters use for yes', () {
      for (final raw in ['true', 'TRUE', '1', 'yes', 'y']) {
        expect(isTrueish(raw), isTrue, reason: raw);
      }
    });

    test('everything else, empty included, is no', () {
      for (final raw in ['false', '0', 'no', '', 'maybe']) {
        expect(isTrueish(raw), isFalse, reason: raw);
      }
    });
  });

  group('parseImportDate', () {
    test('reads a Unix timestamp in milliseconds', () {
      expect(
        parseImportDate('1757507640000'),
        DateTime.fromMillisecondsSinceEpoch(1757507640000),
      );
    });

    test('reads a Unix timestamp in seconds', () {
      expect(
        parseImportDate('1757507640'),
        DateTime.fromMillisecondsSinceEpoch(1757507640000),
      );
    });

    test('a short number is not a timestamp', () {
      // A stray "2026" in a date column must not become January 1970 — a
      // silently wrong date reshapes every chart that counts by week.
      expect(parseImportDate('2026'), isNull);
      expect(parseImportDate('12345'), isNull);
    });

    test('reads ISO and the space-separated form exporters write', () {
      expect(parseImportDate('2026-01-15T18:30:00'), DateTime(2026, 1, 15, 18, 30));
      expect(parseImportDate('2026-01-15 18:30:00'), DateTime(2026, 1, 15, 18, 30));
    });

    test('reads a day-first European date', () {
      expect(parseImportDate('15/01/2026 18:30'), DateTime(2026, 1, 15, 18, 30));
      expect(parseImportDate('15.01.2026, 18:30'), DateTime(2026, 1, 15, 18, 30));
    });

    test('a date with no time is midnight, not a failure', () {
      expect(parseImportDate('15.01.2026'), DateTime(2026, 1, 15));
    });

    test('refuses what it cannot read rather than guessing', () {
      // A wrong date puts a workout in the wrong week and quietly reshapes
      // every chart that counts by week.
      expect(parseImportDate('last Tuesday'), isNull);
      expect(parseImportDate(''), isNull);
    });
  });

  group('isWarmupType', () {
    test('recognises the spellings that mean it', () {
      for (final raw in ['warmup', 'Warm Up', 'WARM-UP']) {
        expect(isWarmupType(raw), isTrue, reason: raw);
      }
    });

    test('anything else is a working set', () {
      // The safe direction: calling a real set a warm-up drops it out of
      // every chart and every personal record.
      for (final raw in ['normal', 'failure', 'drop set', '', 'top set']) {
        expect(isWarmupType(raw), isFalse, reason: raw);
      }
    });
  });
}
