// Writing an imported history into the database.
//
// The test that earns its place here is importing the same file twice. People
// export, import, notice the weights are in the wrong unit, and import again
// — and the naive version of this turns a year of training into two years,
// with no way back short of wiping the app.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
import 'package:gymfy/features/import/data/import_format.dart';
import 'package:gymfy/features/import/data/import_plan.dart';
import 'package:gymfy/features/import/data/import_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

const _twoSessions = '''
title,start_time,end_time,exercise_title,set_type,weight_kg,reps
Push,2026-01-15 18:00:00,2026-01-15 19:05:00,Barbell Bench Press,warmup,40,10
Push,2026-01-15 18:00:00,2026-01-15 19:05:00,Barbell Bench Press,normal,80,8
Push,2026-01-15 18:00:00,2026-01-15 19:05:00,Barbell Bench Press,normal,80,7
Pull,2026-01-17 18:00:00,2026-01-17 19:00:00,Barbell Row,normal,70,10
''';

void main() {
  late AppDatabase db;
  late ExerciseRepository exercises;
  late WorkoutRepository workouts;
  late ImportRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    exercises = ExerciseRepository(db);
    workouts = WorkoutRepository(db);
    repo = ImportRepository(db, exercises, workouts);
    await exercises.seed();
  });

  tearDown(() async => db.close());

  Future<ImportOutcome> importCsv(String csv) =>
      repo.apply(parseWorkoutCsv(csv));

  group('matchableName', () {
    test('collapses case, spacing and punctuation', () {
      // Three spellings of one lift, across three apps.
      expect(
        matchableName('Bench Press (Barbell)'),
        matchableName('bench press barbell'),
      );
      expect(matchableName('Pull-Up'), matchableName('Pull Up'));
    });

    test('but not word order', () {
      // See matchKeys for the one exception.
      // "Front Squat" and "Squat Front" are not obviously the same lift, and
      // collapsing word order merges genuinely different ones often enough
      // to matter.
      expect(matchableName('Front Squat'), isNot(matchableName('Squat Front')));
    });
  });

  group('matchKeys — the bracketed qualifier', () {
    // Hevy writes `Bench Press (Barbell)`; this library, Strong and
    // StrengthLog all write `Barbell Bench Press`. On the plain name alone a
    // Hevy import recognises almost nothing and quietly builds a second,
    // parallel library of duplicates — every chart then split in half, with
    // no error anywhere to explain it.
    test('a trailing qualifier also matches with it moved to the front', () {
      expect(
        matchKeys('Bench Press (Barbell)'),
        contains(matchableName('Barbell Bench Press')),
      );
      expect(
        matchKeys('Chest Fly (Machine)'),
        contains(matchableName('Machine Chest Fly')),
      );
    });

    test('the name as written is always one of the keys', () {
      expect(
        matchKeys('Bench Press (Barbell)'),
        contains(matchableName('Bench Press (Barbell)')),
      );
    });

    test('a name with no brackets has exactly one key', () {
      // The transform must not fire in general: normalising word order
      // everywhere would collapse "Front Squat" and "Squat Front".
      expect(matchKeys('Barbell Bench Press'), hasLength(1));
    });

    test('empty brackets are left alone', () {
      expect(matchKeys('Bench Press ()'), hasLength(1));
    });
  });

  group('importing', () {
    test('a Hevy-style bracketed name finds the built-in exercise', () async {
      // The whole point of the transform, end to end.
      const csv = '''
title,start_time,exercise_title,set_index,weight_kg,reps
Push,2026-04-01 18:00:00,Bench Press (Barbell),0,80,8
''';
      final outcome = await importCsv(csv);

      expect(
        outcome.exercisesCreated,
        isEmpty,
        reason: 'it should have matched the seeded Barbell Bench Press',
      );

      final sets = await db.select(db.loggedSets).get();
      expect(sets.single.exerciseId, 'barbell_bench_press');
    });

    test('one lift written two ways becomes one exercise', () async {
      // A file that is inconsistent with itself must not create two.
      const csv = '''
title,start_time,exercise_title,weight_kg,reps
A,2026-04-01 18:00:00,Thing I Invented (Machine),60,8
B,2026-04-03 18:00:00,Machine Thing I Invented,60,8
''';
      final outcome = await importCsv(csv);

      expect(outcome.exercisesCreated, hasLength(1));
    });

    test('writes the sessions and their sets', () async {
      final outcome = await importCsv(_twoSessions);

      expect(outcome.sessionsAdded, 2);
      expect(outcome.setsAdded, 4);
      expect((await db.select(db.workoutSessions).get()), hasLength(2));
      expect((await db.select(db.loggedSets).get()), hasLength(4));
    });

    test('imported sessions are complete, not left running', () async {
      // An open session makes the app offer to resume a workout from last
      // March, and blocks starting a new one.
      await importCsv(_twoSessions);

      final sessions = await db.select(db.workoutSessions).get();
      expect(sessions.every((s) => s.completedAt != null), isTrue);
    });

    test('matches an existing exercise instead of duplicating it', () async {
      // The seeded library already has a barbell bench press. Creating a
      // second one would split the history of one lift across two charts.
      final outcome = await importCsv(_twoSessions);

      expect(outcome.exercisesCreated, isNot(contains('Barbell Bench Press')));

      final benchRows = await (db.select(
        db.exercises,
      )..where((t) => t.name.equals('Barbell Bench Press'))).get();
      expect(benchRows, hasLength(1));
    });

    test('creates an exercise the library has never heard of', () async {
      // Dropping the sets instead would give a history that looks complete
      // and is not.
      const csv = '''
title,start_time,exercise_title,weight_kg,reps
Push,2026-02-01 18:00:00,Dr Disrespect Special,60,8
''';
      final outcome = await importCsv(csv);

      expect(outcome.exercisesCreated, ['Dr Disrespect Special']);
      expect(outcome.setsAdded, 1);

      final created = (await (db.select(
        db.exercises,
      )..where((t) => t.name.equals('Dr Disrespect Special'))).getSingle());
      expect(created.isCustom, isTrue);
      // No muscles rather than invented ones: a guess would paint the muscle
      // map with work that may never have happened.
      expect(created.muscleIds, isEmpty);
    });

    test('creates an unknown exercise once, not once per set', () async {
      const csv = '''
title,start_time,exercise_title,weight_kg,reps
Push,2026-02-01 18:00:00,Weird Machine,60,8
Push,2026-02-01 18:00:00,Weird Machine,60,8
Push,2026-02-03 18:00:00,Weird Machine,60,8
''';
      final outcome = await importCsv(csv);

      expect(outcome.exercisesCreated, hasLength(1));
      final rows = await (db.select(
        db.exercises,
      )..where((t) => t.name.equals('Weird Machine'))).get();
      expect(rows, hasLength(1));
    });

    test('numbers sets within their phase, like the logging screen', () async {
      // So an imported session reads identically to one logged here: the
      // warm-up is 1, and the working sets start again at 1.
      await importCsv(_twoSessions);

      final sets = await (db.select(
        db.loggedSets,
      )..where((t) => t.isWarmup.equals(false))).get();
      final bench = sets.where((s) => s.exerciseId == 'barbell_bench_press');
      expect(bench.map((s) => s.setNumber), [1, 2]);

      final warmups = await (db.select(
        db.loggedSets,
      )..where((t) => t.isWarmup.equals(true))).get();
      expect(warmups.single.setNumber, 1);
    });
  });

  group('importing the same file twice', () {
    test('adds nothing the second time', () async {
      // The one that makes the feature safe to use. Without it, a mistaken
      // unit and a re-import leave two copies of a year's training.
      await importCsv(_twoSessions);
      final second = await importCsv(_twoSessions);

      expect(second.sessionsAdded, 0);
      expect(second.sessionsSkipped, 2);
      expect(second.setsAdded, 0);
      expect((await db.select(db.workoutSessions).get()), hasLength(2));
      expect((await db.select(db.loggedSets).get()), hasLength(4));
    });

    test('even when the timestamps carry milliseconds', () async {
      // The bug a real export found and six hand-written fixtures did not.
      //
      // Drift stores a DateTime as a Unix timestamp in *seconds*, so the
      // milliseconds are dropped on the way in. Dedupe compared the parsed
      // value (with milliseconds) against the stored one (without), so
      // almost nothing ever matched and importing a file twice imported it
      // twice. Every fixture here had used whole seconds, so every test
      // passed while the feature was broken on real data.
      const withMillis = '''
title,start,exercise,weight,reps
Push,1789740587220,Barbell Bench Press,80,8
Pull,1789826987451,Barbell Row,70,10
''';
      final first = await importCsv(withMillis);
      expect(first.sessionsAdded, 2);

      final second = await importCsv(withMillis);
      expect(
        second.sessionsSkipped,
        2,
        reason: 'the same file must not import twice',
      );
      expect(second.sessionsAdded, 0);
      expect((await db.select(db.workoutSessions).get()), hasLength(2));
    });

    test('sessionKey ignores what the database cannot store', () {
      expect(
        sessionKey(DateTime.fromMillisecondsSinceEpoch(1789740587220)),
        sessionKey(DateTime.fromMillisecondsSinceEpoch(1789740587000)),
      );
      // But a second apart is still two different workouts.
      expect(
        sessionKey(DateTime.fromMillisecondsSinceEpoch(1789740587000)),
        isNot(sessionKey(DateTime.fromMillisecondsSinceEpoch(1789740588000))),
      );
    });

    test('still adds the sessions that are new', () async {
      await importCsv(_twoSessions);

      const withOneMore = '''
title,start_time,exercise_title,weight_kg,reps
Push,2026-01-15 18:00:00,Barbell Bench Press,80,8
Legs,2026-01-20 18:00:00,Barbell Squat,100,5
''';
      final outcome = await importCsv(withOneMore);

      expect(outcome.sessionsAdded, 1);
      expect(outcome.sessionsSkipped, 1);
      expect((await db.select(db.workoutSessions).get()), hasLength(3));
    });

    test('the preview says so before anything is written', () async {
      // The user should learn they are about to add nothing *before* tapping
      // Import, not after.
      await importCsv(_twoSessions);

      final already = await repo.countAlreadyHere(
        parseWorkoutCsv(_twoSessions),
      );
      expect(already, 2);
      // And counting changed nothing.
      expect((await db.select(db.workoutSessions).get()), hasLength(2));
    });

    test(
      'two sessions at the same instant in one file collapse to one',
      () async {
        // Defensive: the in-file guard has to be updated as it goes, or a
        // malformed export could write the same session twice in one pass.
        const csv = '''
title,start_time,exercise_title,weight_kg,reps
A,2026-03-01 18:00:00,Barbell Squat,100,5
B,2026-03-01 18:00:00,Barbell Squat,100,5
''';
        final outcome = await importCsv(csv);

        expect(outcome.sessionsAdded, 1);
        expect(outcome.sessionsSkipped, 1);
      },
    );
  });

  test('an existing history is left alone', () async {
    // Import adds; it never replaces. Someone with three months logged here
    // and two years in another app must end up with both.
    final mine = await db
        .into(db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            name: 'Mine',
            startedAt: Value(DateTime(2026, 6, 1, 12)),
          ),
        );

    await importCsv(_twoSessions);

    final sessions = await db.select(db.workoutSessions).get();
    expect(sessions, hasLength(3));
    expect(sessions.any((s) => s.id == mine && s.name == 'Mine'), isTrue);
  });

  group('building a split out of the file', () {
    // The other half of importing, and for a while it was missing entirely:
    // the history arrived, the year activity filled in, and there was still
    // nothing to press start on.

    test(
      'makes a day per workout name, with the exercises trained on it',
      () async {
        final import = parseWorkoutCsv(_twoSessions);
        await repo.apply(import);
        final plan = await repo.createSplitFrom(import);

        expect(plan, isNotNull);
        expect(plan!.days, 2);
        expect(plan.exercises, 2);

        final days = await workouts.watchDays(plan.splitId).first;
        expect(days.map((d) => d.name), unorderedEquals(['Push', 'Pull']));

        final push = days.firstWhere((d) => d.name == 'Push');
        final planned = await workouts.watchDayExercises(push.id).first;
        expect(planned.single.exercise.name, 'Barbell Bench Press');
      },
    );

    test('carries the sets, reps and warm-ups that were logged', () async {
      final import = parseWorkoutCsv(_twoSessions);
      await repo.apply(import);
      final plan = await repo.createSplitFrom(import);

      final days = await workouts.watchDays(plan!.splitId).first;
      final push = days.firstWhere((d) => d.name == 'Push');
      final bench = (await workouts.watchDayExercises(push.id).first).single;

      // The fixture's Push is one warm-up at 40 and two working sets of 8 and
      // 7 — so two working sets, eight reps, one ramp-up.
      expect(bench.entry.defaultSets, 2);
      expect(bench.entry.defaultReps, 8);
      expect(bench.entry.warmupSets, 1);
    });

    test('points at the library exercises the history already uses', () async {
      // Not a second, parallel set of custom ones. A split whose "Barbell
      // Bench Press" is a different row from the logged one would show no
      // history and no progressive overload on a lift with a year behind it.
      final import = parseWorkoutCsv(_twoSessions);
      await repo.apply(import);
      final before = await db.select(db.exercises).get();

      final plan = await repo.createSplitFrom(import);

      final after = await db.select(db.exercises).get();
      expect(after, hasLength(before.length), reason: 'nothing new created');

      final days = await workouts.watchDays(plan!.splitId).first;
      final push = days.firstWhere((d) => d.name == 'Push');
      final planned = await workouts.watchDayExercises(push.id).first;

      final logged = await db.select(db.loggedSets).get();
      expect(
        logged.map((s) => s.exerciseId),
        contains(planned.single.entry.exerciseId),
      );
    });

    test('creates a missing exercise rather than dropping the slot', () async {
      // Only reachable when the split is built without the history — but a
      // day with a hole in it is exactly as misleading as a history with one.
      const csv = '''
title,start_time,exercise_title,weight_kg,reps
Push,2026-01-15 18:00:00,Nordic Hamstring Lower,0,6
''';
      final plan = await repo.createSplitFrom(parseWorkoutCsv(csv));

      final days = await workouts.watchDays(plan!.splitId).first;
      final planned = await workouts.watchDayExercises(days.single.id).first;
      expect(planned.single.exercise.name, 'Nordic Hamstring Lower');
      expect(planned.single.exercise.isCustom, isTrue);
    });

    test('names itself after the app the file came from', () async {
      // So that a month later the split list still explains where it came
      // from. `_twoSessions` has no `set_index`, so it is not recognised as
      // any particular app and falls back to the neutral name.
      const hevy = '''
title,start_time,exercise_title,set_index,set_type,weight_kg,reps
Push,"15 Jan. 2026, 18:00",Barbell Bench Press,0,normal,80,8
''';
      expect(
        (await repo.createSplitFrom(parseWorkoutCsv(hevy)))!.splitName,
        'Hevy import',
      );
      expect(
        (await repo.createSplitFrom(parseWorkoutCsv(_twoSessions)))!.splitName,
        'Imported split',
      );
    });

    test('takes a name when it is given one', () async {
      final plan = await repo.createSplitFrom(
        parseWorkoutCsv(_twoSessions),
        name: 'My programme',
      );

      expect(plan!.splitName, 'My programme');
    });

    test('the first split ever made is the active one', () async {
      // The same rule as creating one by hand — a lone split that is not
      // active makes the Home tab claim you have no programme while looking
      // straight at one.
      final plan = await repo.createSplitFrom(parseWorkoutCsv(_twoSessions));

      final split = await workouts.watchSplit(plan!.splitId).first;
      expect(split!.isActive, isTrue);
    });

    test('a split you already follow is not pushed aside', () async {
      final mine = await workouts.createSplit('Mine');

      final plan = await repo.createSplitFrom(parseWorkoutCsv(_twoSessions));

      expect((await workouts.watchSplit(mine).first)!.isActive, isTrue);
      expect(
        (await workouts.watchSplit(plan!.splitId).first)!.isActive,
        isFalse,
      );
    });

    test('a file that names no workouts builds nothing', () async {
      // Rather than a split of one day called "Imported workout" holding
      // everything the person has ever lifted.
      const csv = '''
start_time,exercise_title,weight_kg,reps
2026-01-15 18:00:00,Barbell Bench Press,80,8
''';
      expect(await repo.createSplitFrom(parseWorkoutCsv(csv)), isNull);
      expect(await db.select(db.splits).get(), isEmpty);
    });

    test('still builds when every workout is already on the phone', () async {
      // Someone who imported last week and now wants the split out of the
      // same file. Built from the file's sessions rather than from what was
      // added, so re-importing is the way to get it.
      final import = parseWorkoutCsv(_twoSessions);
      await repo.apply(import);
      final again = await repo.apply(import);
      expect(again.sessionsAdded, 0);

      final plan = await repo.createSplitFrom(import);
      expect(plan!.days, 2);
    });
  });

  group('workouts that look like ones already here', () {
    test('are counted for the preview, but never skipped', () async {
      // The same training logged in two apps while switching between them.
      // The exports disagree by a minute, so the exact-start-time rule does
      // not catch them, and importing both doubles that stretch of history.
      await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              name: 'Push',
              startedAt: Value(DateTime(2026, 1, 15, 18, 8)),
            ),
          );

      final import = parseWorkoutCsv(_twoSessions);
      expect(await repo.countNearDuplicates(import), 1);
      expect(await repo.countAlreadyHere(import), 0);

      // Counted, not dropped: a second workout of the day is a real thing,
      // and deleting somebody's training without asking is the worse error.
      final outcome = await repo.apply(import);
      expect(outcome.sessionsAdded, 2);
    });

    test(
      'an exact match is already handled, and is not counted twice',
      () async {
        await repo.apply(parseWorkoutCsv(_twoSessions));

        final import = parseWorkoutCsv(_twoSessions);
        expect(await repo.countAlreadyHere(import), 2);
        expect(await repo.countNearDuplicates(import), 0);
      },
    );
  });

  group('choosing which days the split gets', () {
    /// Three weeks of Push and Pull, plus one improvised session with a name
    /// of its own — the shape StrengthLog produces when a workout is started
    /// without a template and gets named after the clock.
    String threeWeeksPlusOneOff() {
      final rows = <String>[
        'title,start_time,exercise_title,set_index,set_type,weight_kg,reps',
      ];
      for (var week = 0; week < 3; week++) {
        final monday = 5 + week * 7;
        final wednesday = 7 + week * 7;
        rows.add(
          'Push,"$monday Jan. 2026, 18:00",Barbell Bench Press,0,normal,80,8',
        );
        rows.add(
          'Pull,"$wednesday Jan. 2026, 18:00",Barbell Row,0,normal,70,10',
        );
      }
      rows.add(
        '"Saturday Evening: Barbell Curl","10 Jan. 2026, 19:00",'
        'Barbell Curl,0,normal,30,10',
      );
      return '${rows.join('\n')}\n';
    }

    test('builds only the days it was given', () async {
      final import = parseWorkoutCsv(threeWeeksPlusOneOff());
      expect(planForImport(import), hasLength(3));

      final plan = await repo.createSplitFrom(import, only: {'Push', 'Pull'});

      expect(plan!.days, 2);
      final days = await workouts.watchDays(plan.splitId).first;
      expect(days.map((d) => d.name), unorderedEquals(['Push', 'Pull']));
    });

    test('an empty selection builds nothing rather than an empty split', () {
      // Better than a split with no days in it, which the user then has to
      // notice and delete.
      expect(
        repo.createSplitFrom(
          parseWorkoutCsv(threeWeeksPlusOneOff()),
          only: const {},
        ),
        completion(isNull),
      );
    });
  });

  group('putting the split on the calendar', () {
    /// Push every Monday, Pull every Wednesday.
    String twoDaysOnFixedWeekdays() {
      final rows = <String>[
        'title,start_time,exercise_title,set_index,set_type,weight_kg,reps',
      ];
      for (var week = 0; week < 3; week++) {
        rows.add(
          'Push,"${5 + week * 7} Jan. 2026, 18:00",'
          'Barbell Bench Press,0,normal,80,8',
        );
        rows.add(
          'Pull,"${7 + week * 7} Jan. 2026, 18:00",'
          'Barbell Row,0,normal,70,10',
        );
      }
      return '${rows.join('\n')}\n';
    }

    test('schedules each day on the weekday it is actually trained', () async {
      // Without this the split is active and invisible: nothing scheduled
      // anywhere, so the Home tab answers "Rest day" every day of the week
      // and offers no way forward.
      final plan = await repo.createSplitFrom(
        parseWorkoutCsv(twoDaysOnFixedWeekdays()),
      );

      final scheduled = await workouts.watchScheduledDays(plan!.splitId).first;
      final byName = {for (final s in scheduled) s.day.name: s.weekdays};

      expect(byName['Push'], [DateTime.monday]);
      expect(byName['Pull'], [DateTime.wednesday]);
    });

    test('the stronger claim keeps a weekday two days both want', () async {
      // Home reads the weekday's first day and shows only that, so a second
      // claim on it is a day nobody would ever see. Left unscheduled instead,
      // which is at least visibly unscheduled.
      final rows = <String>[
        'title,start_time,exercise_title,set_index,set_type,weight_kg,reps',
      ];
      for (var week = 0; week < 4; week++) {
        rows.add(
          'Push,"${5 + week * 7} Jan. 2026, 18:00",'
          'Barbell Bench Press,0,normal,80,8',
        );
      }
      for (var week = 0; week < 2; week++) {
        rows.add(
          'Torso,"${2 + week * 7} Feb. 2026, 18:00",'
          'Barbell Row,0,normal,70,10',
        );
      }

      final plan = await repo.createSplitFrom(
        parseWorkoutCsv('${rows.join('\n')}\n'),
      );

      final scheduled = await workouts.watchScheduledDays(plan!.splitId).first;
      final byName = {for (final s in scheduled) s.day.name: s.weekdays};

      expect(byName['Push'], [DateTime.monday], reason: 'four sessions');
      expect(byName['Torso'], isEmpty, reason: 'two, so it loses the Monday');
      // And the one that won is the one Home will find.
      final today = await workouts.watchDayForWeekday(DateTime.monday).first;
      expect(today?.name, 'Push');
    });
  });

  group('a lift logged under two spellings', () {
    test('becomes one row in the day, not two', () async {
      // A rename part-way through a history, or a Hevy name alongside a
      // hand-typed one. Two cards for one exercise in a live session read and
      // write the same rows while showing different counts.
      final rows = <String>[
        'title,start_time,exercise_title,set_index,set_type,weight_kg,reps',
      ];
      for (var week = 0; week < 2; week++) {
        rows.add(
          'Push,"${5 + week * 7} Jan. 2026, 18:00",'
          'Bench Press (Barbell),0,normal,80,8',
        );
      }
      for (var week = 2; week < 4; week++) {
        rows.add(
          'Push,"${5 + week * 7} Jan. 2026, 18:00",'
          'Barbell Bench Press,0,normal,80,8',
        );
      }

      final plan = await repo.createSplitFrom(
        parseWorkoutCsv('${rows.join('\n')}\n'),
      );

      final days = await workouts.watchDays(plan!.splitId).first;
      final planned = await workouts.watchDayExercises(days.single.id).first;

      expect(planned, hasLength(1));
      expect(plan.exercises, 1);
    });
  });

  group('a split that already exists', () {
    test('is reported so the screen can stop offering another', () async {
      expect(await repo.hasSplitNamed('Hevy import'), isFalse);

      await repo.createSplitFrom(parseWorkoutCsv(_twoSessions));
      expect(await repo.hasSplitNamed('Imported split'), isTrue);
      expect(await repo.hasSplitNamed('  Imported split  '), isTrue);
      expect(await repo.hasSplitNamed('Something else'), isFalse);
    });
  });
}
