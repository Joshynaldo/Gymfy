// Rolling logged sets up into a week / month / year recap.
//
// Everything here is pure: it takes a flat list of logged sets and returns the
// numbers the Home tab charts. The database query lives in recap_repository.dart
// so this file can be tested without one, which matters because the bucket
// boundaries and the personal-record walk are where the bugs would hide.
//
// Volumes are kilograms, like everything stored; the UI converts for display.

import '../../../shared/utils/dates.dart';

/// One logged set, flattened with everything the recap needs.
typedef RecapSet = ({
  DateTime date,
  int sessionId,
  String exerciseId,
  double weight,
  int reps,
  List<String> muscleIds,
});

/// How far back a recap looks, and at what resolution.
///
/// The resolution matters as much as the range: a year of daily bars is 365
/// slivers nobody can read, and a week of monthly bars is one bar.
enum RecapPeriod {
  week('Week', 7, RecapGrain.day),
  month('Month', 5, RecapGrain.week),
  year('Year', 12, RecapGrain.month);

  const RecapPeriod(this.label, this.buckets, this.grain);

  final String label;

  /// How many buckets the chart shows.
  final int buckets;

  final RecapGrain grain;
}

/// The width of one bucket.
enum RecapGrain { day, week, month }

/// One bar's worth of recap.
class RecapBucket {
  const RecapBucket({
    required this.start,
    required this.label,
    required this.volumeKg,
    required this.sessions,
  });

  /// Midnight at the start of the bucket.
  final DateTime start;

  /// The short label under the bar.
  final String label;

  final double volumeKg;

  /// Distinct workouts in this bucket, not sets.
  final int sessions;
}

/// Everything the recap section shows for one period.
class RecapSummary {
  const RecapSummary({
    required this.period,
    required this.buckets,
    required this.totalVolumeKg,
    required this.sessions,
    required this.muscleSets,
    required this.personalRecords,
  });

  final RecapPeriod period;
  final List<RecapBucket> buckets;
  final double totalVolumeKg;

  /// Distinct workouts across the whole period.
  final int sessions;

  /// Sets per muscle id, for "what did I train".
  ///
  /// Sets rather than volume, deliberately. A set of squats moves five times
  /// the weight of a set of curls, so ranking muscles by kilograms would put
  /// legs on top of every chart no matter how the week actually went — it would
  /// be measuring load, not attention. Counting sets asks the question people
  /// mean: how much work did each muscle get?
  final Map<String, int> muscleSets;

  /// How many personal records were set inside the period.
  final int personalRecords;

  bool get isEmpty => sessions == 0;
}

/// The work one set represents.
///
/// Bodyweight sets are logged at zero weight, so counting `weight × reps` would
/// score every pull-up as nothing. Falling back to reps keeps them visible in
/// the totals — the same rule the muscle map already uses, kept identical so
/// two screens can't disagree about what a set was worth.
double setVolume(double weight, int reps) =>
    weight > 0 ? weight * reps : reps.toDouble();

/// The bucket boundaries for [period], oldest first, ending at [today].
List<DateTime> bucketStarts(RecapPeriod period, DateTime today) {
  final end = dateOnly(today);
  return switch (period.grain) {
    RecapGrain.day => [
      for (var i = period.buckets - 1; i >= 0; i--)
        DateTime(end.year, end.month, end.day - i),
    ],
    // Weeks are counted back from today rather than snapped to Mondays: the
    // last bar should always mean "the last seven days", not "a Monday-to-now
    // stub" that looks like a collapse in volume every Monday morning.
    RecapGrain.week => [
      for (var i = period.buckets - 1; i >= 0; i--)
        DateTime(end.year, end.month, end.day - (i * 7) - 6),
    ],
    RecapGrain.month => [
      for (var i = period.buckets - 1; i >= 0; i--)
        DateTime(end.year, end.month - i, 1),
    ],
  };
}

