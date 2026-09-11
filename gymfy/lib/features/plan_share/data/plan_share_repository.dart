import 'package:drift/drift.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import 'plan_document.dart';

part 'plan_share_repository.g.dart';

/// Reads plans out for sharing, and merges shared plans back in.
class PlanShareRepository {
  PlanShareRepository(this._db);

  final AppDatabase _db;

  /// Builds a shareable document from the given splits.
  ///
  /// Reads only the plan tables. Sessions, logged sets, measurements and photos
  /// are not touched — not filtered out later, never read at all, so there is
  /// no path by which they could end up in the file.
  Future<PlanDocument> export(List<int> splitIds, {DateTime? now}) async {
    final splits = await (_db.select(
      _db.splits,
    )..where((t) => t.id.isIn(splitIds))).get();

    final shared = <SharedSplit>[];
    // Ordered by the caller's selection rather than by row id, so the file
    // matches what the user ticked.
    for (final id in splitIds) {
      final split = splits.where((s) => s.id == id).firstOrNull;
      if (split == null) continue;
      shared.add(SharedSplit(name: split.name, days: await _daysOf(split.id)));
    }

    return PlanDocument(splits: shared, exportedAt: now ?? DateTime.now());
  }

  Future<List<SharedDay>> _daysOf(int splitId) async {
    final days =
        await (_db.select(_db.workoutDays)
              ..where((t) => t.splitId.equals(splitId))
              ..orderBy([(t) => OrderingTerm(expression: t.id)]))
            .get();

    final result = <SharedDay>[];
    for (final day in days) {
      final schedules = await (_db.select(
        _db.workoutDaySchedules,
      )..where((t) => t.dayId.equals(day.id))).get();

      final planned =
          await (_db.select(_db.workoutExercises).join([
                  innerJoin(
                    _db.exercises,
                    _db.exercises.id.equalsExp(_db.workoutExercises.exerciseId),
                  ),
                ])
                ..where(_db.workoutExercises.dayId.equals(day.id))
                ..orderBy([OrderingTerm(expression: _db.workoutExercises.id)]))
              .get();

      result.add(
        SharedDay(
          name: day.name,
          weekdays: [for (final s in schedules) s.weekday]..sort(),
          exercises: [
            for (final row in planned)
              () {
                final entry = row.readTable(_db.workoutExercises);
                final exercise = row.readTable(_db.exercises);
                return SharedExercise(
                  exerciseId: exercise.id,
                  name: exercise.name,
                  muscleIds: exercise.muscleIds,
                  sets: entry.defaultSets,
                  reps: entry.defaultReps,
                  repsMax: entry.defaultRepsMax,
                  warmupSets: entry.warmupSets,
                );
              }(),
          ],
        ),
      );
    }
    return result;
  }

  /// Every split name already on this device, for spotting collisions before
  /// the import runs.
  Future<Set<String>> existingSplitNames() async {
    final splits = await _db.select(_db.splits).get();
    return {for (final split in splits) split.name};
  }

  /// Adds [split] to the library under [name], and returns its new id.
  ///
  /// Always an insert, never an update: importing merges, so a plan you already
  /// have is never overwritten by someone else's version of it. Name collisions
  /// are resolved before this is called — the caller asks the user to rename.
  ///
  /// The whole split goes in one transaction. A crash halfway would otherwise
  /// leave a split with three of its five days and no sign anything was missed.
  Future<int> import(SharedSplit split, {required String name}) {
    return _db.transaction(() async {
      final splitId = await _db
          .into(_db.splits)
          .insert(SplitsCompanion.insert(name: name.trim()));

      for (final day in split.days) {
        final dayId = await _db
            .into(_db.workoutDays)
            .insert(
              WorkoutDaysCompanion.insert(splitId: splitId, name: day.name),
            );

        for (final weekday in day.weekdays) {
          await _db
              .into(_db.workoutDaySchedules)
              .insert(
                WorkoutDaySchedulesCompanion.insert(
                  dayId: dayId,
                  weekday: weekday,
                ),
              );
        }

        for (final exercise in day.exercises) {
          // Belt and braces — `SharedDay.fromJson` already drops these, but a
          // document built in code could still carry one, and a blank id would
          // put a nameless exercise in the library forever.
          if (exercise.exerciseId.isEmpty) continue;
          await _ensureExercise(exercise);
          await _db
              .into(_db.workoutExercises)
              .insert(
                WorkoutExercisesCompanion.insert(
                  dayId: dayId,
                  exerciseId: exercise.exerciseId,
                  defaultSets: Value(exercise.sets),
                  defaultReps: Value(exercise.reps),
                  defaultRepsMax: Value(exercise.repsMax),
                  warmupSets: Value(exercise.warmupSets),
                ),
              );
        }
      }

      return splitId;
    });
  }

  /// Makes sure the library has the exercise a shared plan refers to.
  ///
  /// Built-in slugs are the same on every install, so the recipient's own copy
  /// is reused and nothing is written. Anything else is a lift the sender
  /// invented: it gets recreated from the name and muscles carried in the file,
  /// marked custom. Without this, importing someone's programme would silently
  /// drop exactly the exercises most worth sharing.
  ///
  /// An existing exercise is never modified — their "Cable Fly" does not get to
  /// rename yours.
  Future<void> _ensureExercise(SharedExercise exercise) async {
    final existing = await (_db.select(
      _db.exercises,
    )..where((t) => t.id.equals(exercise.exerciseId))).getSingleOrNull();
    if (existing != null) return;

    await _db
        .into(_db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: exercise.exerciseId,
            name: exercise.name.isEmpty ? exercise.exerciseId : exercise.name,
            muscleIds: exercise.muscleIds,
            isCustom: const Value(true),
          ),
        );
  }
}

/// Suggests a free name for a split whose name is already taken.
///
/// Only a suggestion — the import flow puts it in a text field and makes the
/// user confirm or change it, because "Push / Pull / Legs (2)" is rarely what
/// anyone actually wants their programme called.
String suggestFreeName(String name, Set<String> taken) {
  if (!taken.contains(name)) return name;
  for (var n = 2; n < 100; n++) {
    final candidate = '$name ($n)';
    if (!taken.contains(candidate)) return candidate;
  }
  return name;
}

/// App-wide access to the [PlanShareRepository].
@Riverpod(keepAlive: true)
PlanShareRepository planShareRepository(Ref ref) {
  return PlanShareRepository(ref.watch(appDatabaseProvider));
}
