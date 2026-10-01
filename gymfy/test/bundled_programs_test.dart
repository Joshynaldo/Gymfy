// The programmes bundled with the app: every file parses, every exercise in it
// is one the app ships, and each imports as a complete split.
//
// A bundled programme is a plan file nobody opens until a new user taps it on
// day one. A typo'd exercise id there would not fail to build — it would quietly
// recreate a nameless "custom" exercise in the library of everyone who picked
// that programme, which is about the worst first impression available.

import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/exercises/data/exercise_seed_data.dart';
import 'package:gymfy/features/plan_share/data/plan_document.dart';
import 'package:gymfy/features/plan_share/data/plan_share_repository.dart';
import 'package:gymfy/features/programs/data/program_catalog.dart';
import 'package:gymfy/shared/database/app_database.dart';

/// Reads a programme's file straight off disk, the way the parser would get it.
PlanDocument _read(BundledProgram program) =>
    PlanDocument.decode(File(program.assetPath).readAsStringSync());

void main() {
  final seedById = {
    for (final exercise in exerciseSeedData) exercise.id.value: exercise,
  };

  test('there are programmes, and their ids are unique', () {
    expect(bundledPrograms, isNotEmpty);
    final ids = bundledPrograms.map((p) => p.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('every catalogue entry has a file, and every file an entry', () {
    // A file with no entry never shows in the browser; an entry with no file
    // shows and then fails to open.
    final onDisk = Directory('assets/programs')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => name.endsWith('.$planFileExtension'))
        .toSet();
    final listed = {
      for (final program in bundledPrograms) program.assetPath.split('/').last,
    };
    expect(onDisk, listed);
  });

  test('the folder is bundled into the app', () {
    // Without the pubspec entry every file above exists in the repository and
    // none of them exist on a phone.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/programs/'));
  });

  for (final program in bundledPrograms) {
    group(program.name, () {
      test('parses as a plan with one split of the same name', () {
        final document = _read(program);
        expect(document.splits, hasLength(1));
        expect(document.splits.single.name, program.name);
        expect(document.splits.single.days, isNotEmpty);
      });

      test('references only exercises the app ships', () {
        for (final day in _read(program).splits.single.days) {
          expect(day.exercises, isNotEmpty, reason: '${day.name} is empty');
          for (final exercise in day.exercises) {
            final seed = seedById[exercise.exerciseId];
            expect(
              seed,
              isNotNull,
              reason:
                  '${exercise.exerciseId} in ${day.name} is not in the seed',
            );
            // Carried for recreating custom exercises; for a built-in it
            // should simply agree with the library.
            expect(exercise.name, seed!.name.value);
            expect(exercise.muscleIds, seed.muscleIds.value);
          }
        }
      });

      test('schedules as many days a week as it says', () {
        final weekdays = {
          for (final day in _read(program).splits.single.days) ...day.weekdays,
        };
        expect(weekdays, hasLength(program.daysPerWeek));
      });

      test('keeps superset members next to each other', () {
        // `supersetBlocks` only joins adjacent members, so a group split by
        // another exercise would silently become two lone exercises.
        for (final day in _read(program).splits.single.days) {
          final groups = [for (final e in day.exercises) e.supersetGroup];
          for (final group in groups.whereType<int>().toSet()) {
            final first = groups.indexOf(group);
            final last = groups.lastIndexOf(group);
            expect(last - first, greaterThan(0), reason: 'a lone superset');
            expect(
              groups.sublist(first, last + 1).every((g) => g == group),
              isTrue,
              reason: 'superset $group in ${day.name} is not contiguous',
            );
          }
        }
      });

      test('plans percentages only where a 1RM means something', () {
        for (final day in _read(program).splits.single.days) {
          for (final exercise in day.exercises) {
            final percent = exercise.targetPercent;
            if (percent == null) continue;
            expect(percent, inExclusiveRange(0, 100.0001));
            expect(
              seedById[exercise.exerciseId]!.isTimed.present &&
                  seedById[exercise.exerciseId]!.isTimed.value,
              isFalse,
              reason: 'a timed exercise has no 1RM',
            );
          }
        }
      });
    });
  }

  test('the percentage programme actually uses percentages', () {
    // The one programme that exists to show the feature off.
    final program = bundledPrograms.firstWhere(
      (p) => p.id == 'percentage_strength',
    );
    final percents = [
      for (final day in _read(program).splits.single.days)
        for (final exercise in day.exercises) ?exercise.targetPercent,
    ];
    expect(percents, isNotEmpty);
  });

  group('through the asset bundle', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('every programme loads the way the app loads it', () async {
      for (final program in bundledPrograms) {
        final document = await loadBundledProgram(program, bundle: rootBundle);
        expect(document.splits.single.name, program.name);
      }
    });
  });

  group('importing', () {
    late AppDatabase db;
    late PlanShareRepository repository;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = PlanShareRepository(db);
      // The library a real install has; the test database starts empty.
      await db.batch((batch) {
        batch.insertAll(db.exercises, exerciseSeedData);
      });
    });

    tearDown(() async => db.close());

    for (final program in bundledPrograms) {
      test(
        '${program.name} lands as a whole split, reusing the library',
        () async {
          final split = _read(program).splits.single;
          final before = await db.select(db.exercises).get();

          final splitId = await repository.import(split, name: program.name);

          // No exercise was invented: every id was already in the library.
          expect(await db.select(db.exercises).get(), hasLength(before.length));

          final days = await (db.select(
            db.workoutDays,
          )..where((t) => t.splitId.equals(splitId))).get();
          expect(days.map((d) => d.name), split.days.map((d) => d.name));

          for (final (index, day) in days.indexed) {
            final shared = split.days[index];
            final planned =
                await (db.select(db.workoutExercises)
                      ..where((t) => t.dayId.equals(day.id))
                      ..orderBy([(t) => OrderingTerm(expression: t.position)]))
                    .get();
            expect(
              planned.map((p) => p.exerciseId),
              shared.exercises.map((e) => e.exerciseId),
            );
            expect(
              planned.map((p) => p.targetPercent),
              shared.exercises.map((e) => e.targetPercent),
            );
            expect(
              planned.map((p) => p.supersetGroup),
              shared.exercises.map((e) => e.supersetGroup),
            );
          }
        },
      );
    }
  });
}
