import 'package:drift/drift.dart';

/// The user's body measurements on a given day.
///
/// One row per calendar day (enforced by [uniqueKeys]), with every measurement
/// nullable. That shape matters:
///
///   * Nullable, not 0 — "I didn't measure my hips today" is different from
///     "my hips are 0 cm". Charts skip nulls instead of plotting a dip to zero.
///   * One row per day, so the input screen can let the user fill in whatever
///     they measured today and come back later to add more to the same day.
///
/// Values are always stored canonically — kilograms and centimetres — even
/// after the kg/lbs setting lands in Phase 13. Converting for display is a UI
/// concern; storing mixed units would corrupt the history.
class BodyMeasurements extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The calendar day measured (stored normalized to midnight).
  DateTimeColumn get date => dateTime()();

  /// Bodyweight in kilograms.
  RealColumn get weightKg => real().nullable()();

  /// Circumferences in centimetres.
  RealColumn get chestCm => real().nullable()();
  RealColumn get waistCm => real().nullable()();
  RealColumn get hipsCm => real().nullable()();

  /// Upper arm (flexed), measured on the dominant side.
  RealColumn get armsCm => real().nullable()();

  /// Upper thigh, measured on the dominant side.
  RealColumn get legsCm => real().nullable()();

  /// When the row was last written — the "auto-timestamp" the input screen
  /// shows so the user knows how fresh the numbers are.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// One measurement row per day.
  @override
  List<Set<Column>> get uniqueKeys => [
    {date},
  ];
}

/// The measurable body parts, in the order the input screen and the body-part
/// chart picker show them.
///
/// Having this list in one place keeps the UI from hard-coding field names as
/// strings — the input screen builds its fields by looping over these, and the
/// chart's body-part picker offers exactly the same set.
enum MeasurementField {
  weight('Weight', 'kg'),
  chest('Chest', 'cm'),
  waist('Waist', 'cm'),
  hips('Hips', 'cm'),
  arms('Arms', 'cm'),
  legs('Legs', 'cm');

  const MeasurementField(this.label, this.unit);

  /// Display name, e.g. "Waist".
  final String label;

  /// The unit values are stored in, e.g. "cm".
  final String unit;
}
