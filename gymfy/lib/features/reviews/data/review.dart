// A month or a year of training, summed up — and the one before it, to
// compare against.
//
// Pure, like the recap it builds on: the inputs are the streams the app
// already keeps open (the recap's sets, the heatmap's per-day minutes, the
// per-day record counts), and nothing here queries anything. The rules are
// the existing ones, reused rather than restated:
//
// - A **workout** is a completed session with something logged in it, dated
//   by when it finished — the recap's and the training totals' rule.
// - **Volume** is `setVolume`, every set type included: a warm-up is work you
//   did, it is just not evidence of strength.
// - **Time** is known minutes only. A session whose length was never
//   recorded counts as a workout and adds nothing to the clock
//   (`trainingByDay`, `sessionLength`).
// - **Records** are the workout summary's, counted the same way, so a month
//   adds up to what its summaries said (`recordCountsByWorkout`).
// - **Days and streaks** count any completed session, like the streak card
//   and the year grid.
//
// Free workouts — sessions started from no plan — are ordinary sessions in
// every one of those sources, so they count everywhere without a special
// case.

import '../../../shared/utils/dates.dart';
import '../../../shared/utils/format.dart';
import '../../home/data/activity_repository.dart' show DayTraining;
import '../../home/data/recap.dart' show RecapSet, setVolume;

/// How long a review looks back over.
enum ReviewSpan { month, year }

/// One calendar month or year.
class ReviewPeriod {
  ReviewPeriod.month(int year, int month)
    : span = ReviewSpan.month,
      start = DateTime(year, month);

  ReviewPeriod.year(int year) : span = ReviewSpan.year, start = DateTime(year);

  /// The period of [span] that [day] falls in.
  factory ReviewPeriod.containing(ReviewSpan span, DateTime day) =>
      switch (span) {
        ReviewSpan.month => ReviewPeriod.month(day.year, day.month),
        ReviewSpan.year => ReviewPeriod.year(day.year),
      };

  final ReviewSpan span;

  /// Midnight on the first day.
  final DateTime start;

  /// Midnight on the first day *after* it.
  DateTime get end => switch (span) {
    ReviewSpan.month => DateTime(start.year, start.month + 1),
    ReviewSpan.year => DateTime(start.year + 1),
  };

  ReviewPeriod get previous => switch (span) {
    ReviewSpan.month => ReviewPeriod.month(start.year, start.month - 1),
    ReviewSpan.year => ReviewPeriod.year(start.year - 1),
  };

  ReviewPeriod get next => switch (span) {
    ReviewSpan.month => ReviewPeriod.month(start.year, start.month + 1),
    ReviewSpan.year => ReviewPeriod.year(start.year + 1),
  };

  bool contains(DateTime moment) =>
      !moment.isBefore(start) && moment.isBefore(end);

  /// Whether [today] is inside it — the review of a period still running.
  bool isCurrent(DateTime today) => contains(today);

  /// "September 2026" or "2026".
  String get label => switch (span) {
    ReviewSpan.month => formatMonthYear(start),
    ReviewSpan.year => '${start.year}',
  };

  /// "September" or "2026" — enough to say what a comparison is against.
  String get shortLabel => switch (span) {
    ReviewSpan.month => formatMonthName(start),
    ReviewSpan.year => '${start.year}',
  };

  @override
  bool operator ==(Object other) =>
      other is ReviewPeriod && other.span == span && other.start == start;

  @override
  int get hashCode => Object.hash(span, start);

  @override
  String toString() => 'ReviewPeriod($label)';
}

/// One exercise's share of a period.
class ReviewExercise {
  const ReviewExercise({
    required this.exerciseId,
    required this.sets,
    required this.volumeKg,
    required this.workouts,
  });

  final String exerciseId;
  final int sets;
  final double volumeKg;

  /// Workouts it appeared in.
  final int workouts;
}

/// What one period adds up to.
class ReviewStats {
  const ReviewStats({
    required this.workouts,
    required this.sets,
    required this.volumeKg,
    required this.minutes,
    required this.untimedWorkouts,
    required this.activeDays,
    required this.longestStreak,
    required this.records,
    required this.topExercises,
    required this.muscleSets,
  });

  final int workouts;
  final int sets;
  final double volumeKg;

  /// Known minutes only.
  final int minutes;

  /// Sessions whose length was never recorded — counted, not timed.
  final int untimedWorkouts;

  /// Distinct days trained.
  final int activeDays;

  /// Longest run of consecutive days trained inside the period.
  final int longestStreak;

  /// Personal records set.
  final int records;

  /// Most sets first, ties by volume then id. Every exercise trained.
  final List<ReviewExercise> topExercises;

