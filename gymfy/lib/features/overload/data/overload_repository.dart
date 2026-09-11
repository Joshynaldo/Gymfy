import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/utils/units.dart';
import '../../plates/data/plate_math.dart';
import 'overload_math.dart';
import 'overload_preference.dart';

part 'overload_repository.g.dart';

/// Reads the logged history that a progression suggestion is built from.
///
/// No progression state is stored anywhere: how much you lifted, whether you
/// hit your reps, and how many increases you've had in a row are all derived
/// from the sets themselves. There is one source of truth, so nothing can fall
/// out of step with what you actually did.
class OverloadRepository {
  OverloadRepository(this._db);

  final AppDatabase _db;

  /// The sets logged for [exerciseId], grouped by session, newest session first.
  ///
  /// Only completed sessions count: a workout still in progress is the one
  /// being suggested *for*, and letting it advise itself would move the target
  /// mid-session.
  Future<List<List<LoggedSet>>> recentSessions(
    String exerciseId, {
    int limit = 12,
  }) async {
    final query =
        _db.select(_db.loggedSets).join([
          innerJoin(
            _db.workoutSessions,
            _db.workoutSessions.id.equalsExp(_db.loggedSets.sessionId) &
                _db.workoutSessions.completedAt.isNotNull(),
          ),
        ])..where(
          _db.loggedSets.exerciseId.equals(exerciseId) &
              // Working sets only. Double progression asks "did every planned set
              // hit the top of the rep range?" — counting ramp-up sets would answer
              // that with the wrong rows, and a light warm-up would drag the top
              // weight down and quietly suggest a *decrease*.
              _db.loggedSets.isWarmup.equals(false),
        );
    query.orderBy([
      OrderingTerm(
        expression: _db.workoutSessions.completedAt,
        mode: OrderingMode.desc,
      ),
      // Sessions finished in the same second would otherwise interleave, which
      // would scramble the "increases in a row" walk below.
      OrderingTerm(expression: _db.workoutSessions.id, mode: OrderingMode.desc),
      OrderingTerm(expression: _db.loggedSets.setNumber),
    ]);

    final rows = await query.get();

    final bySession = <int, List<LoggedSet>>{};
    final order = <int>[];
    for (final row in rows) {
      final sessionId = row.readTable(_db.workoutSessions).id;
      if (!bySession.containsKey(sessionId)) order.add(sessionId);
      bySession
          .putIfAbsent(sessionId, () => [])
          .add(row.readTable(_db.loggedSets));
    }
    return [for (final id in order.take(limit)) bySession[id]!];
  }

  /// How many sessions in a row got heavier, counting back from the latest.
  ///
  /// Derived rather than stored, so a manual deload or a light week resets it
  /// on its own — there is no counter to get out of step with the history.
  int increasesInARow(List<List<LoggedSet>> sessions) {
    var count = 0;
    for (var i = 0; i + 1 < sessions.length; i++) {
      final newer = topWeight(sessions[i]);
      final older = topWeight(sessions[i + 1]);
      if (newer == null || older == null || newer <= older) break;
      count++;
    }
    return count;
  }

  /// The suggestion for the next set of [entry], under [config].
  ///
  /// Whether overload is on at all is checked by the caller — the provider
  /// below — so this stays a pure "given these settings and this history, what
  /// next" question.
  Future<OverloadSuggestion?> suggestionFor(
    WorkoutExercise entry,
    Exercise exercise,
    OverloadConfig config,
  ) async {
    // The per-muscle default is still the fallback even in Fixed and Percent
    // mode: it's what tells us this exercise shouldn't be auto-progressed at
    // all. Null means core work, and no number beats a number nobody should
    // follow.
    final muscleDefault = defaultIncrementKg(exercise.muscleIds);
    if (muscleDefault == null) return null;

    final sessions = await recentSessions(exercise.id);

    return suggestNextWeight(
      lastSets: sessions.isEmpty ? const [] : sessions.first,
      plannedSets: entry.defaultSets,
      targetReps: targetRepsFor(entry),
      // Also the fallback when a percentage lands on zero, which it does for
      // bodyweight exercises.
      incrementKg: config.fixedOrNull ?? muscleDefault,
      percent: config.percentOrNull,
      increasesInARow: increasesInARow(sessions),
      deloadAfterWeeks: config.deloadWeeks,
    );
  }
}

/// App-wide access to the [OverloadRepository].
@Riverpod(keepAlive: true)
OverloadRepository overloadRepository(Ref ref) {
  return OverloadRepository(ref.watch(appDatabaseProvider));
}

/// A suggestion rounded to a weight the user can actually load.
///
/// An increment of 1.25 kg on a barbell is half a plate per side, which nobody
/// owns — so the raw number is snapped upward to the next weight that IS
/// loadable. Upward on purpose: rounding down would turn a suggested increase
/// into no increase at all, and the app would look like it had forgotten.
///
/// A deload rounds the other way, since the point there is to go lighter.
double loadableSuggestion({
  required OverloadSuggestion suggestion,
  required bool plateLoaded,
  required WeightUnit unit,
  required List<double> plates,
  required double bar,
}) {
  if (suggestion.reason == OverloadReason.firstTime) return 0;

  if (!plateLoaded) {
    // Dumbbells and machines move in their own steps; the unit's increment is
    // the closest honest approximation.
    return roundToLoadable(suggestion.weight, unit);
  }

  // Plates are physical objects labelled in the display unit, so the search
  // happens there and converts back once at the end.
  final wanted = weightIn(suggestion.weight, unit);
  final load = calculatePlates(target: wanted, bar: bar, plates: plates);

  if (suggestion.reason == OverloadReason.deload || load.isExact) {
    return weightToKilograms(load.achieved, unit);
  }

  // `calculatePlates` never overshoots, so an inexact answer is below the
  // target. Ask again for the next step up, one smallest-plate-pair higher.
  final step = plates.isEmpty ? 0.0 : plates.last * 2;
  final up = calculatePlates(
    target: load.achieved + step,
    bar: bar,
    plates: plates,
  );
  return weightToKilograms(up.achieved, unit);
}

/// The suggestion for one planned exercise, already rounded to a weight the
/// user can load. Null when overload is off, or when there's no history to
/// build on yet.
///
/// Keyed on a record of the two rows rather than on `PlannedExercise`, which
/// has no value equality — a family keyed on it would mint a fresh provider on
/// every rebuild and never reuse a result. Drift's row classes do compare by
/// value, so a record of them is a stable key.
final overloadSuggestionProvider =
    FutureProvider.family<
      OverloadSuggestion?,
      ({WorkoutExercise entry, Exercise exercise})
    >((ref, key) async {
      final config = ref.watch(overloadConfigProvider);
      if (!config.enabled) return null;

      final raw = await ref
          .watch(overloadRepositoryProvider)
          .suggestionFor(key.entry, key.exercise, config);
      if (raw == null || raw.reason == OverloadReason.firstTime) return null;

      return OverloadSuggestion(
        weight: loadableSuggestion(
          suggestion: raw,
          plateLoaded: key.exercise.isPlateLoaded,
          unit: ref.watch(weightUnitProvider),
          plates: ref.watch(availablePlatesProvider),
          bar: ref.watch(barWeightProvider),
        ),
        reason: raw.reason,
      );
    });
