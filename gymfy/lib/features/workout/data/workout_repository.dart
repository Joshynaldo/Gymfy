import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';

part 'workout_repository.g.dart';

/// The next training day coming up, and how far away it is.
class UpcomingDay {
  const UpcomingDay({
    required this.day,
    required this.weekday,
    required this.daysAway,
  });

  final WorkoutDay day;

  /// ISO weekday it falls on.
  final int weekday;

  /// 1 = tomorrow, 2 = the day after, up to 7 for "this same weekday next
  /// week". Never 0: today is answered by the today card, and repeating it here
  /// would just be the same information twice.
  final int daysAway;
}

/// A workout day plus the weekdays it is trained on.
///
/// Weekdays are ISO-8601 (1 = Monday … 7 = Sunday), matching `DateTime.weekday`.
class ScheduledDay {
  const ScheduledDay({required this.day, required this.weekdays});

  final WorkoutDay day;

  /// Sorted, so the UI can render "Mon, Thu" without re-sorting. Empty means
  /// the day exists but isn't on the calendar yet.
  final List<int> weekdays;
}

/// A workout day together with the split it belongs to.
///
/// Day names repeat across splits ("Push" exists in almost every one), so a day
/// on its own isn't enough to identify a target — the split name has to travel
/// with it.
class SplitDay {
  const SplitDay({required this.split, required this.day});

  final Split split;
  final WorkoutDay day;
}

/// A planned exercise joined with its library exercise, so the UI has both the
/// plan data (sets/reps) and the display data (name/muscles) in one object.
class PlannedExercise {
  const PlannedExercise({required this.entry, required this.exercise});

  /// The row from the workout_exercises table (dayId, sets, reps, …).
  final WorkoutExercise entry;

  /// The library exercise it points at (name, muscles, …).
  final Exercise exercise;
}

/// All database access for workout *plans* (splits, days, planned exercises)
/// lives here.
class WorkoutRepository {
  WorkoutRepository(this._db);

  final AppDatabase _db;

  // --- Splits -------------------------------------------------------------

  /// Streams every split, newest first. Re-emits automatically whenever the
  /// splits table changes, so the list UI updates with no manual refresh.
  Stream<List<Split>> watchSplits() {
    final query = _db.select(_db.splits)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }

  /// Streams a single split by id (null if it doesn't exist).
  Stream<Split?> watchSplit(int id) {
    final query = _db.select(_db.splits)..where((t) => t.id.equals(id));
    return query.watchSingleOrNull();
  }

  /// Streams the split currently being followed, or null if none is marked.
  Stream<Split?> watchActiveSplit() {
    final query = _db.select(_db.splits)..where((t) => t.isActive.equals(true));
    // `watchSingleOrNull` would throw if two rows were ever active at once.
    // Taking the first keeps a bad row from crashing the Home tab; the
    // invariant is enforced on write in [setActiveSplit].
    return query.watch().map((rows) => rows.isEmpty ? null : rows.first);
  }

  /// Makes [id] the only active split, or clears the active one when null.
  ///
  /// Both statements run in one transaction: a crash between them would
  /// otherwise leave either two active splits or none.
  Future<void> setActiveSplit(int? id) {
    return _db.transaction(() async {
      await _db
          .update(_db.splits)
          .write(const SplitsCompanion(isActive: Value(false)));
      if (id == null) return;
      await (_db.update(_db.splits)..where((t) => t.id.equals(id))).write(
        const SplitsCompanion(isActive: Value(true)),
      );
    });
  }

  /// Creates a new split with the given name and returns its generated id.
  ///
  /// The first split ever created becomes active on its own: a lone split that
  /// isn't active would make the Home tab claim you have no programme while
  /// looking straight at one.
  Future<int> createSplit(String name) async {
    return _db.transaction(() async {
      final isFirst = (await _db.select(_db.splits).get()).isEmpty;
      return _db.into(_db.splits).insert(
        SplitsCompanion.insert(
          name: name.trim(),
          isActive: Value(isFirst),
        ),
      );
    });
  }

  /// Deletes a split. Its days and their planned exercises are removed too,
  /// via the foreign-key cascade (see app_database.dart).
  Future<void> deleteSplit(int id) {
    return (_db.delete(_db.splits)..where((t) => t.id.equals(id))).go();
  }

  // --- Days ---------------------------------------------------------------

