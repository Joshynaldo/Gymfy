// Unit tests for the weekly overview roll-up. Pure logic, no database — the
// row classes are constructed directly.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/calories/data/weekly_overview_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  final today = DateTime(2026, 7, 24);
  DateTime daysAgo(int n) => DateTime(2026, 7, 24 - n);

  CalorieEntry meal(DateTime day, int calories) => CalorieEntry(
    id: 0,
    date: day,
    name: 'Meal',
    calories: calories,
    protein: 0,
    carbs: 0,
    fat: 0,
    createdAt: day,
  );

  Habit habit(int id, DateTime createdAt) =>
      Habit(id: id, name: 'Habit $id', position: 0, createdAt: createdAt);

  HabitEntry done(int habitId, DateTime day) =>
      HabitEntry(id: 0, habitId: habitId, date: day);

  List<DaySummary> build({
    List<CalorieEntry> calorieEntries = const [],
    List<Habit> habits = const [],
    List<HabitEntry> habitEntries = const [],
  }) {
    return buildWeekSummaries(
      today: today,
      calorieEntries: calorieEntries,
      habits: habits,
      habitEntries: habitEntries,
    );
  }

  test('covers seven days, oldest first, ending today', () {
    final week = build();
    expect(week.length, weeklyOverviewDays);
    expect(week.first.day, daysAgo(6));
    expect(week.last.day, daysAgo(0));
  });

  test('sums calories per day and ignores the time of day', () {
    final week = build(
      calorieEntries: [
        meal(daysAgo(2), 500),
        meal(DateTime(2026, 7, 22, 19, 30), 300), // same day, with a time
        meal(daysAgo(0), 700),
      ],
    );
    expect(week[4].calories, 800); // daysAgo(2)
    expect(week[6].calories, 700); // today
    expect(week[5].calories, 0); // nothing logged
  });

  test('entries outside the week are not counted', () {
    final week = build(calorieEntries: [meal(daysAgo(9), 1000)]);
    expect(week.every((d) => d.calories == 0), isTrue);
  });

  test('a habit only counts from the day it was created', () {
    // One habit that has existed all week, one created three days ago.
    final week = build(
      habits: [habit(1, daysAgo(10)), habit(2, daysAgo(3))],
      habitEntries: [],
    );
    expect(week.first.habitsPlanned, 1); // 6 days ago: only habit 1 existed
    expect(week[3].habitsPlanned, 2); // 3 days ago: habit 2 created
    expect(week.last.habitsPlanned, 2);
  });

  test('completion rate is done over planned', () {
    final week = build(
      habits: [habit(1, daysAgo(10)), habit(2, daysAgo(10))],
      habitEntries: [done(1, daysAgo(0)), done(2, daysAgo(0)), done(1, daysAgo(1))],
    );
    expect(week.last.completionRate, 1.0);
    expect(week[5].completionRate, 0.5);
    expect(week.first.completionRate, 0.0);
  });

  test('no habits yet means no rate at all, not zero percent', () {
    final week = build();
    expect(week.last.habitsPlanned, 0);
    expect(week.last.completionRate, isNull);
  });

  test('duplicate completion rows cannot push a day over 100%', () {
    final week = build(
      habits: [habit(1, daysAgo(10))],
      habitEntries: [done(1, daysAgo(0)), done(1, daysAgo(0))],
    );
    expect(week.last.habitsDone, 1);
    expect(week.last.completionRate, 1.0);
  });
}
