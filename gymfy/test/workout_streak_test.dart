// The workout streak: days trained in a row, counted from logged sessions.
//
// This replaces the habit streak removed in v17. Same counting rule, different
// and better source — the thing the app is actually about.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/dates.dart';

void main() {
  group('streakEndingAt', () {
    final today = DateTime(2026, 7, 24);
    DateTime daysAgo(int n) => DateTime(2026, 7, 24 - n);

    test('no days is no streak', () {
      expect(streakEndingAt({}, today), 0);
    });

    test('today alone is one', () {
      expect(streakEndingAt({today}, today), 1);
    });

    test('counts back through consecutive days', () {
      expect(streakEndingAt({today, daysAgo(1), daysAgo(2)}, today), 3);
    });

    test('a gap ends the count', () {
      expect(
        streakEndingAt({today, daysAgo(1), daysAgo(3), daysAgo(4)}, today),
        2,
      );
    });

    test('yesterday still counts when today is empty', () {
      // At 9am you haven't failed to train today, you just haven't trained yet.
      // A counter that resets overnight would be wrong for most of every day.
      expect(streakEndingAt({daysAgo(1), daysAgo(2)}, today), 2);
    });

    test('a two-day gap is a broken streak', () {
      expect(streakEndingAt({daysAgo(2), daysAgo(3)}, today), 0);
    });

    test('days in the future are ignored', () {
      // A session dated tomorrow (clock change, manual edit) must not inflate
      // or break the count.
      expect(streakEndingAt({DateTime(2026, 7, 25), today}, today), 1);
    });
  });

  group('watchWorkoutStreak', () {
    late AppDatabase db;
    late SessionRepository sessions;
    final today = DateTime(2026, 7, 24);

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      sessions = SessionRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    /// A session finished on [day].
    Future<void> finished(DateTime day) async {
      final id = await db
          .into(db.workoutSessions)
          .insert(WorkoutSessionsCompanion.insert(name: 'Push'));
      await (db.update(db.workoutSessions)..where((t) => t.id.equals(id)))
          .write(WorkoutSessionsCompanion(completedAt: Value(day)));
    }

    Future<int> streak() => sessions.watchWorkoutStreak(today: today).first;

    test('no workouts is no streak', () async {
      expect(await streak(), 0);
    });

    test('counts consecutive days', () async {
      await finished(today);
      await finished(DateTime(2026, 7, 23));
      await finished(DateTime(2026, 7, 22));

      expect(await streak(), 3);
    });

    test('two workouts in one day count once', () async {
      await finished(DateTime(2026, 7, 24, 8));
      await finished(DateTime(2026, 7, 24, 18));

      // It's a streak of days, not of sessions.
      expect(await streak(), 1);
    });

    test('an unfinished workout does not count', () async {
      await db
          .into(db.workoutSessions)
          .insert(WorkoutSessionsCompanion.insert(name: 'Push'));

      // Starting a workout and walking out isn't training, and a number that
      // can be gamed is worth nothing.
      expect(await streak(), 0);
    });

    test('a rest day today does not break yesterday-onward', () async {
      await finished(DateTime(2026, 7, 23));
      await finished(DateTime(2026, 7, 22));

      expect(await streak(), 2);
    });

    test('the time of day is ignored', () async {
      await finished(DateTime(2026, 7, 24, 23, 59));
      await finished(DateTime(2026, 7, 23, 0, 1));

      expect(await streak(), 2);
    });
  });
}
