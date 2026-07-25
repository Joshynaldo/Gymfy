// Verifies the progress history query: one point per session, correct top set,
// oldest first. Uses an in-memory database.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/progress/data/progress_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/models/exercise_category.dart';

void main() {
  late AppDatabase db;
  late ProgressRepository progress;
  late SessionRepository sessions;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    progress = ProgressRepository(db);
    sessions = SessionRepository(db);

    await db.into(db.exercises).insert(
      ExercisesCompanion.insert(
        id: 'barbell_back_squat',
        name: 'Barbell Back Squat',
        muscleIds: const ['quads', 'glutes'],
        category: ExerciseCategory.legs,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  // Inserts a session with an explicit start date and returns its id.
  Future<int> sessionOn(DateTime date) {
    return db.into(db.workoutSessions).insert(
      WorkoutSessionsCompanion.insert(name: 'Legs', startedAt: Value(date)),
    );
  }

  test('one point per session, top set captured, oldest first', () async {
    final older = await sessionOn(DateTime(2026, 1, 1));
    final newer = await sessionOn(DateTime(2026, 1, 8));

    // Older session: heaviest set is 105 x 3.
    await sessions.logSet(
      sessionId: older,
      exerciseId: 'barbell_back_squat',
      setNumber: 1,
      weight: 100,
      reps: 5,
    );
    await sessions.logSet(
      sessionId: older,
      exerciseId: 'barbell_back_squat',
      setNumber: 2,
      weight: 105,
      reps: 3,
    );
    // Newer session: heaviest set is 110 x 5.
    await sessions.logSet(
      sessionId: newer,
      exerciseId: 'barbell_back_squat',
      setNumber: 1,
      weight: 110,
      reps: 5,
    );

    final history =
        await progress.watchExerciseHistory('barbell_back_squat').first;

    expect(history, hasLength(2));
    expect(history[0].date, DateTime(2026, 1, 1));
    expect(history[0].topWeight, 105);
    expect(history[0].repsAtTop, 3);
    expect(history[1].topWeight, 110);
  });

  test('exercises with history lists only trained exercises', () async {
    final s = await sessionOn(DateTime(2026, 1, 1));
    await sessions.logSet(
      sessionId: s,
      exerciseId: 'barbell_back_squat',
      setNumber: 1,
      weight: 100,
      reps: 5,
    );

    final list = await progress.watchExercisesWithHistory().first;
    expect(list.map((e) => e.id), ['barbell_back_squat']);
  });
}
