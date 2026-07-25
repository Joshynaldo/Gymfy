import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/utils/dates.dart';

part 'habit_repository.g.dart';

/// A habit plus its state for the checklist: whether it's done today and its
/// current streak.
class HabitStatus {
  const HabitStatus({
    required this.habit,
    required this.doneToday,
    required this.streak,
  });

  final Habit habit;
  final bool doneToday;

  /// Consecutive completed days ending today (or yesterday, if today isn't
  /// done yet — the streak isn't broken until a full day is missed).
  final int streak;
}

/// Database access for the habit tracker.
class HabitRepository {
  HabitRepository(this._db);

  final AppDatabase _db;

  /// Streams every habit with its today-status and streak, in checklist order.
  Stream<List<HabitStatus>> watchTodayStatuses() {
    final today = dateOnly(DateTime.now());

    final query = _db.select(_db.habits).join([
      leftOuterJoin(
        _db.habitEntries,
        _db.habitEntries.habitId.equalsExp(_db.habits.id),
      ),
    ])..orderBy([
      OrderingTerm(expression: _db.habits.position),
      OrderingTerm(expression: _db.habits.id),
    ]);

    return query.watch().map((rows) {
      // Collect each habit and the set of days it was completed.
      final habits = <int, Habit>{};
      final dates = <int, Set<DateTime>>{};
      for (final row in rows) {
        final habit = row.readTable(_db.habits);
        habits[habit.id] = habit;
        final entry = row.readTableOrNull(_db.habitEntries);
        if (entry != null) {
          dates.putIfAbsent(habit.id, () => {}).add(dateOnly(entry.date));
        }
      }

      return [
        for (final habit in habits.values)
          HabitStatus(
            habit: habit,
            doneToday: dates[habit.id]?.contains(today) ?? false,
            streak: streakEndingAt(dates[habit.id] ?? const {}, today),
          ),
      ];
    });
  }

  /// Adds a habit to the end of the checklist.
  Future<int> createHabit(String name) {
    return _db
        .into(_db.habits)
        .insert(HabitsCompanion.insert(name: name.trim()));
  }

  /// Deletes a habit (and its completion records, via cascade).
  Future<void> deleteHabit(int id) {
    return (_db.delete(_db.habits)..where((t) => t.id.equals(id))).go();
  }

  /// Marks a habit done or not done on [day].
  Future<void> setDone(int habitId, DateTime day, bool done) async {
    final d = dateOnly(day);
    if (done) {
      // insertOrIgnore keeps the once-per-day rule safe against double taps.
      await _db.into(_db.habitEntries).insert(
        HabitEntriesCompanion.insert(habitId: habitId, date: d),
        mode: InsertMode.insertOrIgnore,
      );
    } else {
      await (_db.delete(_db.habitEntries)
            ..where((t) => t.habitId.equals(habitId) & t.date.equals(d)))
          .go();
    }
  }
}

/// Counts consecutive completed days ending at [today] (or [today] - 1 day if
/// today isn't in the set), walking backwards until a gap is found.
int streakEndingAt(Set<DateTime> days, DateTime today) {
  if (days.isEmpty) return 0;

  var cursor = days.contains(today)
      ? today
      : DateTime(today.year, today.month, today.day - 1);

  var count = 0;
  while (days.contains(cursor)) {
    count++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return count;
}

/// App-wide access to the [HabitRepository].
@Riverpod(keepAlive: true)
HabitRepository habitRepository(Ref ref) {
  return HabitRepository(ref.watch(appDatabaseProvider));
}

/// The live habit checklist with today-status and streaks.
final habitTodayStatusesProvider = StreamProvider<List<HabitStatus>>((ref) {
  return ref.watch(habitRepositoryProvider).watchTodayStatuses();
});
