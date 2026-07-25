import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import 'exercise_seed_data.dart';

part 'exercise_repository.g.dart';

/// All database access for exercises lives here.
class ExerciseRepository {
  ExerciseRepository(this._db);

  final AppDatabase _db;

  /// Loads the built-in [exerciseSeedData] into the database.
  ///
  /// Idempotent: this is an upsert keyed on each exercise's `id`, so running
  /// it on every launch never creates duplicates, and editing the seed list
  /// updates the stored rows on the next launch. Cheap enough (~27 rows in one
  /// batch) to run at startup even on older phones.
  Future<void> seed() async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.exercises, exerciseSeedData);
    });
  }

  /// Streams every exercise, ordered by name. The stream automatically
  /// re-emits whenever the exercises table changes, so any UI watching it
  /// updates itself with no manual refresh.
  Stream<List<Exercise>> watchAllExercises() {
    final query = _db.select(_db.exercises)
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return query.watch();
  }

  /// Streams a single exercise by its id (null if it doesn't exist), updating
  /// automatically if that row changes.
  Stream<Exercise?> watchExercise(String id) {
    final query = _db.select(_db.exercises)..where((t) => t.id.equals(id));
    return query.watchSingleOrNull();
  }
}

/// App-wide access to the [ExerciseRepository].
@Riverpod(keepAlive: true)
ExerciseRepository exerciseRepository(Ref ref) {
  return ExerciseRepository(ref.watch(appDatabaseProvider));
}

/// The live list of all exercises from the database, as an `AsyncValue`
/// (loading / error / data) the UI can react to.
///
/// Written as a manual `StreamProvider` (not code-generated) because its type
/// is Drift's generated `Exercise` class, which the Riverpod generator can't
/// emit in generated code.
final exerciseListProvider = StreamProvider<List<Exercise>>((ref) {
  return ref.watch(exerciseRepositoryProvider).watchAllExercises();
});

/// The live single exercise for a given id, as an `AsyncValue` (loading /
/// error / data), where the data can be null if no exercise has that id.
///
/// A `.family` provider so the detail screen can request one exercise by id.
/// Hand-written (not code-generated) for the same reason as
/// [exerciseListProvider]: it exposes Drift's generated `Exercise` type.
final exerciseProvider = StreamProvider.family<Exercise?, String>((ref, id) {
  return ref.watch(exerciseRepositoryProvider).watchExercise(id);
});
