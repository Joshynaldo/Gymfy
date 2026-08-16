import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/utils/dates.dart';

part 'session_repository.g.dart';

/// Database access for *performed* workouts — sessions and their logged sets.
/// (Planning lives in workout_repository.dart; this is the logging side.)
class SessionRepository {
  SessionRepository(this._db);

  final AppDatabase _db;

  /// Starts a new session for a planned day, snapshotting the day's [name], and
  /// returns the new session id. `completedAt` stays null until it's finished.
  Future<int> startSession({required int dayId, required String name}) {
    return _db.into(_db.workoutSessions).insert(
      WorkoutSessionsCompanion.insert(dayId: Value(dayId), name: name.trim()),
    );
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
  }) {
    return _db.into(_db.loggedSets).insert(
      LoggedSetsCompanion.insert(
        sessionId: sessionId,
        exerciseId: exerciseId,
        setNumber: setNumber,
        weight: Value(weight),
        reps: Value(reps),
      ),
    );
  }

  /// Deletes a single logged set.
  Future<void> deleteSet(int id) {
    return (_db.delete(_db.loggedSets)..where((t) => t.id.equals(id))).go();
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

  /// Total volume and workout count over the last seven days.
  ///
  /// Volume is kilograms, like everything stored; the caller converts for
  /// display. Only completed sessions count, matching the streak.
  Future<({double volumeKg, int workouts})> weeklyTotals({
    DateTime? today,
  }) async {
    final end = dateOnly(today ?? DateTime.now());
    final start = DateTime(end.year, end.month, end.day - 6);

    final rows = await (_db.select(_db.workoutSessions).join([
      leftOuterJoin(
        _db.loggedSets,
        _db.loggedSets.sessionId.equalsExp(_db.workoutSessions.id),
      ),
    ])..where(
      _db.workoutSessions.completedAt.isNotNull() &
          _db.workoutSessions.completedAt.isBiggerOrEqualValue(start),
    )).get();

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
      ..orderBy([(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)])
      ..limit(1);
    return query.watch().map((rows) => rows.isEmpty ? null : rows.first);
  }

  /// Deletes a session (and its logged sets, via cascade). Used to discard a
  /// session the user abandons.
  Future<void> deleteSession(int id) {
    return (_db.delete(_db.workoutSessions)..where((t) => t.id.equals(id)))
        .go();
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

/// A workout left running, if any.
final inProgressSessionProvider = StreamProvider<WorkoutSession?>((ref) {
  return ref.watch(sessionRepositoryProvider).watchInProgressSession();
});

/// The live list of sets logged in a session.
final sessionSetsProvider =
    StreamProvider.family<List<LoggedSet>, int>((ref, sessionId) {
      return ref.watch(sessionRepositoryProvider).watchSessionSets(sessionId);
    });
