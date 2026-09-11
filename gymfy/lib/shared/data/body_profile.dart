import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/units.dart';
import 'settings_repository.dart';

/// Height, in centimetres.
const heightCmSetting = 'height_cm';

/// The year the user was born.
const birthYearSetting = 'birth_year';

/// The range the height picker offers.
///
/// Wide enough to cover adults and teenagers without offering a scroll through
/// two metres of values nobody is.
const minHeightCm = 120;
const maxHeightCm = 230;

/// The ages the picker offers.
const minAge = 13;
const maxAge = 100;

/// Height in centimetres, or null until it is given.
final heightCmProvider = StreamProvider<int?>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchRaw(heightCmSetting)
      .map(
        (raw) => _inRange(int.tryParse(raw ?? ''), minHeightCm, maxHeightCm),
      );
});

/// The stored year of birth, or null until it is given.
///
/// Stored as a *year*, never as an age. An age written down as "31" is wrong on
/// the next birthday and nothing in the app would ever notice; a year of birth
/// stays true and the age is derived from it whenever it is needed.
final birthYearProvider = StreamProvider<int?>((ref) {
  return ref.watch(settingsRepositoryProvider).watchRaw(birthYearSetting).map((
    raw,
  ) {
    final now = DateTime.now().year;
    return _inRange(int.tryParse(raw ?? ''), now - maxAge, now - minAge);
  });
});

/// The user's age, derived from [birthYearProvider].
final ageProvider = Provider<int?>((ref) {
  final year = ref.watch(birthYearProvider).value;
  return year == null ? null : DateTime.now().year - year;
});

/// The year someone [age] years old was born.
int birthYearForAge(int age, {DateTime? now}) =>
    (now ?? DateTime.now()).year - age;

/// Only a value the pickers could have produced.
///
/// A stored figure from a hand-edited database or a future build shouldn't put
/// a nonsense height on screen; out of range reads as "not set", which every
/// caller already handles.
int? _inRange(int? value, int min, int max) {
  if (value == null) return null;
  return value >= min && value <= max ? value : null;
}

/// Height as the user should read it.
///
/// Follows the weight unit rather than adding a second preference: someone who
/// thinks in pounds thinks in feet and inches, and asking them twice would be
/// two ways to say the same thing.
String formatHeight(int cm, WeightUnit unit) {
  if (unit == WeightUnit.kg) return '$cm cm';
  final totalInches = (cm / 2.54).round();
  return '${totalInches ~/ 12}′ ${totalInches % 12}″';
}