  /// Streams the days of a split, in the order they were added.
  Stream<List<WorkoutDay>> watchDays(int splitId) {
    final query = _db.select(_db.workoutDays)
      ..where((t) => t.splitId.equals(splitId))
      ..orderBy([(t) => OrderingTerm(expression: t.id)]);
    return query.watch();
  }

  /// Streams a single day by id (null if it doesn't exist).
  Stream<WorkoutDay?> watchDay(int id) {
    final query = _db.select(_db.workoutDays)..where((t) => t.id.equals(id));
    return query.watchSingleOrNull();
  }

  /// Adds a day to a split and returns its generated id.
  Future<int> createDay(int splitId, String name) {
    return _db.into(_db.workoutDays).insert(
      WorkoutDaysCompanion.insert(splitId: splitId, name: name.trim()),
    );
  }

  /// Streams every day in the app, each carrying its split, grouped so all of
  /// one split's days sit together and newer splits come first.
  ///
  /// Used by the "add to day" picker in the exercise library, which needs one
  /// flat list of every possible target rather than a split-then-day drill-down.
  Stream<List<SplitDay>> watchAllDays() {
    final query = _db.select(_db.workoutDays).join([
      innerJoin(_db.splits, _db.splits.id.equalsExp(_db.workoutDays.splitId)),
    ]);
    query.orderBy([
      OrderingTerm(expression: _db.splits.createdAt, mode: OrderingMode.desc),
      // `createdAt` only has second resolution, so two splits made in the same
      // second tie and the order becomes whatever SQLite feels like. Falling
      // back to the id keeps "newest first" true — and keeps a split's days
      // together, which a wobbling order would break.
      OrderingTerm(expression: _db.splits.id, mode: OrderingMode.desc),
      OrderingTerm(expression: _db.workoutDays.id),
    ]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => SplitDay(
              split: row.readTable(_db.splits),
              day: row.readTable(_db.workoutDays),
            ),
          )
          .toList(),
    );
  }

  // --- Weekday scheduling ---------------------------------------------------

  /// Streams a split's days, each with the weekdays it's trained on.
  Stream<List<ScheduledDay>> watchScheduledDays(int splitId) {
    final query = _db.select(_db.workoutDays).join([
      leftOuterJoin(
        _db.workoutDaySchedules,
        _db.workoutDaySchedules.dayId.equalsExp(_db.workoutDays.id),
      ),
    ])..where(_db.workoutDays.splitId.equals(splitId));
    query.orderBy([OrderingTerm(expression: _db.workoutDays.id)]);

    // A left join, so a day with no weekdays yet still comes back — those are
    // exactly the ones the user needs to see in order to schedule them.
    return query.watch().map((rows) {
      final byDay = <int, ScheduledDay>{};
      final weekdays = <int, List<int>>{};
      for (final row in rows) {
        final day = row.readTable(_db.workoutDays);
        byDay[day.id] ??= ScheduledDay(day: day, weekdays: const []);
        final schedule = row.readTableOrNull(_db.workoutDaySchedules);
        if (schedule != null) {
          (weekdays[day.id] ??= []).add(schedule.weekday);
        }
      }
      return [
        for (final entry in byDay.entries)
          ScheduledDay(
            day: entry.value.day,
            weekdays: (weekdays[entry.key] ?? [])..sort(),
          ),
      ];
    });
  }

  /// Streams the day planned for [weekday] in the active split, or null when
  /// that weekday is a rest day (or no split is active).
  ///
  /// Rest is the absence of a scheduled day rather than a stored flag, so there
  /// is nothing that can disagree with the schedule.
  Stream<WorkoutDay?> watchDayForWeekday(int weekday) {
    final query = _db.select(_db.workoutDays).join([
      innerJoin(
        _db.workoutDaySchedules,
        _db.workoutDaySchedules.dayId.equalsExp(_db.workoutDays.id) &
            _db.workoutDaySchedules.weekday.equals(weekday),
      ),
      innerJoin(
        _db.splits,
        _db.splits.id.equalsExp(_db.workoutDays.splitId) &
            _db.splits.isActive.equals(true),
      ),
    ]);
    query.orderBy([OrderingTerm(expression: _db.workoutDays.id)]);

    return query.watch().map(
      (rows) => rows.isEmpty ? null : rows.first.readTable(_db.workoutDays),
    );
  }

  /// Streams the next training day after [fromWeekday] in the active split.
  ///
  /// Looks forward one full week and stops at the first hit, so a programme with
  /// a single training day still answers "next Monday" rather than giving up.
  /// Null means nothing is scheduled at all.
  Stream<UpcomingDay?> watchNextDay(int fromWeekday) {
    final query = _db.select(_db.workoutDays).join([
      innerJoin(
        _db.workoutDaySchedules,
        _db.workoutDaySchedules.dayId.equalsExp(_db.workoutDays.id),
      ),
      innerJoin(
        _db.splits,
        _db.splits.id.equalsExp(_db.workoutDays.splitId) &
            _db.splits.isActive.equals(true),
      ),
    ]);

    return query.watch().map((rows) {
      UpcomingDay? best;
      for (final row in rows) {
        final weekday = row.readTable(_db.workoutDaySchedules).weekday;
        // Distance forward around the week. `% 7` maps a wrap-around to a small
        // number, and the `+ 6) % 7 + 1` shape keeps today itself at 7 (a week
        // away) instead of 0, since today is not "next".
        final daysAway = (weekday - fromWeekday + 6) % 7 + 1;
        if (best == null || daysAway < best.daysAway) {
          best = UpcomingDay(
            day: row.readTable(_db.workoutDays),
            weekday: weekday,
            daysAway: daysAway,
          );
        }
      }
      return best;
    });
  }

  /// Puts a day on [weekday], taking that weekday off whichever day of the same
  /// split currently holds it.
  ///
  /// Two days on one weekday would make "what am I training today?" ambiguous,
  /// and the app would have to pick one arbitrarily. Moving the weekday instead
  /// is what the user meant anyway: assigning Legs to Monday means Monday is leg
  /// day now.
  Future<void> assignWeekday({required int dayId, required int weekday}) {
    return _db.transaction(() async {
      final day = await (_db.select(_db.workoutDays)
            ..where((t) => t.id.equals(dayId)))
          .getSingle();

      final siblings = await (_db.select(_db.workoutDays)
            ..where((t) => t.splitId.equals(day.splitId)))
          .get();

      await (_db.delete(_db.workoutDaySchedules)..where(
        (t) =>
            t.weekday.equals(weekday) &
            t.dayId.isIn(siblings.map((d) => d.id)),
      )).go();

      await _db
          .into(_db.workoutDaySchedules)
          .insert(
            WorkoutDaySchedulesCompanion.insert(
              dayId: dayId,
              weekday: weekday,
            ),
          );
    });
  }

  /// Takes a day off a weekday, making it a rest day unless another day of the
  /// split claims it.
  Future<void> clearWeekday({required int dayId, required int weekday}) {
    return (_db.delete(_db.workoutDaySchedules)
          ..where((t) => t.dayId.equals(dayId) & t.weekday.equals(weekday)))
        .go();
  }

  /// Deletes a day (and its planned exercises, via cascade).
  Future<void> deleteDay(int id) {
    return (_db.delete(_db.workoutDays)..where((t) => t.id.equals(id))).go();
  }

  // --- Planned exercises --------------------------------------------------

  /// Streams the exercises planned for a day, each joined with its library
  /// entry, in the order they were added.
  Stream<List<PlannedExercise>> watchDayExercises(int dayId) {
    final query = _db.select(_db.workoutExercises).join([
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.workoutExercises.exerciseId),
      ),
    ])..where(_db.workoutExercises.dayId.equals(dayId));
    query.orderBy([OrderingTerm(expression: _db.workoutExercises.id)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => PlannedExercise(
              entry: row.readTable(_db.workoutExercises),
              exercise: row.readTable(_db.exercises),
            ),
          )
          .toList(),
    );
  }

  /// Adds a library exercise to a day with default set/rep targets.
  Future<void> addExerciseToDay(
    int dayId,
    String exerciseId, {
    int sets = 3,
    int reps = 10,
  }) {
    return _db.into(_db.workoutExercises).insert(
      WorkoutExercisesCompanion.insert(
        dayId: dayId,
        exerciseId: exerciseId,
        defaultSets: Value(sets),
        defaultReps: Value(reps),
      ),
    );
  }

  /// Adds several exercises to a day at once, skipping any already planned for
  /// it, and returns how many were actually added.
  ///
  /// Skipping rather than duplicating: selecting four exercises when one is
  /// already in the day should leave you with one of each, not a stray double
  /// entry you then have to notice and remove. The count comes back so the UI
  /// can say what happened instead of claiming all four went in.
  Future<int> addExercisesToDay(int dayId, List<String> exerciseIds) async {
    final existing = await (_db.select(_db.workoutExercises)
          ..where((t) => t.dayId.equals(dayId)))
        .get();
    final alreadyThere = {for (final row in existing) row.exerciseId};

    final toAdd = exerciseIds.where((id) => !alreadyThere.contains(id)).toList();
    if (toAdd.isEmpty) return 0;

    await _db.batch((batch) {
      batch.insertAll(_db.workoutExercises, [
        for (final exerciseId in toAdd)
          WorkoutExercisesCompanion.insert(dayId: dayId, exerciseId: exerciseId),
      ]);
    });
    return toAdd.length;
  }

  /// Updates the default set/rep targets of a planned exercise.
  ///
  /// [repsMax] is the top of a rep range; pass null for a fixed target. A max
  /// that isn't actually above [reps] is stored as null rather than as a
  /// degenerate range — "8–8" is a fixed 8 wearing a costume, and letting it
  /// through would mean every display had to handle it.
  Future<void> updatePlannedExercise(
    int id, {
    required int sets,
    required int reps,
    int? repsMax,
    int warmupSets = 0,
  }) {
    return (_db.update(_db.workoutExercises)..where((t) => t.id.equals(id)))
        .write(
          WorkoutExercisesCompanion(
            defaultSets: Value(sets),
            defaultReps: Value(reps),
            defaultRepsMax: Value(
              repsMax != null && repsMax > reps ? repsMax : null,
            ),
            // Never negative: a "minus one warm-up" would make the session's
            // "Warm-up 1 of -1" label nonsense.
            warmupSets: Value(warmupSets < 0 ? 0 : warmupSets),
          ),
        );
  }

  /// Removes a planned exercise from its day.
  Future<void> removePlannedExercise(int id) {
    return (_db.delete(_db.workoutExercises)..where((t) => t.id.equals(id)))
        .go();
  }
}

