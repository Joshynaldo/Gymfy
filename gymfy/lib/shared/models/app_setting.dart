import 'package:drift/drift.dart';

/// A single user preference, stored as a name/value pair.
///
/// Deliberately key-value rather than one column per setting: the settings
/// screen in Phase 13 adds units, notification preferences and the accent
/// colour, and each of those would otherwise mean another schema migration.
/// One table, one migration, and new settings are just new rows.
///
/// The cost is that values are text and callers have to parse them — which is
/// why nothing reads this table directly. A repository with typed getters wraps
/// it, so a typo in a key or a bad parse is caught in one place instead of
/// scattered across the UI.
class AppSettings extends Table {
  /// The setting's key, e.g. "lifter_sex". Use the constants in the repository
  /// rather than typing these as literals.
  TextColumn get name => text()();

  /// The value as text. For enums this is the enum's `name`.
  TextColumn get value => text()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {name};
}
