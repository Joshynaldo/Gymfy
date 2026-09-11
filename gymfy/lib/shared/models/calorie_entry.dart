import 'package:drift/drift.dart';

/// A single logged food/meal item on a given day, with its calories and
/// macros. The daily calorie log sums these per day and compares against the
/// user's goal (the goal itself is a setting, not stored here).
///
/// Drift generates the immutable `CalorieEntry` row class from this table.
class CalorieEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The calendar day this entry belongs to (stored normalized to midnight by
  /// the repository, so all of a day's entries share the same value).
  DateTimeColumn get date => dateTime()();

  /// What was eaten, e.g. "Chicken & rice".
  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// Energy in kilocalories.
  IntColumn get calories => integer().withDefault(const Constant(0))();

  /// Macronutrients in grams.
  IntColumn get protein => integer().withDefault(const Constant(0))();
  IntColumn get carbs => integer().withDefault(const Constant(0))();
  IntColumn get fat => integer().withDefault(const Constant(0))();

  /// Exact time the entry was logged — used to order items within a day.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
