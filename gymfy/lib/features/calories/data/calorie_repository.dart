import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/utils/dates.dart';

part 'calorie_repository.g.dart';

/// Default daily calorie goal until a real setting exists (Phase 13).
const defaultCalorieGoal = 2500;

/// Database access for the daily calorie log.
class CalorieRepository {
  CalorieRepository(this._db);

  final AppDatabase _db;

  /// Streams the entries logged on [day], oldest first.
  Stream<List<CalorieEntry>> watchEntriesForDay(DateTime day) {
    final start = dateOnly(day);
    final query = _db.select(_db.calorieEntries)
      ..where((t) => t.date.equals(start))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
    return query.watch();
  }

  /// Adds a food entry to [day].
  Future<void> addEntry({
    required DateTime day,
    required String name,
    required int calories,
    int protein = 0,
    int carbs = 0,
    int fat = 0,
  }) {
    return _db
        .into(_db.calorieEntries)
        .insert(
          CalorieEntriesCompanion.insert(
            date: dateOnly(day),
            name: name.trim(),
            calories: Value(calories),
            protein: Value(protein),
            carbs: Value(carbs),
            fat: Value(fat),
          ),
        );
  }

  /// Deletes a single entry.
  Future<void> deleteEntry(int id) {
    return (_db.delete(_db.calorieEntries)..where((t) => t.id.equals(id))).go();
  }
}

/// App-wide access to the [CalorieRepository].
@Riverpod(keepAlive: true)
CalorieRepository calorieRepository(Ref ref) {
  return CalorieRepository(ref.watch(appDatabaseProvider));
}

/// The live calorie entries for a given day.
final calorieEntriesForDayProvider =
    StreamProvider.family<List<CalorieEntry>, DateTime>((ref, day) {
      return ref.watch(calorieRepositoryProvider).watchEntriesForDay(day);
    });
