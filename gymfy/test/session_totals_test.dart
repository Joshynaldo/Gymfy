// Rolling up logged sessions: volume and workout count over the last week.
//
// Kept when the home screen widgets were removed — the Home tab's recap charts
// need exactly this, and the edge cases below (the window boundary, unfinished
// sessions, empty workouts) are the ones easy to get wrong twice.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  late AppDatabase db;
  late SessionRepository sessions;
  final today = DateTime(2026, 7, 24);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sessions = SessionRepository(db);
    await db.into(db.exercises).insert(
      ExercisesCompanion.insert(
        id: 'barbell_bench_press',
        name: 'Barbell Bench Press',
        muscleIds: const ['chest'],
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  /// A session on [day] with [sets] sets of 100 kg × 10.
  Future<void> loggedSession(
    DateTime day, {
    int sets = 2,
    bool complete = true,
  }) async {
    final id = await db.into(db.workoutSessions).insert(
      WorkoutSessionsCompanion.insert(name: 'Push'),
    );
    for (var i = 1; i <= sets; i++) {
      await sessions.logSet(
        sessionId: id,
        exerciseId: 'barbell_bench_press',
        setNumber: i,
        weight: 100,
        reps: 10,
      );
    }
    if (complete) {
      await (db.update(db.workoutSessions)..where((t) => t.id.equals(id)))
          .write(WorkoutSessionsCompanion(completedAt: Value(day)));
    }
  }

  test('an empty week totals nothing', () async {
    final totals = await sessions.weeklyTotals(today: today);

    expect(totals.volumeKg, 0);
    expect(totals.workouts, 0);
  });

  test('sums volume across sessions', () async {
    await loggedSession(today);
    await loggedSession(DateTime(2026, 7, 22));

    final totals = await sessions.weeklyTotals(today: today);
    expect(totals.volumeKg, 4000); // 4 sets × 100 × 10
    expect(totals.workouts, 2);
  });

  test('a session from last week is outside the window', () async {
    await loggedSession(DateTime(2026, 7, 10));

    expect((await sessions.weeklyTotals(today: today)).workouts, 0);
  });

  test('the seventh day back still counts', () async {
    // Today plus the six before it — an off-by-one here would silently drop a
    // workout from the total every week.
    await loggedSession(DateTime(2026, 7, 18));

    expect((await sessions.weeklyTotals(today: today)).workouts, 1);
  });

  test('an unfinished session does not count', () async {
    await loggedSession(today, complete: false);

    // Matching the streak: starting a workout isn't training.
    final totals = await sessions.weeklyTotals(today: today);
    expect(totals.workouts, 0);
    expect(totals.volumeKg, 0);
  });

  test('a completed session with no sets still counts as a workout', () async {
    await loggedSession(today, sets: 0);

    // The left join has to keep the session row even with nothing to sum, or an
    // empty workout would vanish from the count.
    final totals = await sessions.weeklyTotals(today: today);
    expect(totals.workouts, 1);
    expect(totals.volumeKg, 0);
  });
}
