import 'package:drift/drift.dart';

/// The two tables behind the habit tracker.
///
///   Habit  ──has many──▶  HabitEntry (one per day it was completed)
///
/// A [Habits] row is a checklist item the user wants to keep up (e.g. "Drink
/// 3L water"). A [HabitEntries] row records that a habit was done on a specific
/// day; a day with no row means "not done". Streaks are counts of consecutive
/// days with an entry. Deleting a habit removes its entries via cascade.

/// A habit the user is tracking.
class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Display name, e.g. "Drink 3L water".
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// Sort order in the checklist (lower = higher up).
  IntColumn get position => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// A record that a habit was completed on a given day. Existence of the row is
/// the completion; toggling off deletes it.
class HabitEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Owning habit. Removed with its habit via cascade.
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();

  /// The calendar day completed (stored normalized to midnight).
  DateTimeColumn get date => dateTime()();

  /// A habit can only be marked done once per day.
  @override
  List<Set<Column>> get uniqueKeys => [
    {habitId, date},
  ];
}
