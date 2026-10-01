// Spotting a personal record as it happens, and listing the ones a session set.
//
// The progress screen already shows your best-ever numbers; this is the other
// half — noticing the moment one of them moves. Two readers use it: the active
// workout, which checks each set as it is logged and celebrates a new best on
// the spot, and the workout summary, which lists every record the session set.
//
// The rules, so the two never disagree:
//
// - **Working sets only** (`isWorkingSet`). A warm-up or a drop set is never a
//   record and never part of the bar a record has to clear — the same strength
//   filter as e1RM, the progress chart and overload.
// - **Strictly better.** Matching your best is not a new one; a second set at
//   the same top weight must not celebrate again.
// - **Never the first time.** With no earlier working set to beat there is no
//   record — otherwise every exercise a new user logs would throw a party, and
//   the alert would mean nothing by the second session.
// - **Like for like.** A hold is compared with holds (seconds), a bodyweight
//   set with bodyweight sets (reps), a loaded set by its weight and its
//   estimated one-rep max. Session volume is a summary-only record: it grows
//   with every set, so celebrating it mid-session would fire on the last set of
//   every good day.

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/models/set_type.dart';
import '../../calculator/data/one_rm_math.dart';

part 'personal_records.g.dart';

/// Which best was beaten.
enum RecordKind {
  /// Heaviest weight on a loaded set.
  weight('Heaviest weight'),

  /// Best estimated one-rep max, on the same formulas the calculator uses.
  oneRm('Best estimated 1RM'),

  /// Most reps on a bodyweight set (no added load).
  reps('Most reps'),

  /// Longest single hold, for an exercise logged by time.
  hold('Longest hold'),

  /// Most working volume in one session. Summary only — see the file header.
  volume('Best session volume');

  const RecordKind(this.label);

  final String label;
}

/// One record broken: what kind, the new best and the one it beat.
///
/// Values are in the record's own unit: kilograms for [RecordKind.weight],
/// [RecordKind.oneRm] and [RecordKind.volume], a count for [RecordKind.reps],
/// seconds for [RecordKind.hold].
class BrokenRecord {
  const BrokenRecord({
    required this.kind,
    required this.value,
    required this.previous,
  });

  final RecordKind kind;
  final double value;
  final double previous;

  @override
  bool operator ==(Object other) =>
      other is BrokenRecord &&
      other.kind == kind &&
      other.value == value &&
      other.previous == previous;

  @override
  int get hashCode => Object.hash(kind, value, previous);

  @override
  String toString() => 'BrokenRecord(${kind.name}: $previous → $value)';
}

/// The records one exercise set in a session.
class ExerciseRecords {
  const ExerciseRecords({required this.exerciseId, required this.records});

  final String exerciseId;
  final List<BrokenRecord> records;
}

/// The bests a new set has to beat. Null means "never done", which is never
/// beaten — see "Never the first time" above.
class RecordBaseline {
  const RecordBaseline({
    this.weightKg,
    this.oneRmKg,
    this.bodyweightReps,
    this.holdSeconds,
    this.volumeKg,
  });

  /// The bests among [sets], working sets only.
  ///
  /// [RecordBaseline.volumeKg] is the best *session*, so the sets are grouped
  /// by the session they were logged in.
  factory RecordBaseline.of(Iterable<LoggedSet> sets) {
    double? weight;
    double? oneRm;
    int? bodyweightReps;
    int? hold;
    final volumeBySession = <int, double>{};

    for (final set in sets) {
      if (!SetType.parse(set.setType).countsTowardStrength) continue;

      volumeBySession[set.sessionId] =
          (volumeBySession[set.sessionId] ?? 0) + workingVolumeOf(set);

      final seconds = set.seconds;
      if (seconds != null) {
        if (hold == null || seconds > hold) hold = seconds;
        continue;
      }
      if (set.weight > 0) {
        if (weight == null || set.weight > weight) weight = set.weight;
        final estimate = estimatedOneRmOf(weightKg: set.weight, reps: set.reps);
        if (estimate != null && (oneRm == null || estimate > oneRm)) {
          oneRm = estimate;
        }
      } else if (set.reps > 0) {
        if (bodyweightReps == null || set.reps > bodyweightReps) {
          bodyweightReps = set.reps;
        }
      }
    }

    double? volume;
    for (final value in volumeBySession.values) {
      if (value > 0 && (volume == null || value > volume)) volume = value;
    }

    return RecordBaseline(
      weightKg: weight,
      oneRmKg: oneRm,
      bodyweightReps: bodyweightReps,
      holdSeconds: hold,
      volumeKg: volume,
    );
  }

