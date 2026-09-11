// Weight units.
//
// Every weight in the database is stored in kilograms, always, regardless of
// what the user has chosen to see. Pounds exist only at the edges: converted on
// the way out for display, and back to kilograms on the way in from a text
// field. Nothing is ever rewritten when the setting changes.
//
// That's the whole design, and it's worth stating plainly because the tempting
// alternative — storing whatever unit was active at the time — makes every
// historical row ambiguous and every chart unplottable.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repository.dart';
import 'format.dart';

/// Setting key holding the user's chosen unit.
const weightUnitSetting = 'weight_unit';

/// Exact by definition: one pound is 0.45359237 kg.
const _kgPerLb = 0.45359237;

/// A unit the user can choose to see weights in.
enum WeightUnit {
  kg('kg', 0.5),
  lbs('lbs', 1);

  const WeightUnit(this.label, this.increment);

  /// Short label shown after a number, e.g. "kg".
  final String label;

  /// The smallest step worth showing in this unit.
  ///
  /// Half a kilo is a pair of 0.25 kg micro plates; a pound is the closest
  /// equivalent jump on a pound-plate barbell. Used when rounding an estimate
  /// to something you could actually load.
  final double increment;

  /// Parses a stored value, falling back to kilograms.
  ///
  /// An unreadable setting means showing kilograms, never failing to render a
  /// weight — the worst case is the user setting their preference again.
  static WeightUnit parse(String? raw) {
    return WeightUnit.values.firstWhere(
      (unit) => unit.name == raw,
      orElse: () => WeightUnit.kg,
    );
  }
}

/// Converts a stored weight in kilograms to [unit] for display.
double weightIn(double kilograms, WeightUnit unit) {
  return switch (unit) {
    WeightUnit.kg => kilograms,
    WeightUnit.lbs => kilograms / _kgPerLb,
  };
}

/// Converts a weight the user typed in [unit] back to kilograms for storage.
double weightToKilograms(double value, WeightUnit unit) {
  return switch (unit) {
    WeightUnit.kg => value,
    WeightUnit.lbs => value * _kgPerLb,
  };
}

/// Rounds a weight to the nearest step loadable in [unit].
///
/// Takes and returns kilograms, but rounds in the *display* unit — rounding to
/// half a kilo and then converting would land on values like 137.8 lbs, which
/// is not a weight anyone can put on a bar.
double roundToLoadable(double kilograms, WeightUnit unit) {
  final display = weightIn(kilograms, unit);
  final step = unit.increment;
  final rounded = (display / step).round() * step;
  return weightToKilograms(rounded, unit);
}

/// Formats a stored weight in [unit], without the unit label — for places that
/// show the label separately, like a text field suffix or a chart axis.
String formatWeightIn(double kilograms, WeightUnit unit) {
  return formatWeight(weightIn(kilograms, unit));
}

/// Formats a stored weight with its unit, e.g. "62.5 kg" or "138 lbs".
///
/// The one function nearly every screen wants. Rounds to something loadable
/// first, so a converted weight reads like a weight rather than trailing five
/// decimal places of conversion error.
String formatWeightUnit(double kilograms, WeightUnit unit) {
  return '${formatWeightIn(roundToLoadable(kilograms, unit), unit)} '
      '${unit.label}';
}

/// Parses a user-typed weight in [unit] and returns it in kilograms.
///
/// Returns null for anything that isn't a positive number, so callers can show
/// a validation message rather than storing nonsense. Accepts a comma as the
/// decimal separator, as [parseWeight] does.
double? parseWeightAsKilograms(String text, WeightUnit unit) {
  final value = parseWeight(text);
  if (value == null) return null;
  return weightToKilograms(value, unit);
}

/// The stored unit preference, or null while loading / if never set.
final storedWeightUnitProvider = StreamProvider<WeightUnit?>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchRaw(weightUnitSetting)
      .map((raw) => raw == null ? null : WeightUnit.parse(raw));
});

/// The unit to show weights in.
///
/// A plain provider rather than a stream so the twenty-odd screens that display
/// a weight can read it synchronously, and so "still loading" resolves to
/// kilograms in exactly one place instead of at every call site.
final weightUnitProvider = Provider<WeightUnit>((ref) {
  return ref.watch(storedWeightUnitProvider).value ?? WeightUnit.kg;
});

/// Stores the user's choice.
Future<void> setWeightUnit(WidgetRef ref, WeightUnit unit) {
  return ref
      .read(settingsRepositoryProvider)
      .write(weightUnitSetting, unit.name);
}
