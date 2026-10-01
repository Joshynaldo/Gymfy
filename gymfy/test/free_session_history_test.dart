// A free workout — one with no planned day — once it is finished.
//
// Everything that reads training history works from sessions and their logged
// sets, never from the plan, so a session with `dayId == null` must show up
// everywhere a planned one does: the streak, the weekly totals, the recap, the
// muscle map, records, progress and the export.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/data_export/data/export_repository.dart';
import 'package:gymfy/features/home/data/recap_repository.dart';
import 'package:gymfy/features/muscle_map/data/muscle_volume_repository.dart';
import 'package:gymfy/features/progress/data/progress_repository.dart';
import 'package:gymfy/features/workout/data/personal_records.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/dates.dart';

void main() {
  late AppDatabase db;
  late SessionRepository sessions;
  late int freeId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = ON');
    sessions = SessionRepository(db);
    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: 'bench',
            name: 'Bench Press',
            muscleIds: const ['chest'],
          ),
        );

    // An earlier, lighter free workout, so the second one has a record to set.
    final earlier = await sessions.startFreeSession(name: 'Free workout');
    await sessions.addExercises(earlier, ['bench']);
    await sessions.logSet(
      sessionId: earlier,
      exerciseId: 'bench',
      setNumber: 1,
      weight: 80,
      reps: 5,
    );
    await (db.update(
      db.workoutSessions,
    )..where((t) => t.id.equals(earlier))).write(
      WorkoutSessionsCompanion(
        startedAt: Value(DateTime.now().subtract(const Duration(days: 1))),
        completedAt: Value(DateTime.now().subtract(const Duration(days: 1))),
      ),
    );

    freeId = await sessions.startFreeSession(name: 'Free workout');
    await sessions.addExercises(freeId, ['bench']);
    for (final (number, weight) in [(1, 90.0), (2, 100.0)]) {
      await sessions.logSet(
        sessionId: freeId,
        exerciseId: 'bench',
        setNumber: number,
        weight: weight,
        reps: 5,
      );
    }
    await sessions.completeSession(freeId);
  });

  tearDown(() => db.close());

  test('has no day, and keeps its name', () async {
    final session = await sessions.watchSession(freeId).first;
    expect(session!.dayId, isNull);
    expect(session.name, 'Free workout');
    expect(session.completedAt, isNotNull);
  });

  test('counts toward the streak', () async {
    final streaks = await sessions.watchStreaks().first;
    expect(streaks.current, 2);
  });

  test('counts toward the weekly totals', () async {
    final totals = await sessions.weeklyTotals();
    expect(totals.workouts, 2);
    expect(totals.volumeKg, 80 * 5 + 90 * 5 + 100 * 5);
  });

  test('is the last completed workout', () async {
    final last = await sessions.watchLastCompletedSession().first;
    expect(last?.id, freeId);
  });

  test('feeds the recap', () async {
    final sets = await RecapRepository(db).watchAllSets().first;
    expect(sets.where((s) => s.sessionId == freeId), hasLength(2));
  });

  test('lights up the muscle map', () async {
    final intensities = await MuscleVolumeRepository(
      db,
    ).watchSessionIntensities(freeId).first;
    expect(intensities['chest'], greaterThan(0));

    final week = await MuscleVolumeRepository(
      db,
    ).watchIntensitiesSince(dateOnly(DateTime.now())).first;
    expect(week['chest'], greaterThan(0));
  });

  test('sets records like any other workout', () async {
    final records = await PersonalRecordsRepository(
      db,
    ).recordsForSession(freeId);
    expect(records.single.exerciseId, 'bench');
    expect(records.single.records, isNotEmpty);
  });

  test('appears on the progress chart', () async {
    final points = await ProgressRepository(
      db,
    ).watchExerciseHistory('bench').first;
    expect(points, hasLength(2));
    expect(points.last.topWeight, 100);
  });

  test('is exported under its own name', () async {
    final data = await ExportRepository(db).load();
    final mine = data.sets.where((s) => s.weightKg >= 90).toList();
    expect(mine, hasLength(2));
    expect(mine.every((s) => s.sessionName == 'Free workout'), isTrue);
  });
}
