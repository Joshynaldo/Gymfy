import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_repository.dart';

/// Which set of reference data applies to this lifter.
///
/// Lives in `shared/` rather than under one feature because three now read it:
/// onboarding asks for it, strength rank picks a standards table with it, and
/// the muscle map picks a body diagram with it. It started in the calculator
/// feature, which made the body diagram depend on strength-standards data it
/// has nothing to do with.
enum LifterSex {
  male('Male'),
  female('Female');

  const LifterSex(this.label);

  final String label;
}

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
/// Strength standards differ substantially by sex, and so does the body
/// diagram, so there is no honest default — the app asks during onboarding
/// rather than guessing. Existing installs that predate the question read null
/// until the user answers it in Settings.
final lifterSexProvider = StreamProvider<LifterSex?>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchRaw(lifterSexSetting)
      .map(parseLifterSex);
});
