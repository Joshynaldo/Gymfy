import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/models/set_type.dart';
import '../../../shared/utils/dates.dart';

export '../../../shared/models/set_type.dart';

part 'session_repository.g.dart';

/// Whether a logged set counts as evidence of strength.
///
/// The single definition of the strength divide. Anything that reads sets to
/// judge how strong you are — estimated 1RM, personal records, the progress
/// chart, the progressive-overload suggestion — filters through this. Anything
/// that reads sets to describe what you *did* — session volume, the muscle map,
/// the recap charts — does not, because a warm-up is still work you performed.
///
/// Warm-ups and drop sets are on the far side of it, working and failure sets
/// on this one — see [SetType.countsTowardStrength]. SQL queries use
/// [strengthExcludedSetTypes] for the same rule.
///
/// One function rather than a type check scattered across five repositories:
/// the rule is easy to state and easy to forget in one place.
bool isWorkingSet(LoggedSet set) => set.type.countsTowardStrength;

/// Typed access to the set columns stored as plain values.
extension LoggedSetType on LoggedSet {
  /// What kind of set this was. Read this, never the raw `setType` string.
  SetType get type => SetType.parse(setType);

  /// Whether this was a ramp-up set. Only warm-ups — a drop set is not one,
  /// even though it is kept out of the strength numbers too (that question is
  /// [isWorkingSet]). Also decides which phase a set is numbered in.
  bool get isWarmup => type.isWarmupPhase;

  /// Reps in reserve, whichever way the set was rated: the stored RIR, or one
  /// derived from RPE (RIR ≈ 10 − RPE, rounded down). Null when unrated.
  int? get effectiveRir {
    if (rir != null) return rir;
    final value = rpe;
    if (value == null) return null;
    final derived = (10 - value).floor();
    return derived < 0 ? 0 : derived;
  }
}

/// One entry in a session's running order, joined with what it needs.
class SessionExerciseEntry {
  const SessionExerciseEntry({
    required this.row,
    required this.exercise,
    this.planned,
  });

  /// The session_exercises row (position, plan link).
  final SessionExercise row;

  /// The library exercise it points at.
  final Exercise exercise;

  /// The plan slot it came from, carrying the targets. Null for an exercise
  /// added during the session or whose slot has since been deleted.
  final WorkoutExercise? planned;

  /// The targets to work to: the plan slot's, or the defaults for an exercise
  /// the plan never had.
  ///
  /// Always a full row rather than a nullable one, so every screen that shows
  /// "3 × 10" or asks overload for a suggestion reads one thing. The stand-in
  /// is never written anywhere — its id of 0 matches no real slot.
  ///
  /// After a swap the slot still names the *old* exercise; only its targets
  /// are meant to carry over, so read the exercise from [exercise], never from
  /// `targets.exerciseId`.
  WorkoutExercise get targets =>
      planned ??
      WorkoutExercise(
        id: 0,
        dayId: 0,
        exerciseId: exercise.id,
        position: 0,
        defaultSets: addedExerciseSets,
        warmupSets: 0,
        defaultReps: addedExerciseReps,
      );

  /// The superset it belongs to in the plan, or null when it stands alone.
  /// Pass this to `supersetBlocks` / `restsAfter` (supersets.dart).
  int? get supersetGroup => planned?.supersetGroup;
}

/// Working sets suggested for an exercise added mid-workout, which has no plan
/// targets of its own. The same 3 × 10 a new plan slot starts with.
const addedExerciseSets = 3;

/// Reps suggested for an exercise added mid-workout. See [addedExerciseSets].
const addedExerciseReps = 10;

/// Database access for *performed* workouts — sessions and their logged sets.
/// (Planning lives in workout_repository.dart; this is the logging side.)
class SessionRepository {
  SessionRepository(this._db);

  final AppDatabase _db;

