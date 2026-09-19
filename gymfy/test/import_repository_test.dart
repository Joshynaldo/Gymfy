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
import 'package:gymfy/features/import/data/import_repository.dart';
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
  late ImportRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    exercises = ExerciseRepository(db);
    repo = ImportRepository(db, exercises);
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
      expect(
        matchableName('Front Squat'),
        isNot(matchableName('Squat Front')),
      );
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

      final sets = await (db.select(db.loggedSets)
            ..where((t) => t.isWarmup.equals(false)))
          .get();
      final bench = sets.where((s) => s.exerciseId == 'barbell_bench_press');
      expect(bench.map((s) => s.setNumber), [1, 2]);

      final warmups = await (db.select(db.loggedSets)
            ..where((t) => t.isWarmup.equals(true)))
          .get();
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

      final already = await repo.countAlreadyHere(parseWorkoutCsv(_twoSessions));
      expect(already, 2);
      // And counting changed nothing.
      expect((await db.select(db.workoutSessions).get()), hasLength(2));
    });

    test('two sessions at the same instant in one file collapse to one',
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
    });
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
}
