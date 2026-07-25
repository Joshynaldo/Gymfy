import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';

part 'muscle_volume_repository.g.dart';

/// One logged set reduced to just what the muscle map needs: how much work it
/// represents and which muscles it hits.
typedef VolumeSample = ({double weight, int reps, List<String> muscleIds});

/// Turns logged sets into a normalized 0.0–1.0 intensity per muscle, for the
/// heatmap. Reads from the workout log joined with the exercise library.
class MuscleVolumeRepository {
  MuscleVolumeRepository(this._db);

  final AppDatabase _db;

  /// Intensities from every set logged in sessions started on/after [since]
  /// (e.g. the last 7 days for a weekly view).
  Stream<Map<String, double>> watchIntensitiesSince(DateTime since) {
    final query = _db.select(_db.loggedSets).join([
      innerJoin(
        _db.workoutSessions,
        _db.workoutSessions.id.equalsExp(_db.loggedSets.sessionId),
      ),
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.loggedSets.exerciseId),
      ),
    ])..where(_db.workoutSessions.startedAt.isBiggerOrEqualValue(since));

    return query.watch().map((rows) => muscleIntensities(_toSamples(rows)));
  }

  /// Intensities from the sets logged in a single session.
  Stream<Map<String, double>> watchSessionIntensities(int sessionId) {
    final query = _db.select(_db.loggedSets).join([
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.loggedSets.exerciseId),
      ),
    ])..where(_db.loggedSets.sessionId.equals(sessionId));

    return query.watch().map((rows) => muscleIntensities(_toSamples(rows)));
  }

  Iterable<VolumeSample> _toSamples(List<TypedResult> rows) {
    return rows.map((row) {
      final set = row.readTable(_db.loggedSets);
      final exercise = row.readTable(_db.exercises);
      return (
        weight: set.weight,
        reps: set.reps,
        muscleIds: exercise.muscleIds,
      );
    });
  }
}

/// Aggregates [samples] into a normalized intensity (0.0–1.0) per muscle id.
///
/// Each set's effort is its volume (weight × reps), falling back to plain reps
/// for bodyweight sets (weight 0) so movements like pull-ups still register.
/// That effort is added to every muscle the exercise trains, then the whole
/// map is scaled so the hardest-worked muscle is 1.0 and the rest are relative
/// to it. Returns an empty map if there's nothing to show.
Map<String, double> muscleIntensities(Iterable<VolumeSample> samples) {
  final totals = <String, double>{};
  for (final s in samples) {
    final effort = s.weight > 0 ? s.weight * s.reps : s.reps.toDouble();
    if (effort <= 0) continue;
    for (final muscle in s.muscleIds) {
      totals[muscle] = (totals[muscle] ?? 0) + effort;
    }
  }

  if (totals.isEmpty) return const {};

  final max = totals.values.reduce((a, b) => a > b ? a : b);
  if (max <= 0) return const {};

  return {for (final e in totals.entries) e.key: e.value / max};
}

/// App-wide access to the [MuscleVolumeRepository].
@Riverpod(keepAlive: true)
MuscleVolumeRepository muscleVolumeRepository(Ref ref) {
  return MuscleVolumeRepository(ref.watch(appDatabaseProvider));
}

/// Intensities for the last 7 days (the weekly muscle map).
final weeklyMuscleIntensitiesProvider =
    StreamProvider<Map<String, double>>((ref) {
      final since = DateTime.now().subtract(const Duration(days: 7));
      return ref
          .watch(muscleVolumeRepositoryProvider)
          .watchIntensitiesSince(since);
    });

/// Intensities for a single session (the per-workout muscle map).
final sessionMuscleIntensitiesProvider =
    StreamProvider.family<Map<String, double>, int>((ref, sessionId) {
      return ref
          .watch(muscleVolumeRepositoryProvider)
          .watchSessionIntensities(sessionId);
    });