  /// Starts a new session for a planned day, snapshotting the day's [name], and
  /// returns the new session id. `completedAt` stays null until it's finished.
  ///
  /// The day's planned exercises are copied into the session's running order
  /// in the same transaction, so the session owns its list from the first
  /// moment and later edits to the plan don't reshuffle a workout under way.
  Future<int> startSession({required int dayId, required String name}) {
    return _db.transaction(() async {
      final sessionId = await _db
          .into(_db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              dayId: Value(dayId),
              name: name.trim(),
            ),
          );

      final planned =
          await (_db.select(_db.workoutExercises)
                ..where((t) => t.dayId.equals(dayId))
                ..orderBy([
                  (t) => OrderingTerm(expression: t.position),
                  (t) => OrderingTerm(expression: t.id),
                ]))
              .get();
      await _db.batch((batch) {
        batch.insertAll(_db.sessionExercises, [
          for (final (index, entry) in planned.indexed)
            SessionExercisesCompanion.insert(
              sessionId: sessionId,
              exerciseId: entry.exerciseId,
              position: Value(index),
              workoutExerciseId: Value(entry.id),
            ),
        ]);
      });
      return sessionId;
    });
  }

  /// Starts a free workout — one that follows no planned day — and returns its
  /// id. Its running order starts empty.
  Future<int> startFreeSession({required String name}) {
    return _db
        .into(_db.workoutSessions)
        .insert(WorkoutSessionsCompanion.insert(name: name.trim()));
  }

  /// Streams a session's running order, each entry joined with its library
  /// exercise and (when there is one) the plan slot it came from.
  Stream<List<SessionExerciseEntry>> watchSessionExercises(int sessionId) {
    final query = _db.select(_db.sessionExercises).join([
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.sessionExercises.exerciseId),
      ),
      leftOuterJoin(
        _db.workoutExercises,
        _db.workoutExercises.id.equalsExp(
          _db.sessionExercises.workoutExerciseId,
        ),
      ),
    ])..where(_db.sessionExercises.sessionId.equals(sessionId));
    query.orderBy([
      OrderingTerm(expression: _db.sessionExercises.position),
      OrderingTerm(expression: _db.sessionExercises.id),
    ]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          SessionExerciseEntry(
            row: row.readTable(_db.sessionExercises),
            exercise: row.readTable(_db.exercises),
            planned: row.readTableOrNull(_db.workoutExercises),
          ),
      ],
    );
  }

  // --- Running order ------------------------------------------------------
  //
  // Everything below edits the session's own list and nothing else. The plan
  // is the plan; what you did today because the rack was taken is not a
  // reason to rewrite it. ("Save swap to plan" is the one deliberate
  // exception, and lives in workout_repository.dart.)
  //
  // An exercise appears at most once in a running order. Logged sets are
  // keyed by exercise, not by entry, so two entries for the same lift would
  // share one set list and each claim the other's sets.

  /// Appends exercises to the end of a session's running order, skipping any
  /// already in it, and returns how many were actually added.
  ///
  /// Added exercises have no plan slot: they work to the defaults (see
  /// [SessionExerciseEntry.targets]).
  Future<int> addExercises(int sessionId, List<String> exerciseIds) {
    return _db.transaction(() async {
      final existing = await _orderOf(sessionId);
      final present = {for (final row in existing) row.exerciseId};
      final toAdd = [
        for (final id in exerciseIds)
          if (present.add(id)) id,
      ];
      if (toAdd.isEmpty) return 0;

      final start = existing.isEmpty ? 0 : existing.last.position + 1;
      await _db.batch((batch) {
        batch.insertAll(_db.sessionExercises, [
          for (final (index, id) in toAdd.indexed)
            SessionExercisesCompanion.insert(
              sessionId: sessionId,
              exerciseId: id,
              position: Value(start + index),
            ),
        ]);
      });
      return toAdd.length;
    });
  }

  /// Replaces the exercise of one entry with [exerciseId], keeping its plan
  /// slot so the targets carry over.
  ///
  /// Returns false, changing nothing, when [exerciseId] is already in the
  /// workout — see the note above on why a lift appears only once.
  ///
  /// If sets were already logged for the outgoing exercise, it stays in the
  /// running order just before the replacement, as an entry of its own with no
  /// plan slot. Those sets happened; swapping the exercise away should not
  /// make them vanish from the screen while they still sit in the session.
  Future<bool> swapExercise({
    required int sessionExerciseId,
    required String exerciseId,
  }) {
    return _db.transaction(() async {
      final row = await (_db.select(
        _db.sessionExercises,
      )..where((t) => t.id.equals(sessionExerciseId))).getSingleOrNull();
      if (row == null) return false;
      if (row.exerciseId == exerciseId) return true;

      final order = await _orderOf(row.sessionId);
      if (order.any((r) => r.exerciseId == exerciseId)) return false;

      final logged =
          await (_db.select(_db.loggedSets)
                ..where(
                  (t) =>
                      t.sessionId.equals(row.sessionId) &
                      t.exerciseId.equals(row.exerciseId),
                )
                ..limit(1))
              .get();

      await (_db.update(_db.sessionExercises)
            ..where((t) => t.id.equals(row.id)))
          .write(SessionExercisesCompanion(exerciseId: Value(exerciseId)));

      if (logged.isNotEmpty) {
        final keptId = await _db
            .into(_db.sessionExercises)
            .insert(
              SessionExercisesCompanion.insert(
                sessionId: row.sessionId,
                exerciseId: row.exerciseId,
              ),
            );
        final ids = [for (final r in order) r.id];
        ids.insert(ids.indexOf(row.id), keptId);
        await _writeOrder(ids);
      }
      return true;
    });
  }

  /// Rewrites a session's running order to [orderedIds] (session_exercises
  /// ids, first to last). Ids from another session are ignored, and entries
  /// left out keep their place after the ones given.
  Future<void> reorderExercises(int sessionId, List<int> orderedIds) {
    return _db.transaction(() async {
      final order = await _orderOf(sessionId);
      final known = {for (final r in order) r.id};
      final ids = [
        for (final id in orderedIds)
          if (known.remove(id)) id,
        for (final r in order)
          if (known.contains(r.id)) r.id,
      ];
      await _writeOrder(ids);
    });
  }

  /// Takes an entry out of the running order. Returns false, changing nothing,
  /// when sets have already been logged for its exercise in this session.
  ///
  /// Refused rather than deleting the sets with it: "remove from today's list"
  /// and "delete what I did" are different requests, and the second one
  /// already has its own button on every logged row.
  Future<bool> removeExercise(int sessionExerciseId) {
    return _db.transaction(() async {
      final row = await (_db.select(
        _db.sessionExercises,
      )..where((t) => t.id.equals(sessionExerciseId))).getSingleOrNull();
      if (row == null) return false;

      final logged =
          await (_db.select(_db.loggedSets)
                ..where(
                  (t) =>
                      t.sessionId.equals(row.sessionId) &
                      t.exerciseId.equals(row.exerciseId),
                )
                ..limit(1))
              .get();
      if (logged.isNotEmpty) return false;

      await (_db.delete(
        _db.sessionExercises,
      )..where((t) => t.id.equals(row.id))).go();
      return true;
    });
  }

  /// A session's running order, first to last.
  Future<List<SessionExercise>> _orderOf(int sessionId) {
    return (_db.select(_db.sessionExercises)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.position),
            (t) => OrderingTerm(expression: t.id),
          ]))
        .get();
  }

  /// Writes positions 0..n-1 to the given session_exercises ids, in order.
  Future<void> _writeOrder(List<int> ids) {
    return _db.batch((batch) {
      for (final (index, id) in ids.indexed) {
        batch.update(
          _db.sessionExercises,
          SessionExercisesCompanion(position: Value(index)),
          where: (t) => t.id.equals(id),
        );
      }
    });
  }

  /// Streams a single session by id (null if it doesn't exist).
  Stream<WorkoutSession?> watchSession(int id) {
    final query = _db.select(_db.workoutSessions)
      ..where((t) => t.id.equals(id));
    return query.watchSingleOrNull();
  }

  /// Streams every set logged in a session, in the order they were logged.
  Stream<List<LoggedSet>> watchSessionSets(int sessionId) {
    final query = _db.select(_db.loggedSets)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([(t) => OrderingTerm(expression: t.id)]);
    return query.watch();
  }

  /// Logs one performed set.
  Future<void> logSet({
    required int sessionId,
    required String exerciseId,
    required int setNumber,
    required double weight,
    required int reps,
    SetType setType = SetType.normal,
    int? seconds,
    double? rpe,
    int? rir,
  }) {
    return _db
        .into(_db.loggedSets)
        .insert(
          LoggedSetsCompanion.insert(
            sessionId: sessionId,
            exerciseId: exerciseId,
            setNumber: setNumber,
            weight: Value(weight),
            reps: Value(reps),
            setType: Value(setType.name),
            // Null for an ordinary set. A held set carries its duration here
            // and zero reps; the two are never both set.
            seconds: Value(seconds),
            rpe: Value(rpe),
            rir: Value(rir),
          ),
        );
  }

  /// Flips a logged set between warm-up and working, renumbering both phases.
  ///
  /// Re-tagging is the common repair: you ramp up, the bar feels light, and the
  /// set you called a warm-up was really your first working set. Without this
  /// the only fix is to delete the row and log it again from memory.
  Future<void> setWarmup({required int id, required bool isWarmup}) {
    return setSetType(id: id, type: isWarmup ? SetType.warmup : SetType.normal);
  }

  /// Re-tags a logged set as [type], renumbering both phases.
  Future<void> setSetType({required int id, required SetType type}) async {
    await _db.transaction(() async {
      final set = await (_db.select(
        _db.loggedSets,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (set == null) return;

      await (_db.update(_db.loggedSets)..where((t) => t.id.equals(id))).write(
        LoggedSetsCompanion(setType: Value(type.name)),
      );
      await _renumber(sessionId: set.sessionId, exerciseId: set.exerciseId);
    });
  }

  /// Deletes a single logged set, then closes the gap it left in the numbering.
  Future<void> deleteSet(int id) async {
    await _db.transaction(() async {
      final set = await (_db.select(
        _db.loggedSets,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (set == null) return;

      await (_db.delete(_db.loggedSets)..where((t) => t.id.equals(id))).go();
      await _renumber(sessionId: set.sessionId, exerciseId: set.exerciseId);
    });
  }

  /// Renumbers one exercise's sets in a session, counting warm-ups and working
  /// sets separately.
  ///
  /// The two phases are numbered independently so the working sets read 1, 2, 3
  /// no matter how many ramp-up sets came first — "set 4 of 3" would be a
  /// strange thing to see on the card, and the number people care about is how
  /// many *working* sets are done.
  Future<void> _renumber({
    required int sessionId,
    required String exerciseId,
  }) async {
    final sets =
        await (_db.select(_db.loggedSets)
              ..where(
                (t) =>
                    t.sessionId.equals(sessionId) &
                    t.exerciseId.equals(exerciseId),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.id)]))
            .get();

    var warmups = 0;
    var working = 0;
    await _db.batch((batch) {
      for (final set in sets) {
        final number = set.isWarmup ? ++warmups : ++working;
        if (number == set.setNumber) continue;
        batch.update(
          _db.loggedSets,
          LoggedSetsCompanion(setNumber: Value(number)),
          where: (t) => t.id.equals(set.id),
        );
      }
    });
  }

  /// Marks a session finished by stamping `completedAt` with the current time.
  Future<void> completeSession(int id) {
    return (_db.update(_db.workoutSessions)..where((t) => t.id.equals(id)))
        .write(WorkoutSessionsCompanion(completedAt: Value(DateTime.now())));
  }

  /// Streams the most recently finished session, or null if there isn't one.
  ///
  /// Ordered by `completedAt` with the id as a tiebreak: two sessions finished
  /// in the same second would otherwise come back in whatever order SQLite
  /// picked, and "your last workout" would flicker between them.
  Stream<WorkoutSession?> watchLastCompletedSession() {
    final query = _db.select(_db.workoutSessions)
      ..where((t) => t.completedAt.isNotNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.completedAt, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
      ])
      ..limit(1);
    return query.watch().map((rows) => rows.isEmpty ? null : rows.first);
  }

  /// Streams how many days in a row you've trained.
  ///
  /// Counts *days*, not sessions: two workouts in one day is one day of the
  /// streak. Only completed sessions count — starting a workout and walking out
  /// isn't training, and letting it count would make the number easy to game
  /// and therefore worth nothing.
  Stream<int> watchWorkoutStreak({DateTime? today}) {
    final query = _db.select(_db.workoutSessions)
      ..where((t) => t.completedAt.isNotNull());

    return query.watch().map((sessions) {
      final days = {
        for (final session in sessions)
          if (session.completedAt != null) dateOnly(session.completedAt!),
      };
      return streakEndingAt(days, dateOnly(today ?? DateTime.now()));
    });
  }

  /// The current run of training days and the longest one on record.
  ///
  /// One query for both: they are the same set of days counted two ways, and
  /// running a second identical query to ask the second question would double
  /// the work for nothing.
  Stream<({int current, int best})> watchStreaks({DateTime? today}) {
    final query = _db.select(_db.workoutSessions)
      ..where((t) => t.completedAt.isNotNull());

    return query.watch().map((sessions) {
      final days = {
        for (final session in sessions)
          if (session.completedAt != null) dateOnly(session.completedAt!),
      };
      return (
        current: streakEndingAt(days, dateOnly(today ?? DateTime.now())),
        best: longestStreak(days),
      );
    });
  }

  /// Total volume and workout count over the last seven days.
  ///
  /// Volume is kilograms, like everything stored; the caller converts for
  /// display. Only completed sessions count, matching the streak.
  Future<({double volumeKg, int workouts})> weeklyTotals({
    DateTime? today,
  }) async {
    final end = dateOnly(today ?? DateTime.now());
    final start = DateTime(end.year, end.month, end.day - 6);

    final rows =
        await (_db.select(_db.workoutSessions).join([
              leftOuterJoin(
                _db.loggedSets,
                _db.loggedSets.sessionId.equalsExp(_db.workoutSessions.id),
              ),
            ])..where(
              _db.workoutSessions.completedAt.isNotNull() &
                  _db.workoutSessions.completedAt.isBiggerOrEqualValue(start),
            ))
            .get();

    var volume = 0.0;
    final sessionIds = <int>{};
    for (final row in rows) {
      sessionIds.add(row.readTable(_db.workoutSessions).id);
      final set = row.readTableOrNull(_db.loggedSets);
      if (set != null) volume += set.weight * set.reps;
    }
    return (volumeKg: volume, workouts: sessionIds.length);
  }

  /// Streams the session still in progress, if the user left one open.
  ///
  /// Home offers to resume this rather than starting a second one — two live
  /// sessions would split a single workout's sets across both.
  Stream<WorkoutSession?> watchInProgressSession() {
    final query = _db.select(_db.workoutSessions)
      ..where((t) => t.completedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
      ])
      ..limit(1);
    return query.watch().map((rows) => rows.isEmpty ? null : rows.first);
  }

  /// Deletes a session (and its logged sets, via cascade). Used to discard a
  /// session the user abandons.
  Future<void> deleteSession(int id) {
    return (_db.delete(
      _db.workoutSessions,
    )..where((t) => t.id.equals(id))).go();
  }
}

