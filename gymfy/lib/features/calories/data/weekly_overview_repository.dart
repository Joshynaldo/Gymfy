import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/utils/dates.dart';

part 'weekly_overview_repository.g.dart';

/// How many days the weekly overview covers (today plus the six before it).
const weeklyOverviewDays = 7;

/// One day's roll-up for the weekly overview.
class DaySummary {
  const DaySummary({required this.day, required this.calories});

  /// Midnight of the calendar day this summarises.
  final DateTime day;

  /// Total kcal logged on [day].
  final int calories;
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
}) {
  final calories = <DateTime, int>{};
  for (final entry in calorieEntries) {
    final day = dateOnly(entry.date);
    calories[day] = (calories[day] ?? 0) + entry.calories;
  }

  return [
    for (final day in weekEndingAt(today))
      DaySummary(day: day, calories: calories[day] ?? 0),
  ];
}

/// Reads the last week of calorie data for the overview screen.
class WeeklyOverviewRepository {
  WeeklyOverviewRepository(this._db);

  final AppDatabase _db;

  /// Streams the week ending today, re-reading whenever the calorie table
  /// changes.
  Stream<List<DaySummary>> watchWeek({DateTime? today}) async* {
    yield await _loadWeek(today ?? DateTime.now());
    final updates = _db.tableUpdates(
      TableUpdateQuery.onAllTables([_db.calorieEntries]),
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
      (t) =>
          t.date.isBiggerOrEqualValue(start) &
          t.date.isSmallerOrEqualValue(end),
    )).get();

    return buildWeekSummaries(today: today, calorieEntries: calorieEntries);
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
