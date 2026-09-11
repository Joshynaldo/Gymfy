import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/data/activity_repository.dart';
import '../../home/data/recap_repository.dart';

/// Everything you have done, all time.
typedef TrainingTotals = ({
  /// Completed workouts. Unfinished sessions are excluded upstream, the same
  /// rule the streak and the recap use.
  int workouts,

  /// Distinct days trained — two sessions in one day count once, because that
  /// is what "days" means everywhere else in this app.
  int days,
  int sets,
  double volumeKg,
  int minutes,
});

/// Lifetime training totals, derived rather than stored.
///
/// Nothing here is a counter that gets incremented: every figure is recomputed
/// from the logged sets and completed sessions. A stored counter would be one
/// more thing to keep in step with a deleted workout, and it would drift
/// silently when it failed.
///
/// Both sources are already watched elsewhere on the app's hot paths, so this
/// adds no new database work — it reuses the recap's single indexed join and
/// the activity heatmap's per-day minutes.
final trainingTotalsProvider = Provider<TrainingTotals?>((ref) {
  final sets = ref.watch(recapSetsProvider).value;
  final minutes = ref.watch(activityMinutesProvider).value;
  if (sets == null || minutes == null) return null;

  final sessions = <int>{};
  final days = <DateTime>{};
  var volume = 0.0;
  for (final set in sets) {
    sessions.add(set.sessionId);
    days.add(DateTime(set.date.year, set.date.month, set.date.day));
    volume += set.weight * set.reps;
  }

  return (
    workouts: sessions.length,
    days: days.length,
    sets: sets.length,
    volumeKg: volume,
    // Summed from the same per-day map the year grid is drawn from, so the two
    // can never disagree about how long you have spent training.
    minutes: minutes.values.fold(0, (sum, m) => sum + m),
  );
});

/// A lifetime volume total is a number with no feel to it — 184,000 kg means
/// nothing on its own. These give it a shape.
///
/// Ordered heaviest last so the *largest* one that fits is the one shown: the
/// interesting comparison is always the biggest thing you have outlifted.
const volumeComparisons = <({String label, double kg})>[
  (label: 'a grand piano', kg: 400),
  (label: 'a small car', kg: 1200),
  (label: 'a rhino', kg: 2300),
  (label: 'a London bus', kg: 12000),
  (label: 'a humpback whale', kg: 30000),
  (label: 'a loaded 747', kg: 400000),
];

/// How many of the biggest comparable thing [volumeKg] adds up to.
///
/// Returns null below the smallest comparison rather than saying "0.4 grand
/// pianos", which is both meaningless and faintly discouraging on day one.
({String label, double times})? volumeComparison(double volumeKg) {
  ({String label, double kg})? best;
  for (final item in volumeComparisons) {
    if (volumeKg >= item.kg) best = item;
  }
  if (best == null) return null;
  return (label: best.label, times: volumeKg / best.kg);
}
