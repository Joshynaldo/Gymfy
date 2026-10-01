import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/models/set_type.dart';
import '../../../shared/utils/units.dart';
import '../../plates/data/plate_math.dart';
import 'overload_math.dart';
import 'overload_preference.dart';
import 'percent_target.dart';
import 'training_block.dart';

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
  ///
  /// [skipSession], when given, leaves out every session it returns true for,
  /// judged by when the session was finished. A training block uses it to keep
  /// its deload weeks out of the history: a week lifted at 60 % on purpose is
  /// not the weight to progress from, nor the weight to take 60 % of again.
  Future<List<List<LoggedSet>>> recentSessions(
    String exerciseId, {
    int limit = 12,
    bool Function(DateTime completedAt)? skipSession,
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
              // weight down and quietly suggest a *decrease*. Drop sets are out for
              // the same reason (see SetType.countsTowardStrength).
              _db.loggedSets.setType.isNotIn(strengthExcludedSetTypes),
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
      final session = row.readTable(_db.workoutSessions);
      if (skipSession != null && skipSession(session.completedAt!)) continue;
      final sessionId = session.id;
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
  ///
  /// [split] is the split the slot belongs to. When it runs a training block,
  /// sessions from its deload weeks are left out of the history, so the week
  /// after a deload progresses from the last real training week rather than
  /// from the deliberately light one.
  Future<OverloadSuggestion?> suggestionFor(
    WorkoutExercise entry,
    Exercise exercise,
    OverloadConfig config, {
    Split? split,
  }) async {
    // The per-muscle default is still the fallback even in Fixed and Percent
    // mode: it's what tells us this exercise shouldn't be auto-progressed at
    // all. Null means core work, and no number beats a number nobody should
    // follow.
    final muscleDefault = defaultIncrementKg(exercise.muscleIds);
    if (muscleDefault == null) return null;

    final sessions = await recentSessions(
      exercise.id,
      skipSession: _deloadWeeksOf(split),
    );

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

  /// The deload-week suggestion for [exercise] while [split]'s block is in its
  /// deload week: [deloadPercent] of the top weight from the last session
  /// *outside* a deload week.
  ///
  /// Outside, because a second deload session in the same week would otherwise
  /// take 60 % of the first one's 60 %, and the week would get lighter every
  /// time you trained.
  ///
  /// Same exclusions as [suggestionFor]: core work gets no number, and with no
  /// history there is nothing to take a percentage of.
  Future<OverloadSuggestion?> blockDeloadFor(
    Exercise exercise,
    Split split, {
    required double deloadPercent,
  }) async {
    if (defaultIncrementKg(exercise.muscleIds) == null) return null;

    final sessions = await recentSessions(
      exercise.id,
      limit: 1,
      skipSession: _deloadWeeksOf(split),
    );
    final last = sessions.isEmpty ? null : topWeight(sessions.first);
    if (last == null || last <= 0) {
      return const OverloadSuggestion(
        weight: 0,
        reason: OverloadReason.firstTime,
      );
    }

    return OverloadSuggestion(
      weight: last * deloadPercent / 100,
      reason: OverloadReason.blockDeload,
      deloadPercent: deloadPercent,
    );
  }

  /// The split that planned day [dayId] belongs to, or null if the day is
  /// gone.
  Future<Split?> splitOfDay(int dayId) async {
    final query = _db.select(_db.splits).join([
      innerJoin(
        _db.workoutDays,
        _db.workoutDays.splitId.equalsExp(_db.splits.id),
      ),
    ])..where(_db.workoutDays.id.equals(dayId));
    final row = await query.getSingleOrNull();
    return row?.readTable(_db.splits);
  }

  /// Whether a session finished on a given day fell in a deload week of
  /// [split]'s block, or null when the split runs no block at all.
  static bool Function(DateTime)? _deloadWeeksOf(Split? split) {
    if (split == null || split.blockWeeks == null) return null;
    return (completedAt) =>
        trainingBlockWeekForSplit(split, completedAt)?.isDeload ?? false;
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

  final lighter =
      suggestion.reason == OverloadReason.deload ||
      suggestion.reason == OverloadReason.blockDeload;
  if (lighter || load.isExact) {
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

/// The weight for a planned percentage of 1RM, rounded to the nearest weight
/// the user can load, or null when there is no percentage target to resolve
/// or no 1RM to take it of.
///
/// [deloadPercent] is the training block's deload load when this is a deload
/// week; the planned percentage is then lightened by it, and the suggestion
/// says so.
///
/// Timed exercises never get one: a percentage of a one-rep max means nothing
/// for a plank.
OverloadSuggestion? percentOfMaxSuggestion({
  required WorkoutExercise entry,
  required Exercise exercise,
  required double? oneRmKg,
  required WeightUnit unit,
  required List<double> plates,
  required double gymBar,
  double? deloadPercent,
}) {
  final percent = entry.targetPercent;
  if (percent == null || percent <= 0 || exercise.isTimed) return null;
  if (oneRmKg == null || oneRmKg <= 0) return null;

  return OverloadSuggestion(
    weight: nearestLoadable(
      kilograms: percentOfMaxKg(
        oneRmKg: oneRmKg,
        percent: percent,
        deloadPercent: deloadPercent,
      ),
      plateLoaded: exercise.isPlateLoaded,
      unit: unit,
      plates: plates,
      bar: barForExercise(exercise.barWeightKg, gymBar, unit),
    ),
    reason: deloadPercent == null
        ? OverloadReason.percentOfMax
        : OverloadReason.blockDeload,
    targetPercent: percent,
    deloadPercent: deloadPercent,
  );
}

/// The suggestion for one planned exercise, already rounded to a weight the
/// user can load. Null when there is nothing to suggest.
///
/// In order of precedence:
/// 1. A percentage-of-1RM target on the plan, resolved against the tested or
///    estimated max — lightened by the block's deload percentage in a deload
///    week. Shown whether or not overload is switched on: it is the plan
///    speaking, not the progression.
/// 2. The split's training block in its deload week: the deload percentage of
///    the last training-week weight. Also independent of the overload switch,
///    since the block is something the user set up on the split itself.
/// 3. Progressive overload, when it is on and there is history to build on.
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
      final entry = key.entry;
      final exercise = key.exercise;

      // One-shot reads below rather than watched streams, like the history
      // the suggestion is built from: the log sheet awaits this provider with
      // `ref.read(...).future`, and a stream dependency nothing is listening
      // to never emits, which would leave the sheet waiting forever.
      final repository = ref.watch(overloadRepositoryProvider);
      final split = await repository.splitOfDay(entry.dayId);
      final week = split == null
          ? null
          : trainingBlockWeekForSplit(split, clock.now());
      final deloadPercent = week != null && week.isDeload
          ? deloadPercentFor(split!)
          : null;

      if (entry.targetPercent != null && !exercise.isTimed) {
        final oneRm = await readWorkingOneRm(ref, exercise.id);
        final byPercent = percentOfMaxSuggestion(
          entry: entry,
          exercise: exercise,
          oneRmKg: oneRm,
          unit: ref.watch(weightUnitProvider),
          plates: ref.watch(availablePlatesProvider),
          gymBar: ref.watch(barWeightProvider),
          deloadPercent: deloadPercent,
        );
        // No 1RM yet falls through to the overload suggestion below, so a
        // percentage day you have never trained still gets last week's weight.
        if (byPercent != null) return byPercent;
      }

      final OverloadSuggestion? raw;
      if (deloadPercent != null) {
        raw = await repository.blockDeloadFor(
          exercise,
          split!,
          deloadPercent: deloadPercent,
        );
      } else {
        final config = ref.watch(overloadConfigProvider);
        if (!config.enabled) return null;
        raw = await repository.suggestionFor(
          entry,
          exercise,
          config,
          split: split,
        );
      }
      if (raw == null || raw.reason == OverloadReason.firstTime) return null;

      return OverloadSuggestion(
        weight: loadableSuggestion(
          suggestion: raw,
          plateLoaded: exercise.isPlateLoaded,
          unit: ref.watch(weightUnitProvider),
          plates: ref.watch(availablePlatesProvider),
          bar: ref.watch(barWeightProvider),
        ),
        reason: raw.reason,
        deloadPercent: raw.deloadPercent,
      );
    });
