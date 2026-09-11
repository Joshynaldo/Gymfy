import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../calculator/data/one_rm_math.dart';

part 'progress_repository.g.dart';

/// One session's worth of history for a single exercise, reduced to the
/// numbers the progress chart and PRs need.
class ExerciseHistoryPoint {
  const ExerciseHistoryPoint({
    required this.date,
    required this.topWeight,
    required this.repsAtTop,
    required this.totalVolume,
  });

  /// When the session was performed.
  final DateTime date;

  /// Heaviest weight lifted for this exercise in the session.
  final double topWeight;

  /// Reps done on that heaviest set (ties broken by more reps).
  final int repsAtTop;

  /// Total volume for the exercise in the session (Σ weight × reps, with reps
  /// as the fallback for bodyweight sets).
  final double totalVolume;
}

/// The personal records for one exercise, derived from its history.
class PersonalRecords {
  const PersonalRecords({
    required this.heaviestWeight,
    required this.repsAtHeaviest,
    required this.heaviestDate,
    required this.bestVolume,
    required this.bestVolumeDate,
  });

  /// Heaviest weight ever lifted for this exercise, and the reps done on it.
  final double heaviestWeight;
  final int repsAtHeaviest;
  final DateTime heaviestDate;

  /// Best single-session volume (Σ weight × reps) for this exercise.
  final double bestVolume;
  final DateTime bestVolumeDate;
}

/// Derives [PersonalRecords] from an exercise's per-session [points], or null
/// if there's no history yet.
PersonalRecords? personalRecordsFrom(List<ExerciseHistoryPoint> points) {
  if (points.isEmpty) return null;

  var heaviest = points.first;
  var bestVolume = points.first;
  for (final p in points) {
    final beatsWeight = p.topWeight > heaviest.topWeight;
    final tiesWeightMoreReps =
        p.topWeight == heaviest.topWeight && p.repsAtTop > heaviest.repsAtTop;
    if (beatsWeight || tiesWeightMoreReps) heaviest = p;
    if (p.totalVolume > bestVolume.totalVolume) bestVolume = p;
  }

  return PersonalRecords(
    heaviestWeight: heaviest.topWeight,
    repsAtHeaviest: heaviest.repsAtTop,
    heaviestDate: heaviest.date,
    bestVolume: bestVolume.totalVolume,
    bestVolumeDate: bestVolume.date,
  );
}

/// The set that implies the biggest one-rep max, and what that max is.
typedef BestOneRm = ({double oneRm, double weight, int reps, DateTime date});

/// Finds the logged top set with the highest estimated one-rep max.
///
/// Deliberately not "the heaviest set": 90 kg × 5 beats 100 kg × 1 on every
/// formula, and that's the honest read of which day you were strongest.
///
/// Only top sets are available here (one per session), so a monster back-off
/// set can't win — an acceptable trade for not re-reading every logged set.
/// Bodyweight sets (weight 0) are skipped since there's nothing to estimate.
BestOneRm? bestEstimatedOneRm(List<ExerciseHistoryPoint> points) {
  BestOneRm? best;
  for (final p in points) {
    final estimates = estimateOneRm(weight: p.topWeight, reps: p.repsAtTop);
    if (estimates == null) continue;
    if (best == null || estimates.average > best.oneRm) {
      best = (
        oneRm: estimates.average,
        weight: p.topWeight,
        reps: p.repsAtTop,
        date: p.date,
      );
    }
  }
  return best;
}

/// Reads logged history for the progress feature.
class ProgressRepository {
  ProgressRepository(this._db);

  final AppDatabase _db;

  /// Every exercise that has at least one logged *working* set, sorted by name.
  /// These are the exercises worth charting.
  ///
  /// Warm-ups don't qualify an exercise: an empty chart is a worse answer than
  /// not offering the chart at all.
  Stream<List<Exercise>> watchExercisesWithHistory() {
    final query = _db.select(_db.loggedSets).join([
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.loggedSets.exerciseId),
      ),
    ])..where(_db.loggedSets.isWarmup.equals(false));

    return query.watch().map((rows) {
      final byId = <String, Exercise>{};
      for (final row in rows) {
        final exercise = row.readTable(_db.exercises);
        byId[exercise.id] = exercise;
      }
      final list = byId.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  /// One [ExerciseHistoryPoint] per session this exercise was trained in,
  /// oldest first — the series behind the progress chart.
  ///
  /// Working sets only. This one query feeds the chart, the personal records
  /// and the estimated 1RM, so filtering here is what keeps a 60 kg ramp-up
  /// single off your bench graph and out of your PR history. Volume on these
  /// points is working volume for the same reason — it is what "best volume
  /// day" is measured against.
  Stream<List<ExerciseHistoryPoint>> watchExerciseHistory(String exerciseId) {
    final query =
        _db.select(_db.loggedSets).join([
          innerJoin(
            _db.workoutSessions,
            _db.workoutSessions.id.equalsExp(_db.loggedSets.sessionId),
          ),
        ])..where(
          _db.loggedSets.exerciseId.equals(exerciseId) &
              _db.loggedSets.isWarmup.equals(false),
        );

    return query.watch().map((rows) {
      // Group the sets by the session they belong to.
      final bySession =
          <int, List<({DateTime date, double weight, int reps})>>{};
      for (final row in rows) {
        final set = row.readTable(_db.loggedSets);
        final session = row.readTable(_db.workoutSessions);
        bySession.putIfAbsent(session.id, () => []).add((
          date: session.startedAt,
          weight: set.weight,
          reps: set.reps,
        ));
      }

      final points = <ExerciseHistoryPoint>[];
      for (final sets in bySession.values) {
        var top = sets.first;
        var volume = 0.0;
        for (final s in sets) {
          final heavier = s.weight > top.weight;
          final sameWeightMoreReps =
              s.weight == top.weight && s.reps > top.reps;
          if (heavier || sameWeightMoreReps) top = s;
          volume += s.weight > 0 ? s.weight * s.reps : s.reps.toDouble();
        }
        points.add(
          ExerciseHistoryPoint(
            date: top.date,
            topWeight: top.weight,
            repsAtTop: top.reps,
            totalVolume: volume,
          ),
        );
      }

      points.sort((a, b) => a.date.compareTo(b.date));
      return points;
    });
  }
}

/// App-wide access to the [ProgressRepository].
@Riverpod(keepAlive: true)
ProgressRepository progressRepository(Ref ref) {
  return ProgressRepository(ref.watch(appDatabaseProvider));
}

/// The exercises that have logged history (for the progress list).
final exercisesWithHistoryProvider = StreamProvider<List<Exercise>>((ref) {
  return ref.watch(progressRepositoryProvider).watchExercisesWithHistory();
});

/// The session-by-session history for one exercise.
final exerciseHistoryProvider =
    StreamProvider.family<List<ExerciseHistoryPoint>, String>((ref, id) {
      return ref.watch(progressRepositoryProvider).watchExerciseHistory(id);
    });
