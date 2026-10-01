import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/data/activity_repository.dart';
import '../../home/data/recap_repository.dart';
import '../../workout/data/personal_records.dart';
import 'review.dart';

/// The review of one period, against the one before. Null while any of its
/// three sources is still loading.
///
/// No query of its own: the recap's sets, the per-day minutes and the per-day
/// record counts are streams the app already has, and this only re-adds them
/// over a different window.
final reviewProvider = Provider.family<TrainingReview?, ReviewPeriod>((
  ref,
  period,
) {
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
