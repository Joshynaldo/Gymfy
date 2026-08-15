import 'package:drift/drift.dart';

import 'exercise.dart';

/// How long to rest between sets of one exercise.
///
/// A separate table rather than a column on [Exercises] because that table is
/// seeded from `exercise_seed_data.dart` on every launch — a user's chosen rest
/// time would be at the mercy of the next reseed. Same reasoning as
/// `TestedOneRms`.
///
/// Rows only exist for exercises the user has actually customised. Everything
/// else falls back to the global default in the settings table, so adding a new
/// exercise doesn't mean inventing a rest time for it.
class RestTimers extends Table {
  /// The exercise this applies to. Deleting the exercise removes it.
  TextColumn get exerciseId =>
      text().references(Exercises, #id, onDelete: KeyAction.cascade)();

  /// Rest length in seconds.
  IntColumn get seconds => integer()();

  /// When the row was last written.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {exerciseId};
}
