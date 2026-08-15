import 'package:drift/drift.dart';

import 'exercise.dart';

/// A one-rep max the user actually tested, per exercise.
///
/// Separate from the logged sets on purpose: a real max attempt is a fact, and
/// it should override anything a formula guesses from a 5-rep set. Where both
/// exist, the progress screen leads with this and demotes the estimate.
///
/// One row per exercise — [exerciseId] is the primary key, so a retest simply
/// overwrites the old number rather than accumulating history. Tracking the
/// full history of tested maxes would be a nicer feature, but it isn't what
/// this is for: it's "what do I currently know my max to be".
class TestedOneRms extends Table {
  /// The exercise this max belongs to. Deleting the exercise removes it.
  TextColumn get exerciseId =>
      text().references(Exercises, #id, onDelete: KeyAction.cascade)();

  /// The tested max in kilograms.
  RealColumn get weightKg => real()();

  /// The day it was tested (stored normalized to midnight). Shown next to the
  /// number, since a max from eight months ago is worth doubting.
  DateTimeColumn get testedOn => dateTime()();

  /// When the row was last written.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {exerciseId};
}
