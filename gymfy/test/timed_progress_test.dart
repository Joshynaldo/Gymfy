// Progress for an exercise logged by time.
//
// Timed exercises shipped two versions before this and nothing in Progress
// knew about them. The result was not a missing feature but a wrong one: a
// plank appeared in the list like any other lift, charted as a flat line
// along zero, and reported a personal record of "0 kg × 0 reps". Present and
// wrong is worse than absent, because there is nothing to tell you not to
// believe it.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/progress/data/progress_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  late AppDatabase db;
  late ProgressRepository progress;
  late SessionRepository sessions;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    progress = ProgressRepository(db);
    sessions = SessionRepository(db);

    for (final (id, name, timed) in const [
      ('plank', 'Plank', true),
      ('farmers_walk', "Farmer's Walk", true),
      ('barbell_back_squat', 'Barbell Back Squat', false),
    ]) {
      await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              id: id,
              name: name,
              muscleIds: const ['abs'],
              isTimed: Value(timed),
            ),
          );
    }
  });

  tearDown(() async => db.close());

  Future<int> sessionOn(DateTime date) => db
      .into(db.workoutSessions)
      .insert(
        WorkoutSessionsCompanion.insert(name: 'Core', startedAt: Value(date)),
      );

  Future<void> logHold(
    int sessionId,
    String exerciseId,
    int number,
    int seconds, {
    double weight = 0,
  }) => sessions.logSet(
    sessionId: sessionId,
    exerciseId: exerciseId,
    setNumber: number,
    weight: weight,
    reps: 0,
    seconds: seconds,
  );

  group('history points', () {
    test('carry the longest hold of the session', () async {
      final id = await sessionOn(DateTime(2026, 1, 1));
      await logHold(id, 'plank', 1, 45);
      await logHold(id, 'plank', 2, 62);
      await logHold(id, 'plank', 3, 50);

      final points = await progress.watchExerciseHistory('plank').first;

      expect(points.single.longestHold, 62);
      expect(points.single.isHold, isTrue);
    });

    test('and the total time under tension', () async {
      // The hold's answer to session volume, kept as its own number rather
      // than folded into one: 45 seconds and 45 kilograms are not the same
      // quantity and must never share an axis.
      final id = await sessionOn(DateTime(2026, 1, 1));
      await logHold(id, 'plank', 1, 45);
      await logHold(id, 'plank', 2, 62);

      final points = await progress.watchExerciseHistory('plank').first;

      expect(points.single.totalSeconds, 107);
    });

    test('a counted exercise carries neither', () async {
      final id = await sessionOn(DateTime(2026, 1, 1));
      await sessions.logSet(
        sessionId: id,
        exerciseId: 'barbell_back_squat',
        setNumber: 1,
        weight: 100,
        reps: 5,
      );

      final points = await progress
          .watchExerciseHistory('barbell_back_squat')
          .first;

      expect(points.single.longestHold, isNull);
      expect(points.single.isHold, isFalse);
      expect(points.single.totalSeconds, 0);
    });

    test('warm-up holds stay out, like warm-up sets do', () async {
      final id = await sessionOn(DateTime(2026, 1, 1));
      await sessions.logSet(
        sessionId: id,
        exerciseId: 'plank',
        setNumber: 1,
        weight: 0,
        reps: 0,
        seconds: 120,
        isWarmup: true,
      );
      await logHold(id, 'plank', 1, 40);

      final points = await progress.watchExerciseHistory('plank').first;

      expect(
        points.single.longestHold,
        40,
        reason: 'a 2-minute warm-up must not become the record',
      );
    });
  });

  group('personal records', () {
    test('a hold records its longest, not a weight', () async {
      final first = await sessionOn(DateTime(2026, 1, 1));
      final second = await sessionOn(DateTime(2026, 1, 8));
      await logHold(first, 'plank', 1, 45);
      await logHold(second, 'plank', 1, 70);

      final records = personalRecordsFrom(
        await progress.watchExerciseHistory('plank').first,
      );

      expect(records!.isHold, isTrue);
      expect(records.longestHold, 70);
      expect(records.longestHoldDate, DateTime(2026, 1, 8));
      // And not the thing it used to say.
      expect(records.heaviestWeight, 0);
    });

    test('most time in a session is tracked separately', () async {
      // One long hold on the first day, more total time on the second.
      final first = await sessionOn(DateTime(2026, 1, 1));
      final second = await sessionOn(DateTime(2026, 1, 8));
      await logHold(first, 'plank', 1, 90);
      await logHold(second, 'plank', 1, 40);
      await logHold(second, 'plank', 2, 40);
      await logHold(second, 'plank', 3, 40);

      final records = personalRecordsFrom(
        await progress.watchExerciseHistory('plank').first,
      );

      expect(records!.longestHold, 90, reason: 'the single best hold');
      expect(records.longestHoldDate, DateTime(2026, 1, 1));
      expect(records.bestSeconds, 120, reason: 'the most time in one session');
      expect(records.bestSecondsDate, DateTime(2026, 1, 8));
    });

    test('a counted exercise is unaffected', () async {
      // The other half: adding holds must not change what a squat reports.
      final id = await sessionOn(DateTime(2026, 1, 1));
      await sessions.logSet(
        sessionId: id,
        exerciseId: 'barbell_back_squat',
        setNumber: 1,
        weight: 100,
        reps: 5,
      );

      final records = personalRecordsFrom(
        await progress.watchExerciseHistory('barbell_back_squat').first,
      );

      expect(records!.isHold, isFalse);
      expect(records.heaviestWeight, 100);
      expect(records.repsAtHeaviest, 5);
      expect(records.longestHold, isNull);
    });
  });

  group('a loaded carry', () {
    test('keeps its weight and still charts by time', () async {
      // Both quantities are real here, and the time is the one that
      // progresses — you walk further before you add a kilo.
      final id = await sessionOn(DateTime(2026, 1, 1));
      await logHold(id, 'farmers_walk', 1, 45, weight: 24);

      final points = await progress.watchExerciseHistory('farmers_walk').first;

      expect(points.single.longestHold, 45);
      expect(points.single.topWeight, 24);
      expect(points.single.isHold, isTrue);
    });

    test('has no estimated one-rep max', () async {
      // There is no rep to take a maximum of. Before this it would have been
      // computed from zero reps and quietly shown.
      final id = await sessionOn(DateTime(2026, 1, 1));
      await logHold(id, 'farmers_walk', 1, 45, weight: 24);

      final points = await progress.watchExerciseHistory('farmers_walk').first;

      expect(bestEstimatedOneRm(points), isNull);
    });
  });
}
