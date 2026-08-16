// Putting split days on weekdays, and the rules that keep "what am I training
// today?" answerable with exactly one answer.

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/weekday.dart';

void main() {
  const monday = 1;
  const tuesday = 2;
  const thursday = 4;

  group('weekday labels', () {
    test('cover all seven days in week order', () {
      expect(weekdays, [1, 2, 3, 4, 5, 6, 7]);
      expect(weekdays.map(weekdayInitial), [
        'Mo',
        'Tu',
        'We',
        'Th',
        'Fr',
        'Sa',
        'Su',
      ]);
    });

    test('line up with DateTime.weekday', () {
      // The whole point of ISO numbering: no conversion between what the
      // database stores and what `DateTime` reports.
      expect(weekdayName(DateTime(2026, 8, 17).weekday), 'Monday');
      expect(weekdayName(DateTime(2026, 8, 23).weekday), 'Sunday');
    });

    test('a summary is sorted into week order, not tap order', () {
      expect(weekdaySummary([4, 1]), 'Mon, Thu');
    });

    test('nothing scheduled has no summary', () {
      // Null rather than an empty string, so each caller picks its own wording
      // instead of rendering a blank.
      expect(weekdaySummary([]), isNull);
    });
  });

  group('WorkoutRepository scheduling', () {
    late AppDatabase db;
    late WorkoutRepository repo;
    late int splitId;
    late int push;
    late int pull;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = WorkoutRepository(db);
      splitId = await repo.createSplit('PPL');
      push = await repo.createDay(splitId, 'Push');
      pull = await repo.createDay(splitId, 'Pull');
    });

    tearDown(() async {
      await db.close();
    });

    Future<List<int>> weekdaysOf(int dayId) async {
      final scheduled = await repo.watchScheduledDays(splitId).first;
      return scheduled.firstWhere((s) => s.day.id == dayId).weekdays;
    }

    test('a day starts on no weekday at all', () async {
      final scheduled = await repo.watchScheduledDays(splitId).first;

      // Unscheduled rather than defaulted onto some weekday — we can't guess
      // someone's week, and a wrong guess is worse than an obvious blank.
      expect(scheduled, hasLength(2));
      expect(scheduled.every((s) => s.weekdays.isEmpty), isTrue);
    });

    test('one day can hold several weekdays', () async {
      await repo.assignWeekday(dayId: push, weekday: monday);
      await repo.assignWeekday(dayId: push, weekday: thursday);

      // The six-day PPL case: without this you'd need two identical Push days.
      expect(await weekdaysOf(push), [monday, thursday]);
    });

    test('weekdays come back in week order', () async {
      await repo.assignWeekday(dayId: push, weekday: thursday);
      await repo.assignWeekday(dayId: push, weekday: monday);

      expect(await weekdaysOf(push), [monday, thursday]);
    });

    test('assigning the same weekday twice is not an error', () async {
      await repo.assignWeekday(dayId: push, weekday: monday);
      await repo.assignWeekday(dayId: push, weekday: monday);

      expect(await weekdaysOf(push), [monday]);
    });

    test('a weekday moves off whichever day held it', () async {
      await repo.assignWeekday(dayId: push, weekday: monday);

      await repo.assignWeekday(dayId: pull, weekday: monday);

      // Two days on one Monday would make "today" ambiguous, and assigning Pull
      // to Monday plainly means Monday is pull day now.
      expect(await weekdaysOf(push), isEmpty);
      expect(await weekdaysOf(pull), [monday]);
    });

    test('taking a weekday off leaves the others alone', () async {
      await repo.assignWeekday(dayId: push, weekday: monday);
      await repo.assignWeekday(dayId: push, weekday: thursday);

      await repo.clearWeekday(dayId: push, weekday: monday);

      expect(await weekdaysOf(push), [thursday]);
    });

    test('deleting a day takes its schedule with it', () async {
      await repo.assignWeekday(dayId: push, weekday: monday);
      await db.customStatement('PRAGMA foreign_keys = ON');

      await repo.deleteDay(push);

      expect(await db.select(db.workoutDaySchedules).get(), isEmpty);
    });
  });

  group('the active split', () {
    late AppDatabase db;
    late WorkoutRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = WorkoutRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('the first split created becomes active on its own', () async {
      await repo.createSplit('PPL');

      // A lone split that isn't active would have the app claim you have no
      // programme while you're looking straight at one.
      expect((await repo.watchActiveSplit().first)?.name, 'PPL');
    });

    test('later splits do not take over', () async {
      await repo.createSplit('PPL');
      await repo.createSplit('Upper/Lower');

      // Creating a split to experiment with must not silently reschedule your
      // week.
      expect((await repo.watchActiveSplit().first)?.name, 'PPL');
    });

    test('setting one active deactivates the other', () async {
      final first = await repo.createSplit('PPL');
      final second = await repo.createSplit('Upper/Lower');

      await repo.setActiveSplit(second);

      expect((await repo.watchActiveSplit().first)?.id, second);
      final splits = await repo.watchSplits().first;
      expect(splits.where((s) => s.isActive), hasLength(1));
      expect(splits.firstWhere((s) => s.id == first).isActive, isFalse);
    });

    test('the active split can be cleared entirely', () async {
      await repo.createSplit('PPL');

      await repo.setActiveSplit(null);

      expect(await repo.watchActiveSplit().first, isNull);
    });
  });

  group('what is planned for a weekday', () {
    late AppDatabase db;
    late WorkoutRepository repo;
    late int push;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = WorkoutRepository(db);
      final splitId = await repo.createSplit('PPL');
      push = await repo.createDay(splitId, 'Push');
      await repo.assignWeekday(dayId: push, weekday: monday);
    });

    tearDown(() async {
      await db.close();
    });

    test('finds the day scheduled for that weekday', () async {
      expect((await repo.watchDayForWeekday(monday).first)?.name, 'Push');
    });

    test('an unscheduled weekday is a rest day', () async {
      // Null, not an empty day: rest is the absence of a workout, and there is
      // no second place for it to be recorded and disagree.
      expect(await repo.watchDayForWeekday(tuesday).first, isNull);
    });

    test('only the active split counts', () async {
      final other = await repo.createSplit('Upper/Lower');
      final upper = await repo.createDay(other, 'Upper');
      await repo.assignWeekday(dayId: upper, weekday: monday);

      // Both splits now claim Monday. PPL is active, so PPL wins.
      expect((await repo.watchDayForWeekday(monday).first)?.name, 'Push');

      await repo.setActiveSplit(other);
      expect((await repo.watchDayForWeekday(monday).first)?.name, 'Upper');
    });

    test('with no active split every day is a rest day', () async {
      await repo.setActiveSplit(null);

      expect(await repo.watchDayForWeekday(monday).first, isNull);
    });
  });
}
