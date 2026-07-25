import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';

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

/// The live list of sets logged in a session.
final sessionSetsProvider =
    StreamProvider.family<List<LoggedSet>, int>((ref, sessionId) {
      return ref.watch(sessionRepositoryProvider).watchSessionSets(sessionId);
    });