/// The short label under a bucket.
String bucketLabel(DateTime start, RecapGrain grain) {
  const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  const months = [
    'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D',
  ];
  return switch (grain) {
    RecapGrain.day => weekdays[start.weekday - 1],
    // Day-of-month: a week bar is identified by when it started, and "12"
    // is readable where "12 Aug" would collide with its neighbours.
    RecapGrain.week => '${start.day}',
    RecapGrain.month => months[start.month - 1],
  };
}

/// Which bucket a date falls in, or -1 if it's outside the period.
int bucketIndexFor(DateTime date, List<DateTime> starts, RecapGrain grain) {
  final day = dateOnly(date);
  if (day.isBefore(starts.first)) return -1;

  for (var i = starts.length - 1; i >= 0; i--) {
    if (!day.isBefore(starts[i])) {
      // Months are the only grain where a date can sit past the last bucket's
      // start and still belong to it, so no upper bound check is needed —
      // every start is in the past and the last one runs to today.
      return i;
    }
  }
  return -1;
}

/// Counts personal records per date.
///
/// A PR is a set heavier than anything previously logged for that exercise.
/// The walk has to cover ALL history, not just the period: whether today's
/// 100 kg bench is a record depends on every bench before it. The first ever
/// set of an exercise doesn't count — otherwise trying a new machine would
/// read as a personal best.
Map<DateTime, int> personalRecordDates(List<RecapSet> allSets) {
  final sorted = [...allSets]..sort((a, b) => a.date.compareTo(b.date));
  final best = <String, double>{};
  final records = <DateTime, int>{};

  for (final set in sorted) {
    if (set.weight <= 0) continue; // Bodyweight work has no weight to beat.
    final previous = best[set.exerciseId];
    if (previous != null && set.weight > previous) {
      final day = dateOnly(set.date);
      records[day] = (records[day] ?? 0) + 1;
    }
    if (previous == null || set.weight > previous) {
      best[set.exerciseId] = set.weight;
    }
  }
  return records;
}

/// Builds the recap for [period] from every logged set.
///
/// [allSets] is the complete history, not just the period — personal records
/// can't be judged from a window.
RecapSummary summariseRecap({
  required RecapPeriod period,
  required DateTime today,
  required List<RecapSet> allSets,
}) {
  final starts = bucketStarts(period, today);
  final volumes = List<double>.filled(starts.length, 0);
  final sessionsPerBucket = List.generate(starts.length, (_) => <int>{});
  final muscleSets = <String, int>{};
  final allSessions = <int>{};
  var totalVolume = 0.0;

  for (final set in allSets) {
    final index = bucketIndexFor(set.date, starts, period.grain);
    if (index < 0) continue;

    final volume = setVolume(set.weight, set.reps);
    volumes[index] += volume;
    sessionsPerBucket[index].add(set.sessionId);
    allSessions.add(set.sessionId);
    totalVolume += volume;

    // The set counts once for every muscle it trains. Splitting it between
    // them would need a per-muscle contribution the app doesn't know, and a
    // bench press really does work all three of chest, front delt and triceps.
    for (final muscleId in set.muscleIds) {
      muscleSets[muscleId] = (muscleSets[muscleId] ?? 0) + 1;
    }
  }

  final records = personalRecordDates(allSets);
  var recordCount = 0;
  records.forEach((day, count) {
    if (bucketIndexFor(day, starts, period.grain) >= 0) recordCount += count;
  });

  return RecapSummary(
    period: period,
    buckets: [
      for (var i = 0; i < starts.length; i++)
        RecapBucket(
          start: starts[i],
          label: bucketLabel(starts[i], period.grain),
          volumeKg: volumes[i],
          sessions: sessionsPerBucket[i].length,
        ),
    ],
    totalVolumeKg: totalVolume,
    sessions: allSessions.length,
    muscleSets: muscleSets,
    personalRecords: recordCount,
  );
}
