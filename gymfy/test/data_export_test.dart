// The data export.
//
// The escaping tests carry the weight here. A CSV that shifts one column
// because someone called a session "Push, heavy" is worse than no export at
// all: it produces a file that opens fine and is quietly wrong.

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/data_export/data/export_format.dart';
import 'package:gymfy/features/data_export/data/export_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

ExportSet set({
  String session = 'Push',
  String exercise = 'Barbell Bench Press',
  List<String> muscles = const ['chest'],
  int setNumber = 1,
  bool isWarmup = false,
  double weightKg = 100,
  int reps = 5,
  DateTime? at,
}) {
  return (
    performedAt: at ?? DateTime(2026, 8, 24, 18, 30),
    sessionName: session,
    exerciseName: exercise,
    muscleIds: muscles,
    setNumber: setNumber,
    isWarmup: isWarmup,
    weightKg: weightKg,
    reps: reps,
  );
}

/// The CSV's data rows, header dropped.
List<String> rowsOf(String csv) =>
    csv.trim().split('\n').skip(1).map((line) => line.trimRight()).toList();

void main() {
  group('CSV', () {
    test('starts with a header naming every column', () {
      final csv = toCsv([set()]);

      expect(csv.split('\n').first, csvColumns.join(','));
    });

    test('writes one row per set', () {
      final csv = toCsv([set(setNumber: 1), set(setNumber: 2)]);

      expect(rowsOf(csv), hasLength(2));
    });

    test('splits the timestamp into date and time', () {
      final csv = toCsv([set(at: DateTime(2026, 8, 4, 9, 5))]);

      // Zero-padded so a spreadsheet sorts them as text without surprises.
      expect(rowsOf(csv).single, startsWith('2026-08-04,09:05,'));
    });

    test('names the weight column in kilograms', () {
      // The app stores kg whatever unit you read in. A column called plain
      // "weight" would be a number with no unit the moment it left the app.
      expect(csvColumns, contains('weight_kg'));
      expect(csvColumns, isNot(contains('weight')));
    });

    test('computes volume so the spreadsheet does not have to', () {
      final csv = toCsv([set(weightKg: 82.5, reps: 8)]);

      expect(rowsOf(csv).single, endsWith(',82.5,8,660'));
    });

    test('drops a pointless decimal but keeps a real one', () {
      expect(toCsv([set(weightKg: 100)]).contains(',100,'), isTrue);
      expect(toCsv([set(weightKg: 82.5)]).contains(',82.5,'), isTrue);
    });

    test('marks warm-ups so they can be filtered out later', () {
      final csv = toCsv([set(isWarmup: true), set()]);

      // Included, not dropped: this is your data, and an export deciding what
      // you may see is an export you cannot trust.
      expect(rowsOf(csv)[0], contains(',warmup,'));
      expect(rowsOf(csv)[1], contains(',working,'));
    });

    test('joins muscles without a comma', () {
      final csv = toCsv([
        set(muscles: ['chest', 'triceps']),
      ]);

      // A comma here would be quoted correctly and still trip up every naive
      // splitter someone points at the file.
      expect(rowsOf(csv).single, contains('chest; triceps'));
    });
  });

  group('CSV escaping', () {
    test('leaves an ordinary field alone', () {
      expect(csvField('Bench Press'), 'Bench Press');
    });

    test('quotes a field containing a comma', () {
      expect(csvField('Push, heavy'), '"Push, heavy"');
    });

    test('doubles an embedded quote', () {
      expect(csvField('The "big" three'), '"The ""big"" three"');
    });

    test('quotes a field containing a newline', () {
      expect(csvField('line one\nline two'), '"line one\nline two"');
    });

    test('a comma in a session name does not shift the columns', () {
      final csv = toCsv([set(session: 'Push, heavy', exercise: 'Bench')]);

      // The failure this guards: unquoted, that comma pushes every later value
      // one column right, so reps land under weight and the file reads fine
      // while being entirely wrong.
      final row = rowsOf(csv).single;
      expect(row, contains('"Push, heavy"'));
      expect(row, endsWith(',100,5,500'));
    });

    test("an apostrophe needs no quoting", () {
      // Common in exercise names, and quoting it would be noise.
      expect(csvField("Farmer's Walk"), "Farmer's Walk");
    });
  });

  group('JSON', () {
    test('groups sets under the session they belong to', () {
      final json =
          jsonDecode(
                toJson(
                  ExportData(sets: [set(setNumber: 1), set(setNumber: 2)]),
                ),
              )
              as Map<String, dynamic>;

      final workouts = json['workouts'] as List;
      expect(workouts, hasLength(1));
      expect((workouts.single as Map)['sets'], hasLength(2));
    });

    test('keeps two workouts on the same day apart', () {
      final json =
          jsonDecode(
                toJson(
                  ExportData(
                    sets: [
                      set(session: 'Push', at: DateTime(2026, 8, 24, 9)),
                      set(session: 'Pull', at: DateTime(2026, 8, 24, 18)),
                    ],
                  ),
                ),
              )
              as Map<String, dynamic>;

      expect(json['workouts'], hasLength(2));
    });

    test('carries measurements and meals as well', () {
      final json =
          jsonDecode(
                toJson(
                  ExportData(
                    sets: const [],
                    measurements: [
                      (
                        date: DateTime(2026, 8, 24),
                        weightKg: 84.2,
                        chestCm: null,
                        waistCm: 81,
                        hipsCm: null,
                        armsCm: null,
                        legsCm: null,
                      ),
                    ],
                    meals: [
                      (
                        date: DateTime(2026, 8, 24),
                        name: 'Chicken & rice',
                        calories: 650,
                        protein: 50,
                        carbs: 70,
                        fat: 12,
                      ),
                    ],
                  ),
                ),
              )
              as Map<String, dynamic>;

      final measurement = (json['measurements'] as List).single as Map;
      expect(measurement['weightKg'], 84.2);
      expect(measurement['waistCm'], 81);
      // Omitted rather than null: you didn't measure your chest that day, and a
      // null reads as a failed measurement rather than a skipped one.
      expect(measurement.containsKey('chestCm'), isFalse);

      expect(((json['meals'] as List).single as Map)['name'], 'Chicken & rice');
    });

    test('says out loud that it cannot be imported back', () {
      final json =
          jsonDecode(toJson(const ExportData(sets: [])))
              as Map<String, dynamic>;

      // Someone exporting before a phone swap needs to know this is a copy,
      // not a backup.
      expect(json['note'], contains('cannot be imported'));
    });
  });

  group('file names', () {
    test('are dated, so two exports do not collide', () {
      expect(
        exportFileName('csv', on: DateTime(2026, 8, 4)),
        'gymfy-workouts-2026-08-04.csv',
      );
      expect(
        exportFileName('json', on: DateTime(2026, 8, 4)),
        'gymfy-workouts-2026-08-04.json',
      );
    });
  });

  group('reading from the database', () {
    late AppDatabase db;
    late ExportRepository export;
    late SessionRepository sessions;
    late WorkoutRepository workout;
    late int dayId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      export = ExportRepository(db);
      sessions = SessionRepository(db);
      workout = WorkoutRepository(db);

      await db.into(db.exercises).insert(
        ExercisesCompanion.insert(
          id: 'barbell_bench_press',
          name: 'Barbell Bench Press',
          muscleIds: const ['chest', 'triceps'],
        ),
      );
      final splitId = await workout.createSplit('PPL');
      dayId = await workout.createDay(splitId, 'Push');
    });

    tearDown(() => db.close());

    Future<int> loggedSession({bool complete = true}) async {
      final id = await sessions.startSession(dayId: dayId, name: 'Push');
      await sessions.logSet(
        sessionId: id,
        exerciseId: 'barbell_bench_press',
        setNumber: 1,
        weight: 100,
        reps: 5,
      );
      if (complete) await sessions.completeSession(id);
      return id;
    }

    test('exports a finished workout', () async {
      await loggedSession();

      final data = await export.load();

      expect(data.sets, hasLength(1));
      expect(data.sets.single.exerciseName, 'Barbell Bench Press');
      expect(data.sets.single.weightKg, 100);
      expect(data.sets.single.muscleIds, ['chest', 'triceps']);
    });

    test('leaves an unfinished workout out', () async {
      await loggedSession(complete: false);

      // Matches the streak and the recap — a workout you walked out of isn't
      // training, and a half-finished row would skew a spreadsheet you're
      // using to judge your progress.
      expect((await export.load()).sets, isEmpty);
    });

    test('includes measurements and meals', () async {
      await db.into(db.bodyMeasurements).insert(
        BodyMeasurementsCompanion.insert(
          date: DateTime(2026, 8, 24),
          weightKg: const Value(84.2),
        ),
      );
      await db.into(db.calorieEntries).insert(
        CalorieEntriesCompanion.insert(
          date: DateTime(2026, 8, 24),
          name: 'Chicken & rice',
          calories: const Value(650),
        ),
      );

      final data = await export.load();

      expect(data.measurements, hasLength(1));
      expect(data.meals.single.name, 'Chicken & rice');
    });

    test('an empty log exports nothing rather than throwing', () async {
      final data = await export.load();

      expect(data.sets, isEmpty);
      expect(toCsv(data.sets).trim(), csvColumns.join(','));
    });
  });
}
