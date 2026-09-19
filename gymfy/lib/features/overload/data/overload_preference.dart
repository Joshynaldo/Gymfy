import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/settings_repository.dart';

// Progressive overload is configured once for the whole app, not per exercise.
//
// It's a decision about how you train — whether to progress, by how much, and
// whether to deload — and asking it thirty times in a day builder was making a
// programme-level choice look like an exercise-level one. Asked during
// onboarding, changeable in Settings, and nowhere else.
//
// Stored in the key-value settings table rather than as columns, so none of
// this needed a migration of its own.

const overloadEnabledSetting = 'overload_enabled';
const overloadModeSetting = 'overload_mode';
const overloadFixedSetting = 'overload_fixed_kg';
const overloadPercentSetting = 'overload_percent';
const overloadDeloadSetting = 'overload_deload_weeks';

/// How the next step is worked out.
enum OverloadMode {
  /// Per-muscle defaults: 5 kg on legs, 2.5 on back and chest, 1.25 on arms and
  /// shoulders. Still the recommendation — it's the only mode that already
  /// knows a squat isn't a lateral raise.
  auto('Auto'),

  /// The same number of kilograms on everything.
  fixed('Fixed'),

  /// A share of whatever you're currently lifting, so the step scales with the
  /// lift instead of being generous on small ones and timid on big ones.
  percent('Percent');

  const OverloadMode(this.label);

  final String label;

  static OverloadMode parse(String? raw) => OverloadMode.values.firstWhere(
    (mode) => mode.name == raw,
    orElse: () => OverloadMode.auto,
  );
}

/// The fixed steps offered, in kilograms — the jumps a standard plate set can
/// actually make. 1.25 is there for dumbbells and gyms with micro plates.
const overloadFixedSteps = <double>[1.25, 2.5, 5, 10];

/// The percentages offered. Small on purpose: 5% of a 140 kg squat is 7 kg,
/// already an aggressive week-on-week jump.
const overloadPercentSteps = <double>[1, 2.5, 5, 7.5];

/// How many increases in a row can pass before a deload is suggested.
const overloadDeloadOptions = <int>[4, 6, 8];

/// Everything the app knows about how to progress.
class OverloadConfig {
  const OverloadConfig({
    required this.enabled,
    required this.mode,
    required this.fixedKg,
    required this.percent,
    required this.deloadWeeks,
  });

  final bool enabled;
  final OverloadMode mode;

  /// Used when [mode] is [OverloadMode.fixed].
  final double fixedKg;

  /// Used when [mode] is [OverloadMode.percent].
  final double percent;

  /// Null means never deload.
  final int? deloadWeeks;

  /// The percentage to apply, or null when this isn't percentage mode.
  double? get percentOrNull => mode == OverloadMode.percent ? percent : null;

  /// The fixed step to apply, or null to fall back to the per-muscle default.
  double? get fixedOrNull => mode == OverloadMode.fixed ? fixedKg : null;

  OverloadConfig copyWith({
    bool? enabled,
    OverloadMode? mode,
    double? fixedKg,
    double? percent,
    int? deloadWeeks,
    bool clearDeload = false,
  }) {
    return OverloadConfig(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      fixedKg: fixedKg ?? this.fixedKg,
      percent: percent ?? this.percent,
      // A nullable field can't be cleared by passing null — that's
      // indistinguishable from "leave it alone" — so clearing is explicit.
      deloadWeeks: clearDeload ? null : (deloadWeeks ?? this.deloadWeeks),
    );
  }

  // Compared by value, because `overloadConfigProvider` rebuilds this object
  // whenever any of the five settings streams emits — which every one of them
  // does at least once on startup. Without value equality each of those
  // rebuilds is a *different* config as far as Riverpod is concerned, so every
  // visible overload suggestion re-runs its database join several times before
  // the screen has settled. Nothing looks wrong; it is just work, on the
  // hardware least able to spare it, and it widens the window in which a
  // suggestion has not arrived yet.
  @override
  bool operator ==(Object other) =>
      other is OverloadConfig &&
      other.enabled == enabled &&
      other.mode == mode &&
      other.fixedKg == fixedKg &&
      other.percent == percent &&
      other.deloadWeeks == deloadWeeks;

  @override
  int get hashCode => Object.hash(enabled, mode, fixedKg, percent, deloadWeeks);
}

/// What a fresh install gets.
///
/// On by default: onboarding offers it already switched on, so a user who taps
/// straight through gets suggestions, and an install that never saw that page
/// behaves the same as a new one.
const defaultOverloadConfig = OverloadConfig(
  enabled: true,
  mode: OverloadMode.auto,
  fixedKg: 2.5,
  percent: 2.5,
  deloadWeeks: null,
);

/// Parses the enabled flag.
///
/// Only the exact string we write counts as off. Anything else is a value we
/// didn't write, and silently disabling a feature because of junk in a settings
/// row is a horrible thing to debug.
bool parseOverloadEnabled(String? raw) => raw != 'false';

/// The whole configuration, from the settings table.
final overloadConfigProvider = Provider<OverloadConfig>((ref) {
  String? raw(String key) => ref.watch(rawSettingProvider(key)).value;

  final storedDeload = int.tryParse(raw(overloadDeloadSetting) ?? '');

  return OverloadConfig(
    enabled: parseOverloadEnabled(raw(overloadEnabledSetting)),
    mode: OverloadMode.parse(raw(overloadModeSetting)),
    fixedKg:
        double.tryParse(raw(overloadFixedSetting) ?? '') ??
        defaultOverloadConfig.fixedKg,
    percent:
        double.tryParse(raw(overloadPercentSetting) ?? '') ??
        defaultOverloadConfig.percent,
    // Only a value we offer: a number from some other build shouldn't put a
    // deload schedule on screen that the picker can't show.
    deloadWeeks: overloadDeloadOptions.contains(storedDeload)
        ? storedDeload
        : null,
  );
});

/// Whether suggestions are switched on. Read by everything that only needs the
/// yes/no.
final overloadEnabledProvider = Provider<bool>((ref) {
  return ref.watch(overloadConfigProvider).enabled;
});

/// Writes the whole configuration.
///
/// Every key every time, including the deload's absence: writing only what
/// changed would leave a stale value behind whenever a mode was switched away
/// from and back.
Future<void> setOverloadConfig(WidgetRef ref, OverloadConfig config) async {
  final settings = ref.read(settingsRepositoryProvider);
  await settings.write(overloadEnabledSetting, config.enabled.toString());
  await settings.write(overloadModeSetting, config.mode.name);
  await settings.write(overloadFixedSetting, config.fixedKg.toString());
  await settings.write(overloadPercentSetting, config.percent.toString());
  if (config.deloadWeeks == null) {
    await settings.clear(overloadDeloadSetting);
  } else {
    await settings.write(overloadDeloadSetting, config.deloadWeeks.toString());
  }
}
