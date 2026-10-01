import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/data/activity_repository.dart';
import '../../home/data/recap_repository.dart';
import '../../workout/data/personal_records.dart';
import 'review.dart';

/// The review of one period, against the one before. Null while any of its
/// three sources is still loading.
///
/// No query of its own: it re-adds the recap's sets, the heatmap's per-day
/// minutes (over the whole log rather than the grid's year) and the workout
/// summary's records, counted per day, over a calendar window. Auto-disposed
/// with the two whole-log streams, so closing the review stops them
/// recounting on every logged set.
final reviewProvider = Provider.autoDispose
    .family<TrainingReview?, ReviewPeriod>((ref, period) {
      final sets = ref.watch(recapSetsProvider).value;
      final days = ref.watch(allTrainingByDayProvider).value;
      final records = ref.watch(recordsByDayProvider).value;
      if (sets == null || days == null || records == null) return null;
      return buildReview(
        period: period,
        allSets: sets,
        trainingDays: days,
        recordsByDay: records,
      );
    });