/// App-wide access to the [SessionRepository].
@Riverpod(keepAlive: true)
SessionRepository sessionRepository(Ref ref) {
  return SessionRepository(ref.watch(appDatabaseProvider));
}

// Hand-written (not code-generated) because their types are Drift's generated
// classes, which the Riverpod generator can't emit.

/// A single session by id (data may be null if it was deleted).
final sessionProvider = StreamProvider.family<WorkoutSession?, int>((ref, id) {
  return ref.watch(sessionRepositoryProvider).watchSession(id);
});

/// The most recently finished session (null before the first one).
final lastCompletedSessionProvider = StreamProvider<WorkoutSession?>((ref) {
  return ref.watch(sessionRepositoryProvider).watchLastCompletedSession();
});

/// Days trained in a row, ending today (or yesterday if today is still ahead
/// of you).
final workoutStreakProvider = StreamProvider<int>((ref) {
  return ref.watch(sessionRepositoryProvider).watchWorkoutStreak();
});

/// The current streak and the best one ever, for the streak card.
final workoutStreaksProvider = StreamProvider<({int current, int best})>((ref) {
  return ref.watch(sessionRepositoryProvider).watchStreaks();
});

/// A workout left running, if any.
final inProgressSessionProvider = StreamProvider<WorkoutSession?>((ref) {
  return ref.watch(sessionRepositoryProvider).watchInProgressSession();
});

/// A session's running order, each entry with its exercise and plan targets.
final sessionExercisesProvider =
    StreamProvider.family<List<SessionExerciseEntry>, int>((ref, sessionId) {
      return ref
          .watch(sessionRepositoryProvider)
          .watchSessionExercises(sessionId);
    });

/// The live list of sets logged in a session.
final sessionSetsProvider = StreamProvider.family<List<LoggedSet>, int>((
  ref,
  sessionId,
) {
  return ref.watch(sessionRepositoryProvider).watchSessionSets(sessionId);
});