  final double? weightKg;
  final double? oneRmKg;
  final int? bodyweightReps;
  final int? holdSeconds;
  final double? volumeKg;
}

/// The estimated one-rep max of a counted, loaded set, or null when there is
/// nothing to estimate (bodyweight, a hold, or a rep count no formula takes).
double? estimatedOneRmOf({required double weightKg, required int reps}) {
  if (weightKg <= 0 || reps <= 0) return null;
  return estimateOneRm(weight: weightKg, reps: reps)?.average;
}

/// A set's contribution to working volume — weight × reps, or the reps alone
/// for a bodyweight set, matching the progress screen's "best volume day".
double workingVolumeOf(LoggedSet set) =>
    set.weight > 0 ? set.weight * set.reps : set.reps.toDouble();

/// Floating-point dust allowance. 102.5 vs 102.50000000001 is not a record.
const _epsilon = 0.001;

/// The records a set about to be logged would break, against [before].
///
/// Volume is never returned here; it is a whole-session record.
List<BrokenRecord> recordsSetBy({
  required SetType type,
  required double weightKg,
  required int reps,
  required int? seconds,
  required RecordBaseline before,
}) {
  if (!type.countsTowardStrength) return const [];

  final broken = <BrokenRecord>[];
  void check(RecordKind kind, double? value, num? previous) {
    if (value == null || previous == null) return;
    if (value > previous + _epsilon) {
      broken.add(
        BrokenRecord(kind: kind, value: value, previous: previous.toDouble()),
      );
    }
  }

  if (seconds != null) {
    check(RecordKind.hold, seconds.toDouble(), before.holdSeconds);
  } else if (weightKg > 0) {
    check(RecordKind.weight, weightKg, before.weightKg);
    check(
      RecordKind.oneRm,
      estimatedOneRmOf(weightKg: weightKg, reps: reps),
      before.oneRmKg,
    );
  } else if (reps > 0) {
    check(RecordKind.reps, reps.toDouble(), before.bodyweightReps);
  }
  return broken;
}

/// The records a session set, per exercise, in the order the exercises were
/// first logged.
///
/// [sessionSets] are the session's own sets (every type — filtered here);
/// [earlierSets] are the sets of the same exercises from sessions before it.
List<ExerciseRecords> sessionRecordsFrom({
  required List<LoggedSet> sessionSets,
  required List<LoggedSet> earlierSets,
}) {
  final order = <String>[];
  final byExercise = <String, List<LoggedSet>>{};
  for (final set in sessionSets) {
    if (!byExercise.containsKey(set.exerciseId)) order.add(set.exerciseId);
    byExercise.putIfAbsent(set.exerciseId, () => []).add(set);
  }
  final earlierByExercise = <String, List<LoggedSet>>{};
  for (final set in earlierSets) {
    earlierByExercise.putIfAbsent(set.exerciseId, () => []).add(set);
  }

  final result = <ExerciseRecords>[];
  for (final exerciseId in order) {
    final broken = _beaten(
      RecordBaseline.of(byExercise[exerciseId]!),
      RecordBaseline.of(earlierByExercise[exerciseId] ?? const []),
    );
    if (broken.isNotEmpty) {
      result.add(ExerciseRecords(exerciseId: exerciseId, records: broken));
    }
  }
  return result;
}

/// Every best in [now] that beats the same best in [before].
List<BrokenRecord> _beaten(RecordBaseline now, RecordBaseline before) {
  final broken = <BrokenRecord>[];
  void check(RecordKind kind, num? value, num? previous) {
    if (value == null || previous == null) return;
    if (value > previous + _epsilon) {
      broken.add(
        BrokenRecord(
          kind: kind,
          value: value.toDouble(),
          previous: previous.toDouble(),
        ),
      );
    }
  }

  check(RecordKind.weight, now.weightKg, before.weightKg);
  check(RecordKind.oneRm, now.oneRmKg, before.oneRmKg);
  check(RecordKind.reps, now.bodyweightReps, before.bodyweightReps);
  check(RecordKind.hold, now.holdSeconds, before.holdSeconds);
  check(RecordKind.volume, now.volumeKg, before.volumeKg);
  return broken;
}

