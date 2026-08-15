import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/settings_repository.dart';
import '../../progress/data/measurements_repository.dart';
import 'strength_standards.dart';

/// The settings key holding the lifter's sex.
const lifterSexSetting = 'lifter_sex';

/// Parses a stored setting value back into a [LifterSex].
///
/// Anything unrecognised (a hand-edited database, a value written by a future
/// version) reads as "not set", which the UI already knows how to handle.
LifterSex? parseLifterSex(String? raw) {
  for (final sex in LifterSex.values) {
    if (sex.name == raw) return sex;
  }
  return null;
}

/// The lifter's sex, or null until they've told us.
///
/// Needed because strength standards differ substantially by sex — see
/// [strengthStandards]. There's no sensible default to fall back on, so the
/// rank UI asks rather than assumes.
final lifterSexProvider = StreamProvider<LifterSex?>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchRaw(lifterSexSetting)
      .map(parseLifterSex);
});

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
