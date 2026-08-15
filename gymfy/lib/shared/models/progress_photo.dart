import 'package:drift/drift.dart';

/// A progress photo the user picked from their gallery.
///
/// The image itself lives as a file in the app's documents directory; this table
/// only records which file belongs to which day.
///
/// Two deliberate choices:
///
///   * The picked photo is **copied** into app storage rather than referenced
///     where it sits in the gallery. A gallery path is not stable — deleting or
///     moving the original would leave a permanently broken thumbnail here.
///   * Only the [fileName] is stored, never an absolute path. The app's
///     documents directory can move between OS versions and reinstalls, so the
///     full path is resolved at read time.
class ProgressPhotos extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The calendar day the photo represents (stored normalized to midnight).
  /// Several photos can share a day — front, back, side.
  DateTimeColumn get date => dateTime()();

  /// File name inside the app's progress-photos directory, e.g.
  /// "2026-07-25_1753441200000.jpg".
  TextColumn get fileName => text().withLength(min: 1, max: 120)();

  /// Optional label, e.g. "front relaxed".
  TextColumn get note => text().withLength(max: 60).nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