  /// Sets per muscle, most first, ties by id. Sets rather than volume, for the
  /// reason the recap gives: kilograms would put legs on top of every chart.
  final List<MapEntry<String, int>> muscleSets;

  bool get isEmpty => workouts == 0;
}

/// A period, and the one before it.
class TrainingReview {
  const TrainingReview({
    required this.period,
    required this.current,
    required this.previous,
  });

  final ReviewPeriod period;
  final ReviewStats current;
  final ReviewStats previous;
}

/// Sums up [period] and the period before it.
///
/// [allSets] is every set from a completed session (the recap's stream),
/// [trainingDays] the per-day minutes over the whole log, and [recordsByDay]
/// the records set per day.
TrainingReview buildReview({
  required ReviewPeriod period,
  required List<RecapSet> allSets,
  required Map<DateTime, DayTraining> trainingDays,
  required Map<DateTime, int> recordsByDay,
}) {
  ReviewStats statsFor(ReviewPeriod p) => reviewStats(
    period: p,
    allSets: allSets,
    trainingDays: trainingDays,
    recordsByDay: recordsByDay,
  );

  return TrainingReview(
    period: period,
    current: statsFor(period),
    previous: statsFor(period.previous),
  );
}

/// What [period] adds up to. See [buildReview] for the inputs.
ReviewStats reviewStats({
  required ReviewPeriod period,
  required List<RecapSet> allSets,
  required Map<DateTime, DayTraining> trainingDays,
  required Map<DateTime, int> recordsByDay,
}) {
  final sessions = <int>{};
  var sets = 0;
  var volume = 0.0;
  final exerciseSets = <String, int>{};
  final exerciseVolume = <String, double>{};
  final exerciseSessions = <String, Set<int>>{};
  final muscles = <String, int>{};

  for (final set in allSets) {
    if (!period.contains(set.date)) continue;
    final work = setVolume(set.weight, set.reps);
    sessions.add(set.sessionId);
    sets++;
    volume += work;
    exerciseSets[set.exerciseId] = (exerciseSets[set.exerciseId] ?? 0) + 1;
    exerciseVolume[set.exerciseId] =
        (exerciseVolume[set.exerciseId] ?? 0) + work;
    exerciseSessions.putIfAbsent(set.exerciseId, () => {}).add(set.sessionId);
    // Once per muscle it trains, like the recap's muscle card.
    for (final muscle in set.muscleIds) {
      muscles[muscle] = (muscles[muscle] ?? 0) + 1;
    }
  }

  var minutes = 0;
  var untimed = 0;
  final days = <DateTime>{};
  trainingDays.forEach((day, training) {
    if (!period.contains(day)) return;
    minutes += training.minutes;
    untimed += training.untimed;
    days.add(dateOnly(day));
  });

  var records = 0;
  recordsByDay.forEach((day, count) {
    if (period.contains(day)) records += count;
  });

  final exercises =
      [
        for (final id in exerciseSets.keys)
          ReviewExercise(
            exerciseId: id,
            sets: exerciseSets[id]!,
            volumeKg: exerciseVolume[id]!,
            workouts: exerciseSessions[id]!.length,
          ),
      ]..sort((a, b) {
        final bySets = b.sets.compareTo(a.sets);
        if (bySets != 0) return bySets;
        final byVolume = b.volumeKg.compareTo(a.volumeKg);
        return byVolume != 0 ? byVolume : a.exerciseId.compareTo(b.exerciseId);
      });

  final muscleSets = muscles.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });

  return ReviewStats(
    workouts: sessions.length,
    sets: sets,
    volumeKg: volume,
    minutes: minutes,
    untimedWorkouts: untimed,
    activeDays: days.length,
    longestStreak: longestStreak(days),
    records: records,
    topExercises: exercises,
    muscleSets: muscleSets,
  );
}

/// The period a review opens on: the one [today] is in, unless nothing has
/// been finished in it yet — then the one before.
///
/// On the first of the month the current month is empty, and the review
/// anyone opening it then wants is the month that just ended.
ReviewPeriod defaultReviewPeriod(
  ReviewSpan span,
  DateTime today,
  List<RecapSet> allSets,
) {
  final current = ReviewPeriod.containing(span, today);
  final anything = allSets.any((set) => current.contains(set.date));
  return anything ? current : current.previous;
}

/// A change between two periods, as a short signed figure: "+3", "−1", or
/// null when there is no change worth printing.
///
/// A real minus sign rather than a hyphen, for the reason the rep-range dash
/// is an en dash: at small sizes a hyphen reads as punctuation.
String? signedDelta(num now, num before, {String Function(num)? format}) {
  final diff = now - before;
  if (diff == 0) return null;
  final text = format == null ? '${diff.abs()}' : format(diff.abs());
  return diff > 0 ? '+$text' : '−$text';
}
