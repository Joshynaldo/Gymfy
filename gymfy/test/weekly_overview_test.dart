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

  List<DaySummary> build({List<CalorieEntry> calorieEntries = const []}) {
    return buildWeekSummaries(today: today, calorieEntries: calorieEntries);
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

  test('a day with nothing logged is zero, not missing', () {
    // The chart needs seven slots either way; it decides for itself that a zero
    // means "draw no bar".
    expect(build().length, weeklyOverviewDays);
    expect(build().every((d) => d.calories == 0), isTrue);
  });
}
