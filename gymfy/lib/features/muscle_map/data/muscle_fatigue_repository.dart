import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';

part 'muscle_fatigue_repository.g.dart';

/// One working set reduced to what the fatigue map needs: when it happened and
/// which muscles it hit.
typedef FatigueSample = ({DateTime performedAt, List<String> muscleIds});

/// How long it takes for a muscle's accumulated fatigue to halve.
///
/// Two days: a session read the morning after is still most of the way to
/// "worked", by day four it's a quarter, and after a week it's noise. That
/// matches how long training actually keeps a muscle sore and under-recovered,
/// and it means a normal weekly split never shows everything lit at once.
const fatigueHalfLife = Duration(hours: 48);

/// The decayed set count that reads as completely fatigued.
///
/// Twelve hard sets on one muscle in a day is a heavy session by most
/// standards, so that is where the scale tops out. Anything above it clamps —
/// there is no "more than fully fatigued" worth drawing.
const fatigueSaturationSets = 12.0;

/// How far back to read. Past this, decay has made a set's contribution smaller
/// than the map can render (a fortnight is seven half-lives, under 1%), so
/// reading further would cost query time to change nothing.
const fatigueWindow = Duration(days: 14);

/// Turns recent working sets into a 0.0–1.0 fatigue level per muscle.
class MuscleFatigueRepository {
  MuscleFatigueRepository(this._db);

  final AppDatabase _db;

  /// Streams current fatigue per muscle, as of [now].
  Stream<Map<String, double>> watchFatigue(DateTime now) {
    final query = _db.select(_db.loggedSets).join([
      innerJoin(
        _db.workoutSessions,
        _db.workoutSessions.id.equalsExp(_db.loggedSets.sessionId),
      ),
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.loggedSets.exerciseId),
      ),
    ])..where(
      _db.workoutSessions.startedAt.isBiggerOrEqualValue(
        now.subtract(fatigueWindow),
      ) &
          // Warm-ups don't fatigue you — ramping up to your working weight is
          // the opposite of accumulating work. Counting them would make a
          // careful lifter look more beaten up than a careless one.
          _db.loggedSets.isWarmup.equals(false),
    );

    return query.watch().map((rows) {
      final samples = rows.map((row) {
        final session = row.readTable(_db.workoutSessions);
        final exercise = row.readTable(_db.exercises);
        // Sets have no timestamp of their own; the session's start is the best
        // answer available and is never more than a workout's length out.
        return (
          performedAt: session.startedAt,
          muscleIds: exercise.muscleIds,
        );
      });
      return muscleFatigue(samples, now: now);
    });
  }
}

/// Aggregates [samples] into a 0.0–1.0 fatigue level per muscle id.
///
/// Every working set counts as one unit of fatigue on each muscle it trains,
/// decayed by how long ago it was, then divided by [fatigueSaturationSets] and
/// clamped.
///
/// **Sets, not volume.** A set of squats moves five times the weight of a set
/// of curls, so by kilograms the legs would sit pinned at maximum forever and
/// the map would say the same thing every day. Counting sets asks "how much
/// work has this muscle absorbed lately", which is the question fatigue is
/// about. It's the same reasoning the recap charts already use.
///
/// **Absolute, not relative.** Unlike the volume heatmap this deliberately does
/// *not* scale so the worst muscle is 1.0. After a rest week everything should
/// be dark; normalizing would instead light up whichever muscle happened to be
/// least recovered and claim it was fried.
Map<String, double> muscleFatigue(
  Iterable<FatigueSample> samples, {
  required DateTime now,
}) {
  final totals = <String, double>{};
  for (final sample in samples) {
    final elapsed = now.difference(sample.performedAt);
    // A set logged in the future (clock change, edited data) would otherwise
    // decay *upward* into a fatigue above the saturation point.
    final hours = elapsed.isNegative ? 0.0 : elapsed.inMinutes / 60.0;
    final weight = math.pow(0.5, hours / fatigueHalfLife.inHours).toDouble();

    for (final muscle in sample.muscleIds) {
      totals[muscle] = (totals[muscle] ?? 0) + weight;
    }
  }

  if (totals.isEmpty) return const {};

  return {
    for (final entry in totals.entries)
      entry.key: (entry.value / fatigueSaturationSets).clamp(0.0, 1.0),
  };
}

/// App-wide access to the [MuscleFatigueRepository].
@Riverpod(keepAlive: true)
MuscleFatigueRepository muscleFatigueRepository(Ref ref) {
  return MuscleFatigueRepository(ref.watch(appDatabaseProvider));
}

/// Current fatigue per muscle.
///
/// Reads the clock once per watch rather than ticking: fatigue changes on the
/// scale of hours, so a map that redrew every second would burn battery to show
/// the same picture. Re-entering the tab re-reads it.
final muscleFatigueProvider = StreamProvider<Map<String, double>>((ref) {
  return ref.watch(muscleFatigueRepositoryProvider).watchFatigue(
    DateTime.now(),
  );
});
