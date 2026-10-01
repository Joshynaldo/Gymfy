import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/settings_repository.dart';

// How a set is logged, beyond its weight and reps.
//
// Both settings live in the key-value table, so neither needed a migration
// (see FEATURE_PLAN.md, "Settings keys").

/// Setting key: whether the log sheet asks how hard a set was, and how.
const effortRatingModeSetting = 'effort_rating_mode';

/// Setting key: the warm-up calculator's ramp, as percentages of the working
/// weight — `40,60,80`.
const warmupRampSetting = 'warmup_ramp_percents';

/// How effort is rated in the log sheet, if at all.
///
/// Off by default. Most people never rate a set, and a row of chips on every
/// set you log is a cost paid forty times a session by someone who never asked
/// for it.
enum EffortRatingMode {
  off('Off'),

  /// Rate of perceived exertion, 6–10 in half steps.
  rpe('RPE'),

  /// Reps in reserve — how many more you could have done.
  rir('RIR');

  const EffortRatingMode(this.label);

  final String label;

  /// Reads a stored value. Anything unrecognised is [off]: a feature that
  /// adds controls should never switch itself on because of junk in a row.
  static EffortRatingMode parse(String? raw) =>
      EffortRatingMode.values.firstWhere(
        (mode) => mode.name == raw,
        orElse: () => EffortRatingMode.off,
      );
}

/// The RPE values the sheet offers.
///
/// Six and up only. Below six an RPE says "this was easy", which is what a
/// warm-up is for — and nine chips already fill the width of a phone.
const rpeOptions = <double>[6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5, 10];

/// The RIR values the sheet offers. Five reads as "five or more": past that
/// nobody can tell, and the overload maths only cares about the bottom end.
const rirOptions = <int>[0, 1, 2, 3, 4, 5];

/// The ramp a fresh install gets: three steps, the shape most coaches draw.
const defaultWarmupRamp = <int>[40, 60, 80];

/// The ramps offered in Settings. Fixed presets rather than free text: a ramp
/// is a handful of numbers and four sensible shapes cover nearly everyone.
const warmupRampPresets = <List<int>>[
  [40, 60, 80],
  [50, 70, 90],
  [40, 55, 70, 85],
  [30, 50, 70, 85],
];

/// Parses a stored ramp ("40,60,80") into ascending, distinct percentages.
///
/// Only values strictly between 0 and 100 count — a 0 % step is the empty bar,
/// which the calculator adds on its own, and 100 % is the working set itself.
/// Anything unreadable falls back to [defaultWarmupRamp] rather than leaving
/// the calculator with nothing to suggest.
List<int> parseWarmupRamp(String? raw) {
  if (raw == null || raw.trim().isEmpty) return defaultWarmupRamp;
  final parsed =
      raw
          .split(',')
          .map((part) => int.tryParse(part.trim()))
          .whereType<int>()
          .where((value) => value > 0 && value < 100)
          .toSet()
          .toList()
        ..sort();
  return parsed.isEmpty ? defaultWarmupRamp : parsed;
}

/// Serialises a ramp for storage.
String encodeWarmupRamp(List<int> percents) => percents.join(',');

/// How a ramp reads on screen: `40 · 60 · 80 %`.
String formatWarmupRamp(List<int> percents) => '${percents.join(' · ')} %';

// Both are streams rather than plain values derived from one, on purpose.
// They are read at the moment of use — a tap on "Log set", the calculator
// opening — often by a screen that never watched them. A plain provider read
// then answers with the *default* before the settings row has loaded, so the
// first set of a session would open without the rating you switched on. A
// stream can be awaited (`.future`) until the row is actually in.

/// The current effort-rating mode.
final effortRatingModeProvider = StreamProvider<EffortRatingMode>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchRaw(effortRatingModeSetting)
      .map(EffortRatingMode.parse);
});

/// The current warm-up ramp.
final warmupRampProvider = StreamProvider<List<int>>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchRaw(warmupRampSetting)
      .map(parseWarmupRamp);
});

/// Writes the effort-rating mode.
Future<void> setEffortRatingMode(WidgetRef ref, EffortRatingMode mode) {
  return ref
      .read(settingsRepositoryProvider)
      .write(effortRatingModeSetting, mode.name);
}

/// Writes the warm-up ramp.
Future<void> setWarmupRamp(WidgetRef ref, List<int> percents) {
  return ref
      .read(settingsRepositoryProvider)
      .write(warmupRampSetting, encodeWarmupRamp(percents));
}