/// The higher of each best in [a] and [b] — the baseline of both their sets
/// together.
///
/// Exact for volume too, because that best is per *session* and a session's
/// sets never end up split between the two.
RecordBaseline _higher(RecordBaseline a, RecordBaseline b) {
  T? max<T extends num>(T? x, T? y) {
    if (x == null) return y;
    if (y == null) return x;
    return y > x ? y : x;
  }

  return RecordBaseline(
    weightKg: max(a.weightKg, b.weightKg),
    oneRmKg: max(a.oneRmKg, b.oneRmKg),
    bodyweightReps: max(a.bodyweightReps, b.bodyweightReps),
    holdSeconds: max(a.holdSeconds, b.holdSeconds),
    volumeKg: max(a.volumeKg, b.volumeKg),
  );
}

/// One finished workout's sets, for counting records across the whole log.
typedef RecordWorkout = ({
  int sessionId,
  DateTime startedAt,
  DateTime finishedAt,
  List<LoggedSet> sets,
});

/// How many records each workout in [workouts] set, by session id.
///
/// The same rules and the same count as the workout summary — every
/// [BrokenRecord] is one, so a heavier set that is also a better estimate is
/// two — which means a month's total is exactly what its summaries added up
/// to. "Earlier" is by start time with the id breaking ties, as there.
///
/// One pass with a running best per exercise rather than re-reading the
/// history for each workout, so a year of training costs one walk.
///
/// Only finished workouts are in the walk. The summary also measures against
/// a session left open from before, which is too rare a difference to cost a
/// second query over.
Map<int, int> recordCountsByWorkout(List<RecordWorkout> workouts) {
  final ordered = [...workouts]
    ..sort((a, b) {
      final byStart = a.startedAt.compareTo(b.startedAt);
      return byStart != 0 ? byStart : a.sessionId.compareTo(b.sessionId);
    });

  final best = <String, RecordBaseline>{};
  final counts = <int, int>{};
  for (final workout in ordered) {
    final byExercise = <String, List<LoggedSet>>{};
    for (final set in workout.sets) {
      byExercise.putIfAbsent(set.exerciseId, () => []).add(set);
    }
    var count = 0;
    for (final MapEntry(key: exerciseId, value: sets) in byExercise.entries) {
      final now = RecordBaseline.of(sets);
      final before = best[exerciseId] ?? const RecordBaseline();
      count += _beaten(now, before).length;
      best[exerciseId] = _higher(before, now);
    }
    if (count > 0) counts[workout.sessionId] = count;
  }
  return counts;
}

/// Reads the history personal records are measured against.
class PersonalRecordsRepository {
  PersonalRecordsRepository(this._db);

  final AppDatabase _db;

  /// The bests a new set of [exerciseId], logged in session [sessionId], has
  /// to beat.
  ///
  /// A kind of best exists only if some *other* session set it — "Never the
  /// first time" above. Your first ever bench session ramping 50, 55, 60 kg is
  /// not three records, and the summary, which compares only with earlier
  /// sessions, would list none of them.
  ///
  /// Once it exists, the bar also includes earlier sets of the workout in
  /// progress, so a second set at the same new top weight is not a second
  /// record.
  Future<RecordBaseline> baselineFor(
    String exerciseId, {
    required int sessionId,
  }) async {
    final query = _db.select(_db.loggedSets)
      ..where(
        (t) =>
            t.exerciseId.equals(exerciseId) &
            t.setType.isNotIn(strengthExcludedSetTypes),
      );
    final sets = await query.get();
    final before = RecordBaseline.of(
      sets.where((s) => s.sessionId != sessionId),
    );
    final today = RecordBaseline.of(
      sets.where((s) => s.sessionId == sessionId),
    );

    T? raised<T extends num>(T? earlier, T? sameSession) {
      if (earlier == null) return null;
      if (sameSession == null || sameSession <= earlier) return earlier;
      return sameSession;
    }

    return RecordBaseline(
      weightKg: raised(before.weightKg, today.weightKg),
      oneRmKg: raised(before.oneRmKg, today.oneRmKg),
      bodyweightReps: raised(before.bodyweightReps, today.bodyweightReps),
      holdSeconds: raised(before.holdSeconds, today.holdSeconds),
      volumeKg: before.volumeKg,
    );
  }

