import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';

part 'settings_repository.g.dart';

/// Typed access to the key-value settings table.
///
/// Every setting goes through here rather than the table directly, so keys are
/// spelled in exactly one place and a value that can't be parsed degrades to
/// "not set" instead of crashing a screen.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  /// Watches one setting's raw text value, or null if it was never set.
  Stream<String?> watchRaw(String name) {
    final query = _db.select(_db.appSettings)
      ..where((t) => t.name.equals(name));
    return query.watchSingleOrNull().map((row) => row?.value);
  }

  /// Reads one setting's raw text value once.
  Future<String?> readRaw(String name) async {
    final query = _db.select(_db.appSettings)
      ..where((t) => t.name.equals(name));
    final row = await query.getSingleOrNull();
    return row?.value;
  }

  /// Writes a setting, replacing any previous value ([name] is the key).
  Future<void> write(String name, String value) async {
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            name: name,
            value: value,
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Removes a setting, so it reads as "not set" again.
  Future<void> clear(String name) async {
    await (_db.delete(_db.appSettings)..where((t) => t.name.equals(name))).go();
  }
}

/// App-wide access to the [SettingsRepository].
@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
}