/// App-wide access to the [WorkoutRepository].
@Riverpod(keepAlive: true)
WorkoutRepository workoutRepository(Ref ref) {
  return WorkoutRepository(ref.watch(appDatabaseProvider));
}

// The providers below are hand-written (not code-generated) because their
// types are Drift's generated classes (Split / WorkoutDay) or a class built
// from them, which the Riverpod generator can't emit.

/// The live list of all splits.
final splitListProvider = StreamProvider<List<Split>>((ref) {
  return ref.watch(workoutRepositoryProvider).watchSplits();
});

/// A single split by id (data may be null if it was deleted).
final splitProvider = StreamProvider.family<Split?, int>((ref, id) {
  return ref.watch(workoutRepositoryProvider).watchSplit(id);
});

/// The live list of days in a split.
final dayListProvider = StreamProvider.family<List<WorkoutDay>, int>((
  ref,
  splitId,
) {
  return ref.watch(workoutRepositoryProvider).watchDays(splitId);
});

/// The split currently being followed (null if none is marked active).
final activeSplitProvider = StreamProvider<Split?>((ref) {
  return ref.watch(workoutRepositoryProvider).watchActiveSplit();
});

/// A split's days with the weekdays each is trained on.
final scheduledDaysProvider =
    StreamProvider.family<List<ScheduledDay>, int>((ref, splitId) {
      return ref.watch(workoutRepositoryProvider).watchScheduledDays(splitId);
    });

/// What's planned for a given ISO weekday in the active split — null means rest.
final dayForWeekdayProvider = StreamProvider.family<WorkoutDay?, int>((
  ref,
  weekday,
) {
  return ref.watch(workoutRepositoryProvider).watchDayForWeekday(weekday);
});

/// The next training day after a given weekday — null when nothing is planned.
final nextDayProvider = StreamProvider.family<UpcomingDay?, int>((
  ref,
  fromWeekday,
) {
  return ref.watch(workoutRepositoryProvider).watchNextDay(fromWeekday);
});

/// Every day in every split, for pickers that need one flat list of targets.
final allDaysProvider = StreamProvider<List<SplitDay>>((ref) {
  return ref.watch(workoutRepositoryProvider).watchAllDays();
});

/// A single day by id (data may be null if it was deleted).
final dayProvider = StreamProvider.family<WorkoutDay?, int>((ref, id) {
  return ref.watch(workoutRepositoryProvider).watchDay(id);
});

/// The live list of planned exercises in a day.
final dayExercisesProvider =
    StreamProvider.family<List<PlannedExercise>, int>((ref, dayId) {
      return ref.watch(workoutRepositoryProvider).watchDayExercises(dayId);
    });
