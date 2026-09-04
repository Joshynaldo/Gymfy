import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/lifter_sex.dart';
import '../../progress/data/measurements_repository.dart';

// The sex itself lives in shared/ — onboarding and the muscle map read it too.
// Re-exported so the rank code can keep asking one file for its inputs.
export '../../../shared/data/lifter_sex.dart'
    show LifterSex, lifterSexProvider, lifterSexSetting, parseLifterSex;

/// Everything a rank needs besides the lift itself. Either field being null is
/// the signal to show the setup prompt instead of a rank.
typedef RankInputs = ({
  LifterSex? sex,
  double? bodyweightKg,
  DateTime? measuredOn,
});

/// Combines the lifter's sex with their latest logged bodyweight.
///
/// Bodyweight comes from the measurements table rather than a separate copy —
/// one number, one source. Logging a new weigh-in re-ranks every lift with no
/// extra bookkeeping.
final rankInputsProvider = Provider<RankInputs>((ref) {
  final sex = ref.watch(lifterSexProvider).value;
  final bodyweight = ref.watch(latestBodyweightProvider);
  return (
    sex: sex,
    bodyweightKg: bodyweight?.value,
    measuredOn: bodyweight?.day,
  );
});