  /// The records session [sessionId] set.
  ///
  /// "Earlier" is by start time, with the id breaking ties, so a history
  /// imported after the fact still counts as coming before a workout logged
  /// today.
  Future<List<ExerciseRecords>> recordsForSession(int sessionId) async {
    final session = await (_db.select(
      _db.workoutSessions,
    )..where((t) => t.id.equals(sessionId))).getSingleOrNull();
    if (session == null) return const [];

    final sessionSets =
        await (_db.select(_db.loggedSets)
              ..where((t) => t.sessionId.equals(sessionId))
              ..orderBy([(t) => OrderingTerm(expression: t.id)]))
            .get();
    if (sessionSets.isEmpty) return const [];

    final exerciseIds = {for (final s in sessionSets) s.exerciseId};
    final earlierQuery =
        _db.select(_db.loggedSets).join([
          innerJoin(
            _db.workoutSessions,
            _db.workoutSessions.id.equalsExp(_db.loggedSets.sessionId),
          ),
        ])..where(
          _db.loggedSets.exerciseId.isIn(exerciseIds) &
              _db.loggedSets.setType.isNotIn(strengthExcludedSetTypes) &
              _db.workoutSessions.id.equals(sessionId).not() &
              (_db.workoutSessions.startedAt.isSmallerThanValue(
                    session.startedAt,
                  ) |
                  (_db.workoutSessions.startedAt.equals(session.startedAt) &
                      _db.workoutSessions.id.isSmallerThanValue(sessionId))),
        );
    final earlier = [
      for (final row in await earlierQuery.get()) row.readTable(_db.loggedSets),
    ];

    return sessionRecordsFrom(sessionSets: sessionSets, earlierSets: earlier);
  }

  /// How many records were set on each day, across the whole log — for the
  /// monthly and yearly reviews.
  ///
  /// A day is the day the workout finished, which is how the streak, the
  /// recap and the reviews date a workout. Working sets only, read once; see
  /// [recordCountsByWorkout] for the walk.
  Stream<Map<DateTime, int>> watchRecordsByDay() {
    final query = _db.select(_db.loggedSets).join([
      innerJoin(
        _db.workoutSessions,
        _db.workoutSessions.id.equalsExp(_db.loggedSets.sessionId) &
            _db.workoutSessions.completedAt.isNotNull(),
      ),
    ])..where(_db.loggedSets.setType.isNotIn(strengthExcludedSetTypes));

    return query.watch().map((rows) {
      final sessions = <int, WorkoutSession>{};
      final sets = <int, List<LoggedSet>>{};
      for (final row in rows) {
        final session = row.readTable(_db.workoutSessions);
        sessions[session.id] = session;
        sets
            .putIfAbsent(session.id, () => [])
            .add(row.readTable(_db.loggedSets));
      }
      final counts = recordCountsByWorkout([
        for (final session in sessions.values)
          (
            sessionId: session.id,
            startedAt: session.startedAt,
            finishedAt: session.completedAt!,
            sets: sets[session.id]!,
          ),
      ]);

      final byDay = <DateTime, int>{};
      counts.forEach((sessionId, count) {
        final finished = sessions[sessionId]!.completedAt!;
        final day = DateTime(finished.year, finished.month, finished.day);
        byDay[day] = (byDay[day] ?? 0) + count;
      });
      return byDay;
    });
  }
}

/// App-wide access to the [PersonalRecordsRepository].
@Riverpod(keepAlive: true)
PersonalRecordsRepository personalRecordsRepository(Ref ref) {
  return PersonalRecordsRepository(ref.watch(appDatabaseProvider));
}

/// The records a finished session set, for the workout summary.
///
/// Hand-written for the same reason as the session providers: its type holds
/// Drift's generated classes. A future rather than a stream — the summary is
/// of a finished workout, whose sets no longer change.
final sessionRecordsProvider =
    FutureProvider.family<List<ExerciseRecords>, int>((ref, sessionId) {
      return ref
          .watch(personalRecordsRepositoryProvider)
          .recordsForSession(sessionId);
    });

/// Records set per day across the whole log, for the reviews.
final recordsByDayProvider = StreamProvider<Map<DateTime, int>>((ref) {
  return ref.watch(personalRecordsRepositoryProvider).watchRecordsByDay();
});
