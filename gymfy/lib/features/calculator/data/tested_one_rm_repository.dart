import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/utils/dates.dart';

part 'tested_one_rm_repository.g.dart';

/// Reads and writes the one-rep maxes the user tested for real.
class TestedOneRmRepository {
  TestedOneRmRepository(this._db);

  final AppDatabase _db;

  /// The tested max for one exercise, or null if it was never tested.
  Stream<TestedOneRm?> watchForExercise(String exerciseId) {
    final query = _db.select(_db.testedOneRms)
      ..where((t) => t.exerciseId.equals(exerciseId));
    return query.watchSingleOrNull();
  }

  /// Records a tested max, replacing any previous one for the exercise.
  ///
  /// [exerciseId] is the primary key, so the default conflict target is the
  /// right one here — a retest overwrites rather than piling up.
  Future<void> setForExercise({
    required String exerciseId,
    required double weightKg,
    required DateTime testedOn,
  }) async {
    await _db
        .into(_db.testedOneRms)
        .insertOnConflictUpdate(
          TestedOneRmsCompanion.insert(
            exerciseId: exerciseId,
            weightKg: weightKg,
            testedOn: dateOnly(testedOn),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Forgets the tested max, so the exercise falls back to the estimate.
  Future<void> clearForExercise(String exerciseId) async {
    await (_db.delete(
      _db.testedOneRms,
    )..where((t) => t.exerciseId.equals(exerciseId))).go();
  }
}

/// App-wide access to the [TestedOneRmRepository].
@Riverpod(keepAlive: true)
TestedOneRmRepository testedOneRmRepository(Ref ref) {
  return TestedOneRmRepository(ref.watch(appDatabaseProvider));
}

/// The tested max for one exercise, or null if there isn't one.
final testedOneRmProvider = StreamProvider.family<TestedOneRm?, String>((
  ref,
  exerciseId,
) {
  return ref.watch(testedOneRmRepositoryProvider).watchForExercise(exerciseId);
});
