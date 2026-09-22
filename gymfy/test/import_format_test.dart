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

/// Shaped like a Hevy export: snake_case, explicit kilograms, a set type, and
/// — the part that mattered — dates with the month spelled out in the
/// language of the phone that exported them.
///
/// This fixture used to write `2026-01-15 18:00:00`, which reads cleanly and
/// which Hevy has never produced. Every test passed and every real Hevy export
/// imported as zero workouts. A fixture that is easier to read than the thing
/// it stands for is not a test of anything.
const _hevy = '''
title,start_time,end_time,exercise_title,set_index,set_type,weight_kg,reps
Push,"15 Jan. 2026, 18:00","15 Jan. 2026, 19:05",Bench Press,0,warmup,40,10
Push,"15 Jan. 2026, 18:00","15 Jan. 2026, 19:05",Bench Press,1,normal,80,8
Push,"15 Jan. 2026, 18:00","15 Jan. 2026, 19:05",Bench Press,2,normal,80,7
Pull,"17 Jan. 2026, 18:00","17 Jan. 2026, 19:00",Barbell Row,0,normal,70,10
''';

/// Lines copied verbatim out of a real Hevy export — full header, quoting,
/// empty columns and German month names as the file has them.
///
/// Kept alongside the tidied [_hevy] because the two failures this feature has
/// had were both things a hand-written fixture cannot show: a column shape
/// nobody expected, and a date format nobody had looked at. The real file is
/// the only witness to either.
const _hevyReal =
    '"title","start_time","end_time","description","exercise_title",'
    '"superset_id","exercise_notes","set_index","set_type","weight_kg",'
    '"reps","distance_km","duration_seconds","rpe"\n'
    '"Torso 2 (Schwachstellen)","18 Sept. 2026, 16:01","18 Sept. 2026, 17:44",'
    '"","Schrägbankdrücken (Multipresse)",,"",0,"normal",30,8,,,\n'
    '"Torso 2 (Schwachstellen)","18 Sept. 2026, 16:01","18 Sept. 2026, 17:44",'
    '"","Schrägbankdrücken (Multipresse)",,"",1,"normal",50,6,,,\n'
    '"Leg/ Core","11 März 2026, 15:32","11 März 2026, 17:01",'
    '"","Beinpresse (Maschine)",,"",0,"normal",120,10,,,\n'
    '"Pull","1 Juni 2026, 17:18","1 Juni 2026, 18:30",'
    '"","Latzug (Kabelzug)",,"",0,"normal",32,8,,,\n';

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
      final crunch = parseWorkoutCsv(
        _strengthlog,
      ).sessions.last.sets.firstWhere((s) => s.exerciseName == 'Crunch');

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

  group('sets logged by time', () {
    // Before the app could store a hold, every one of these was skipped —
    // a plank or a carry in someone's history simply vanished on import.
    const csv = '''
title,start_time,exercise_title,weight_kg,reps,duration_seconds
Core,2026-05-01 18:00:00,Plank,0,,60
Core,2026-05-01 18:00:00,Farmer's Walk,20,,45
Core,2026-05-01 18:00:00,Crunch,0,15,
''';

    test('a hold is kept, with its duration and no reps', () {
      final sets = parseWorkoutCsv(csv).sessions.single.sets;

      expect(sets, hasLength(3));
      expect(sets[0].seconds, 60);
      expect(sets[0].reps, 0);
    });

    test('a loaded carry keeps its weight as well as its time', () {
      final carry = parseWorkoutCsv(csv).sessions.single.sets[1];

      expect(carry.seconds, 45);
      expect(carry.weightKg, 20);
    });

    test('a counted set carries no duration', () {
      final crunch = parseWorkoutCsv(csv).sessions.single.sets[2];

      expect(crunch.reps, 15);
      expect(crunch.seconds, isNull);
    });

    test('a clock-formatted duration is read', () {
      // StrengthLog writes `00:01:30` where Hevy writes `90`.
      const clockCsv = '''
title,start,exercise,weight,reps,time
Core,2026-05-01 18:00:00,Plank,0,,00:01:30
''';
      expect(parseWorkoutCsv(clockCsv).sessions.single.sets.single.seconds, 90);
    });

    test('a zero-length duration is not a set', () {
      // `00:00:00` is what an exporter writes for a set that was set up and
      // never done — importing it would put a zero-second plank in the
      // history.
      const zeroCsv = '''
title,start,exercise,weight,reps,time,distanceM
Core,2026-05-01 18:00:00,Doomscrolling,,,00:00:00,0
''';
      final result = parseWorkoutCsv(zeroCsv);

      expect(result.setCount, 0);
      expect(result.skippedRows, 1);
    });
  });

  group('parseDurationCell', () {
    test('reads plain seconds', () {
      expect(parseDurationCell('45'), 45);
    });

    test('reads a clock', () {
      expect(parseDurationCell('1:30'), 90);
      expect(parseDurationCell('00:01:30'), 90);
      expect(parseDurationCell('1:00:00'), 3600);
    });

    test('nothing, zero and nonsense all read as no duration', () {
      for (final raw in ['', '0', '00:00', '00:00:00', 'a while', '1:2:3:4']) {
        expect(parseDurationCell(raw), isNull, reason: raw);
      }
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
      expect(
        parseImportDate('2026-01-15T18:30:00'),
        DateTime(2026, 1, 15, 18, 30),
      );
      expect(
        parseImportDate('2026-01-15 18:30:00'),
        DateTime(2026, 1, 15, 18, 30),
      );
    });

    test('reads a day-first European date', () {
      expect(
        parseImportDate('15/01/2026 18:30'),
        DateTime(2026, 1, 15, 18, 30),
      );
      expect(
        parseImportDate('15.01.2026, 18:30'),
        DateTime(2026, 1, 15, 18, 30),
      );
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

  group('a date with the month spelled out', () {
    test('reads the German spellings a real Hevy export uses', () {
      // Every one of these is a month token out of the file that imported as
      // zero workouts. `Sept.` is the specific one: German abbreviates
      // September to four letters where English uses three.
      expect(
        parseImportDate('18 Sept. 2026, 16:01'),
        DateTime(2026, 9, 18, 16, 1),
      );
      expect(
        parseImportDate('11 März 2026, 15:32'),
        DateTime(2026, 3, 11, 15, 32),
      );
      expect(parseImportDate('1 Mai 2026, 13:06'), DateTime(2026, 5, 1, 13, 6));
      expect(
        parseImportDate('1 Juni 2026, 17:18'),
        DateTime(2026, 6, 1, 17, 18),
      );
      expect(
        parseImportDate('3 Juli 2026, 20:18'),
        DateTime(2026, 7, 3, 20, 18),
      );
      expect(
        parseImportDate('10 Aug. 2026, 13:52'),
        DateTime(2026, 8, 10, 13, 52),
      );
      expect(
        parseImportDate('9 Feb. 2026, 18:00'),
        DateTime(2026, 2, 9, 18, 0),
      );
      expect(
        parseImportDate('1 Apr. 2026, 13:13'),
        DateTime(2026, 4, 1, 13, 13),
      );
    });

    test('reads English, in both the orders it is written in', () {
      // An English Hevy export failed exactly as the German one did — this is
      // not a translation problem, it is a missing format.
      expect(
        parseImportDate('28 Mar 2025, 17:29'),
        DateTime(2025, 3, 28, 17, 29),
      );
      expect(
        parseImportDate('12 Sep 2024, 07:30'),
        DateTime(2024, 9, 12, 7, 30),
      );
      expect(
        parseImportDate('18 September 2026, 16:01'),
        DateTime(2026, 9, 18, 16, 1),
      );
      // Month first, which is unambiguous *because* the month is a word. The
      // refusal to guess at a numeric `01/02/2026` is untouched.
      expect(
        parseImportDate('Sep 18, 2026, 4:01 PM'),
        DateTime(2026, 9, 18, 16, 1),
      );
      expect(parseImportDate('18th March 2026'), DateTime(2026, 3, 18));
    });

    test('reads the other locales Hevy ships in', () {
      final expected = DateTime(2026, 9, 18, 16, 1);

      expect(parseImportDate('18 sept. 2026 16:01'), expected, reason: 'fr');
      expect(parseImportDate('18 sept 2026, 16:01'), expected, reason: 'es');
      expect(parseImportDate('18 set 2026, 16:01'), expected, reason: 'it');
      // Portuguese puts "de" between the parts; they are neither a number nor
      // a month, so they are simply passed over.
      expect(
        parseImportDate('18 de set. de 2026 16:01'),
        expected,
        reason: 'pt',
      );
      expect(parseImportDate('18 sep 2026 16:01'), expected, reason: 'nl');
      expect(
        parseImportDate('18 mrt 2026 16:01'),
        DateTime(2026, 3, 18, 16, 1),
        reason: 'nl March',
      );
      expect(
        parseImportDate('18 août 2026 16:01'),
        DateTime(2026, 8, 18, 16, 1),
        reason: 'fr August',
      );
      expect(
        parseImportDate('18 março 2026 16:01'),
        DateTime(2026, 3, 18, 16, 1),
        reason: 'pt March',
      );
    });

    test('moves a 12-hour clock at both ends', () {
      expect(
        parseImportDate('5 Jan 2026, 12:30 AM'),
        DateTime(2026, 1, 5, 0, 30),
      );
      expect(
        parseImportDate('5 Jan 2026, 12:30 PM'),
        DateTime(2026, 1, 5, 12, 30),
      );
      expect(
        parseImportDate('5 Jan 2026, 1:30 PM'),
        DateTime(2026, 1, 5, 13, 30),
      );
      expect(
        parseImportDate('5 Jan 2026, 1:30 a.m.'),
        DateTime(2026, 1, 5, 1, 30),
      );
    });

    test('survives the invisible space a phone puts before the time', () {
      // ICU writes a narrow no-break space before AM/PM on newer Android and
      // iOS. It is not `\\s` to a regex, so left alone it fails the whole
      // pattern for a reason nothing on screen could explain.
      expect(
        parseImportDate('5 Jan 2026, 1:30 PM'),
        DateTime(2026, 1, 5, 13, 30),
      );
      expect(
        parseImportDate('5 Jan 2026, 13:30'),
        DateTime(2026, 1, 5, 13, 30),
      );
    });

    test(
      'a day that does not exist is refused, not rolled into next month',
      () {
        // DateTime(2026, 2, 31) is silently 3 March. A workout moved to the
        // wrong month is worse than one the user is told could not be read.
        expect(parseImportDate('31 February 2026'), isNull);
        expect(parseImportDate('31 Apr 2026'), isNull);
        // The real end of a real month still reads.
        expect(parseImportDate('29 Feb 2024'), DateTime(2024, 2, 29));
      },
    );

    test('refuses what is missing a part, or is not a month at all', () {
      expect(parseImportDate('Sept. 2026'), isNull, reason: 'no day');
      expect(parseImportDate('18 Sept. 16:01'), isNull, reason: 'no year');
      expect(parseImportDate('18 Smarch 2026'), isNull, reason: 'no month');
      // A word that is not a month means this is not a date at all, whatever
      // digits it happens to contain.
      expect(parseImportDate('Woche 12 2026'), isNull);
      expect(parseImportDate('Week 3 Day 2 2026'), isNull);
      // A two-digit year has no unambiguous reading — 26 could be the year or
      // a second day — so it is refused rather than guessed.
      expect(parseImportDate('18 Sep 26'), isNull);
    });

    test('a clock it cannot read is refused, not quietly dropped', () {
      // The worst possible outcome for this function is not failing — it is
      // returning midnight. Two workouts on one day would then share a start
      // time, and the grouping key would merge them into a single session.
      expect(parseImportDate('18 Sept. 2026, 16:01 Uhr'), isNull);
      expect(parseImportDate('18 Sep 2026, 16:01 GMT+2'), isNull);
      expect(parseImportDate('18 Sep 2026, 16:01 UTC'), isNull);
      // Split by the period, this arrives as two extra small numbers rather
      // than as a clock — caught by the same rule from the other side.
      expect(parseImportDate('18 Sep 2026 16.01'), isNull);
    });

    test('a Spanish day period has a space inside it', () {
      // `4:01 p. m.` is what CLDR writes for es, and the narrow no-break
      // space between `p.` and `m.` is already a plain one by the time this
      // sees it.
      expect(
        parseImportDate('18 sept 2026, 4:01 p. m.'),
        DateTime(2026, 9, 18, 16, 1),
      );
      expect(
        parseImportDate('18 sept 2026, 4:01 p. m.'),
        DateTime(2026, 9, 18, 16, 1),
      );
    });

    test('a weekday that is also a month name does not win', () {
      // `mar` is Tuesday in Spanish, French and Italian, and March in all
      // three. Read as a month, every Tuesday workout in a file would move
      // six months into the past without a word.
      expect(
        parseImportDate('mar, 18 ago 2026, 16:01'),
        DateTime(2026, 8, 18, 16, 1),
      );
      expect(parseImportDate('mar., 18 août 2026'), DateTime(2026, 8, 18));
      // But on its own it is still March — nothing else in the string can be.
      expect(parseImportDate('18 mar 2026'), DateTime(2026, 3, 18));
    });

    test('a weekday prefix in any of the supported languages is harmless', () {
      expect(parseImportDate('Wed, 18 Mar 2026'), DateTime(2026, 3, 18));
      expect(parseImportDate('Mi., 18. März 2026'), DateTime(2026, 3, 18));
      expect(parseImportDate('mié, 18 mar 2026'), DateTime(2026, 3, 18));
      expect(parseImportDate('lun, 18 mag 2026'), DateTime(2026, 5, 18));
    });

    test('no month name means two different months', () {
      // The table is flat across seven languages, so one spelling meaning
      // January in one and October in another would silently move workouts by
      // nine months. Asserted here so a language added later cannot introduce
      // a clash quietly.
      for (final entry in monthNumbers.entries) {
        expect(entry.key, foldMonthName(entry.key), reason: entry.key);
        expect(entry.value, inInclusiveRange(1, 12), reason: entry.key);
      }
      expect(foldMonthName('März'), 'marz');
      expect(foldMonthName('Sept.'), 'sept');
      expect(foldMonthName('março'), 'marco');
      expect(foldMonthName('août'), 'aout');
    });
  });

  group('a real Hevy export', () {
    test('reads, where before it produced nothing at all', () {
      final result = parseWorkoutCsv(_hevyReal);

      expect(result.source, 'Hevy');
      expect(result.skippedRows, 0);
      expect(result.sessions, hasLength(3));
      expect(result.setCount, 4);
    });

    test('keeps its names, umlauts and all, and its dates', () {
      final result = parseWorkoutCsv(_hevyReal);
      final last = result.sessions.last;

      expect(last.name, 'Torso 2 (Schwachstellen)');
      expect(last.start, DateTime(2026, 9, 18, 16, 1));
      expect(last.end, DateTime(2026, 9, 18, 17, 44));
      expect(last.sets.first.exerciseName, 'Schrägbankdrücken (Multipresse)');
      expect(last.sets.first.weightKg, 30);
    });
  });

  group('an end time the file is wrong about', () {
    test('is dropped when it is not a workout length', () {
      // StrengthLog's `end` is when the record was last closed, not when
      // training stopped. In a real export one workout claimed 33 days.
      final start = DateTime(2026, 7, 7, 22, 7);

      expect(plausibleEnd(start, DateTime(2026, 8, 10, 13, 53)), isNull);
      // Five and a half hours: short enough to look like a workout, long
      // enough that it is not one. The six-hour ceiling this started with let
      // five of these through, one of which still landed on the wrong day.
      expect(
        plausibleEnd(start, start.add(const Duration(minutes: 330))),
        isNull,
      );
      expect(
        plausibleEnd(start, start.subtract(const Duration(hours: 1))),
        isNull,
      );
      expect(plausibleEnd(start, null), isNull);
    });

    test('a genuine session, including one past midnight, is kept', () {
      // The real Hevy export has one starting 23:50 and ending 02:14. It is a
      // workout, not an error, and clamping on "same calendar day" would have
      // thrown it away.
      final late = DateTime(2026, 5, 23, 23, 50);
      expect(
        plausibleEnd(late, DateTime(2026, 5, 24, 2, 14)),
        DateTime(2026, 5, 24, 2, 14),
      );

      final start = DateTime(2026, 1, 15, 18);
      expect(
        plausibleEnd(start, DateTime(2026, 1, 15, 19, 30)),
        DateTime(2026, 1, 15, 19, 30),
      );
      // Exactly at the ceiling still counts; a minute past does not.
      expect(plausibleEnd(start, start.add(maxWorkoutDuration)), isNotNull);
      expect(
        plausibleEnd(
          start,
          start.add(maxWorkoutDuration + const Duration(minutes: 1)),
        ),
        isNull,
      );
    });
  });

  group('a file whose dates cannot be read', () {
    test('says so, and hands back the date it could not read', () {
      // The Hevy failure was silent: every column was present, so nothing
      // threw, and every row was dropped, so the screen said the file held no
      // sets. This is what turns that into a message someone can act on.
      const unreadable = '''
title,start_time,exercise_title,weight_kg,reps
Push,18.09.26 16:01,Bench Press,80,8
Push,Woche 12 2026,Bench Press,80,7
''';

      final result = parseWorkoutCsv(unreadable);

      expect(result.sessions, isEmpty);
      expect(result.skippedRows, 2);
      expect(result.skippedNoDate, 2);
      expect(result.unreadableDate, '18.09.26 16:01');
    });

    test('a row skipped for another reason is not blamed on its date', () {
      final result = parseWorkoutCsv(_hevy);

      expect(result.skippedNoDate, 0);
      expect(result.unreadableDate, isNull);
    });

    test('says so on a partial import too, not only an empty one', () {
      // The dangerous shape: most of a file reads, a stretch of it does not,
      // and the import is silently short by however many weeks that was.
      const partial = '''
title,start_time,exercise_title,weight_kg,reps
Push,"15 Jan. 2026, 18:00",Bench Press,80,8
Push,"15 Styczeń 2026, 18:00",Bench Press,80,8
''';

      final result = parseWorkoutCsv(partial);

      expect(result.sessions, hasLength(1));
      expect(result.skippedNoDate, 1);
      expect(result.unreadableDate, '15 Styczeń 2026, 18:00');
    });
  });

  group('a file with a workout column but no workout names', () {
    test('is not offered as a split', () {
      // The column being there is not the same as it having anything in it.
      // Without this the plan would be one day called "Imported workout"
      // holding every lift the person has ever done.
      const blank = '''
title,start_time,exercise_title,weight_kg,reps
,"15 Jan. 2026, 18:00",Bench Press,80,8
,"17 Jan. 2026, 18:00",Barbell Row,70,10
''';

      final result = parseWorkoutCsv(blank);

      expect(result.sessions, hasLength(2));
      expect(result.namesWorkouts, isFalse);
    });

    test('a file that does name them says so', () {
      expect(parseWorkoutCsv(_hevy).namesWorkouts, isTrue);
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
