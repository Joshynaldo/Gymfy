import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/utils/dates.dart';

part 'weekly_overview_repository.g.dart';

/// How many days the weekly overview covers (today plus the six before it).
const weeklyOverviewDays = 7;

/// One day's roll-up for the weekly overview: calories eaten, and how many of
/// that day's habits were ticked off.
class DaySummary {
  const DaySummary({
    required this.day,
    required this.calories,
    required this.habitsDone,
    required this.habitsPlanned,
  });

  /// Midnight of the calendar day this summarises.
  final DateTime day;

  /// Total kcal logged on [day].
  final int calories;

  /// How many habits were marked done on [day].
  final int habitsDone;

  /// How many habits existed on [day] — a habit created later shouldn't count
  /// against earlier days, or every past day would look like a failure.
  final int habitsPlanned;

  /// Share of that day's habits completed (0.0–1.0), or null when there were no
  /// habits yet — which is "nothing to do", not "0% done".
  double? get completionRate =>
      habitsPlanned == 0 ? null : habitsDone / habitsPlanned;
}

/// The seven days ending at [today], oldest first.
List<DateTime> weekEndingAt(DateTime today) {
  final end = dateOnly(today);
  return [
    for (var i = weeklyOverviewDays - 1; i >= 0; i--)
      DateTime(end.year, end.month, end.day - i),
  ];
}

/// Rolls raw rows up into one [DaySummary] per day of the week ending at
/// [today]. Pure so it can be unit-tested without a database.
List<DaySummary> buildWeekSummaries({
  required DateTime today,
  required List<CalorieEntry> calorieEntries,
  required List<Habit> habits,
  required List<HabitEntry> habitEntries,
}) {
  // Calories per day.
  final calories = <DateTime, int>{};
  for (final entry in calorieEntries) {
    final day = dateOnly(entry.date);
    calories[day] = (calories[day] ?? 0) + entry.calories;
  }

  // Completed habits per day. A set of habit ids guards against any duplicate
  // rows so a day can never report more done than planned.
  final done = <DateTime, Set<int>>{};
  for (final entry in habitEntries) {
    done.putIfAbsent(dateOnly(entry.date), () => {}).add(entry.habitId);
  }

  final createdOn = [for (final habit in habits) dateOnly(habit.createdAt)];

  return [
    for (final day in weekEndingAt(today))
      DaySummary(
        day: day,
        calories: calories[day] ?? 0,
        habitsDone: done[day]?.length ?? 0,
        habitsPlanned: createdOn.where((c) => !c.isAfter(day)).length,
      ),
  ];
}

/// Reads the last week of calorie and habit data for the overview screen.
class WeeklyOverviewRepository {
  WeeklyOverviewRepository(this._db);

  final AppDatabase _db;

  /// Streams the week ending today, re-reading whenever any of the underlying
  /// tables change.
  ///
  /// The two data sets live in unrelated tables, so instead of joining we
  /// re-run both reads on any relevant table update. It's a handful of rows per
  /// week — cheap even on slow hardware — and far clearer than combining
  /// streams by hand.
  Stream<List<DaySummary>> watchWeek({DateTime? today}) async* {
    yield await _loadWeek(today ?? DateTime.now());
    final updates = _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.calorieEntries,
        _db.habits,
        _db.habitEntries,
      ]),
    );
    await for (final _ in updates) {
      yield await _loadWeek(today ?? DateTime.now());
    }
  }

  Future<List<DaySummary>> _loadWeek(DateTime today) async {
    final week = weekEndingAt(today);
    final start = week.first;
    final end = week.last;

    final calorieEntries = await (_db.select(_db.calorieEntries)..where(
      (t) => t.date.isBiggerOrEqualValue(start) & t.date.isSmallerOrEqualValue(end),
    )).get();

    final habitEntries = await (_db.select(_db.habitEntries)..where(
      (t) => t.date.isBiggerOrEqualValue(start) & t.date.isSmallerOrEqualValue(end),
    )).get();

    final habits = await _db.select(_db.habits).get();

    return buildWeekSummaries(
      today: today,
      calorieEntries: calorieEntries,
      habits: habits,
      habitEntries: habitEntries,
    );
  }
}

/// App-wide access to the [WeeklyOverviewRepository].
@Riverpod(keepAlive: true)
WeeklyOverviewRepository weeklyOverviewRepository(Ref ref) {
  return WeeklyOverviewRepository(ref.watch(appDatabaseProvider));
}

/// The live seven-day overview, oldest day first.
final weeklyOverviewProvider = StreamProvider<List<DaySummary>>((ref) {
  return ref.watch(weeklyOverviewRepositoryProvider).watchWeek();
});
