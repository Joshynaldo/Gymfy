// Verifies that logged workout data actually persists to (and reads back from)
// the database, using an in-memory SQLite instance — no device needed.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  late AppDatabase db;
  late WorkoutRepository workout;
  late SessionRepository sessions;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    workout = WorkoutRepository(db);
    sessions = SessionRepository(db);

    // A session needs a day to belong to, and a logged set needs a real
    // exercise to reference (foreign keys are enforced).
    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: 'barbell_bench_press',
            name: 'Barbell Bench Press',
            muscleIds: const ['chest', 'triceps'],
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('logged sets persist and read back correctly', () async {
    final splitId = await workout.createSplit('PPL');
    final dayId = await workout.createDay(splitId, 'Push');
    final sessionId = await sessions.startSession(dayId: dayId, name: 'Push');

    await sessions.logSet(
      sessionId: sessionId,
      exerciseId: 'barbell_bench_press',
      setNumber: 1,
      weight: 60,
      reps: 10,
    );
    await sessions.logSet(
      sessionId: sessionId,
      exerciseId: 'barbell_bench_press',
      setNumber: 2,
      weight: 62.5,
      reps: 8,
    );

    final logged = await sessions.watchSessionSets(sessionId).first;

    expect(logged, hasLength(2));
    expect(logged[0].weight, 60);
    expect(logged[0].reps, 10);
    expect(logged[1].weight, 62.5);
    expect(logged[1].reps, 8);
  });

  test('finishing a session stamps completedAt', () async {
    final dayId = await workout.createDay(
      await workout.createSplit('PPL'),
      'Push',
    );
    final sessionId = await sessions.startSession(dayId: dayId, name: 'Push');

    final before = await sessions.watchSession(sessionId).first;
    expect(before!.completedAt, isNull);

    await sessions.completeSession(sessionId);

    final after = await sessions.watchSession(sessionId).first;
    expect(after!.completedAt, isNotNull);
  });

  test('deleting a session cascades to its logged sets', () async {
    final dayId = await workout.createDay(
      await workout.createSplit('PPL'),
      'Push',
    );
    final sessionId = await sessions.startSession(dayId: dayId, name: 'Push');
    await sessions.logSet(
      sessionId: sessionId,
      exerciseId: 'barbell_bench_press',
      setNumber: 1,
      weight: 60,
      reps: 10,
    );

    await sessions.deleteSession(sessionId);

    // No sets should remain anywhere once the session is gone.
    final remaining = await db.select(db.loggedSets).get();
    expect(remaining, isEmpty);
  });
}
