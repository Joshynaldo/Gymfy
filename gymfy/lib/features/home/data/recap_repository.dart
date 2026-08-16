import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import 'recap.dart';

part 'recap_repository.g.dart';

/// Feeds the Home tab's recap charts.
///
/// Reads every logged set once and hands the lot to [summariseRecap]. Reading
/// everything rather than just the period is deliberate: a personal record can
/// only be judged against all history, so the window has to be applied after
/// the walk, not in the query.
///
/// On older hardware this is the one place worth watching. It is a single
/// indexed join with no per-row queries, and a few thousand sets is nothing for
/// SQLite — but if someone's log ever runs to tens of thousands, the PR walk is
/// what to move into SQL first.
class RecapRepository {
  RecapRepository(this._db);

  final AppDatabase _db;

  /// Every set from a completed session, with its date and muscles.
  ///
  /// Only completed sessions, matching the streak and the weekly totals: a
  /// workout you started and walked out of isn't training.
  Stream<List<RecapSet>> watchAllSets() {
    final query = _db.select(_db.loggedSets).join([
      innerJoin(
        _db.workoutSessions,
        _db.workoutSessions.id.equalsExp(_db.loggedSets.sessionId) &
            _db.workoutSessions.completedAt.isNotNull(),
      ),
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.loggedSets.exerciseId),
      ),
    ]);

    return query.watch().map((rows) {
      return [
        for (final row in rows)
          () {
            final set = row.readTable(_db.loggedSets);
            final session = row.readTable(_db.workoutSessions);
            final exercise = row.readTable(_db.exercises);
            return (
              // Dated by when the workout finished, so a session that ran past
              // midnight counts once, on the day it was completed — the same
              // day the streak and the weekly totals credit it to.
              date: session.completedAt ?? session.startedAt,
              sessionId: session.id,
              exerciseId: set.exerciseId,
              weight: set.weight,
              reps: set.reps,
              muscleIds: exercise.muscleIds,
            );
          }(),
      ];
    });
  }
}

/// App-wide access to the [RecapRepository].
@Riverpod(keepAlive: true)
RecapRepository recapRepository(Ref ref) {
  return RecapRepository(ref.watch(appDatabaseProvider));
}

/// Every logged set, for the recap.
final recapSetsProvider = StreamProvider<List<RecapSet>>((ref) {
  return ref.watch(recapRepositoryProvider).watchAllSets();
});

/// The recap for one period. Recomputed when the log changes, not on a timer.
final recapProvider = Provider.family<RecapSummary?, RecapPeriod>((
  ref,
  period,
) {
  final sets = ref.watch(recapSetsProvider).value;
  if (sets == null) return null;
  return summariseRecap(
    period: period,
    today: DateTime.now(),
    allSets: sets,
  );
});
