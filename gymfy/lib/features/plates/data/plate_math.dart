// Working out which plates go on the bar.
//
// Everything here works in the *display* unit, not in kilograms — and that is a
// deliberate exception to the app-wide "store kilograms always" rule.
//
// A plate is a physical object stamped with a number. A 45 lb plate is 45 lb;
// calling it 20.411656 kg and converting back would produce rounding dust and,
// worse, plate sets that don't exist. Barbells are the same: a 45 lb bar and a
// 20 kg bar are different bars, not the same bar described twice.
//
// So the inventory is stored per unit, and switching units switches which
// inventory is in use. Nothing is converted, because there is nothing to
// convert — the numbers on the plates don't change when you change your mind
// about units.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/settings_repository.dart';
import '../../../shared/utils/units.dart';

/// Setting keys. One per unit, since the two hold different physical objects.
const platesKgSetting = 'plates_kg';
const platesLbsSetting = 'plates_lbs';
const barKgSetting = 'bar_kg';
const barLbsSetting = 'bar_lbs';

/// The plate denominations a well-stocked gym has, per unit.
const defaultPlatesKg = <double>[25, 20, 15, 10, 5, 2.5, 1.25];
const defaultPlatesLbs = <double>[45, 35, 25, 10, 5, 2.5];

/// Bars to choose from, per unit. The first is the default.
const barsKg = <double>[20, 15, 10];
const barsLbs = <double>[45, 35, 25];

/// Plate denominations that can be offered in the settings picker — a superset
/// of the defaults, including the micro plates some gyms have.
const selectablePlatesKg = <double>[25, 20, 15, 10, 5, 2.5, 1.25, 1, 0.5, 0.25];
const selectablePlatesLbs = <double>[100, 45, 35, 25, 10, 5, 2.5, 1.25];

/// The competition colour of a plate.
///
/// These are the IWF/IPF colours stamped into calibrated plates, and they are
/// the one place in the app where a hardcoded colour is right: a 20 kg plate is
/// blue in every gym on earth, and recolouring it to the user's accent would
/// throw away the fastest way to read a loaded bar. Everything *else* on these
/// screens still follows the accent.
///
/// Plates outside the competition set (and most pound plates, which are usually
/// plain iron) fall back to a neutral grey rather than being assigned an
/// invented colour that would contradict the real thing.
Color plateColor(double weight, WeightUnit unit) {
  const red = Color(0xFFD32F2F);
  const blue = Color(0xFF1976D2);
  const yellow = Color(0xFFFBC02D);
  const green = Color(0xFF388E3C);
  const white = Color(0xFFE0E0E0);
  const chrome = Color(0xFF9E9E9E);

  if (unit == WeightUnit.kg) {
    return switch (weight) {
      25 => red,
      20 => blue,
      15 => yellow,
      10 => green,
      5 => white,
      2.5 => red,
      2 => blue,
      1.5 => yellow,
      1 => green,
      0.5 => white,
      _ => chrome,
    };
  }

  // Pound plates only carry these colours on calibrated competition sets, but
  // the ranking is the same, so the same reading habit works.
  return switch (weight) {
    100 => chrome,
    45 => blue,
    35 => yellow,
    25 => green,
    10 => white,
    5 => red,
    _ => chrome,
  };
}

/// Whether [plateColor] returns something light enough to need dark text on it.
bool plateNeedsDarkLabel(Color color) => color.computeLuminance() > 0.5;

/// The result of loading a bar: what goes on each side, and what's left over.
class PlateLoad {
  const PlateLoad({
    required this.perSide,
    required this.achieved,
    required this.target,
    required this.bar,
  });

  /// Plates for ONE side, heaviest first. Repeated entries mean repeated
  /// plates, so `[20, 20, 5]` is two twenties and a five.
  final List<double> perSide;

  /// The weight these plates actually make, which may be under [target] when
  /// the target isn't reachable with the available plates.
  final double achieved;

  final double target;
  final double bar;

  /// How far short (or over) the loadable weight falls. Zero when exact.
  double get difference => achieved - target;

  bool get isExact => difference.abs() < 0.001;

  /// True when the target is below the empty bar — nothing to load, and the
  /// number on screen would otherwise be a confusing negative.
  bool get belowBar => target < bar - 0.001;
}

/// Works out the heaviest loadable weight not exceeding [target].
///
/// Greedy from the heaviest plate down, which is optimal for every real plate
/// set (each denomination divides evenly into the ones above it) and is also
/// what a person does at the rack — big plates first.
///
/// [plates] need not be sorted. An empty list, or a target at or below the bar,
/// gives an empty load rather than an error: "just the bar" is a valid answer.
PlateLoad calculatePlates({
  required double target,
  required double bar,
  required List<double> plates,
}) {
  if (target < bar - 0.001) {
    return PlateLoad(
      perSide: const [],
      achieved: bar,
      target: target,
      bar: bar,
    );
  }

  final available = [...plates]..sort((a, b) => b.compareTo(a));
  // Everything is doubled because plates go on in pairs; working in per-side
  // weight keeps the arithmetic in the same units the answer is given in.
  var remaining = (target - bar) / 2;
  final perSide = <double>[];

  for (final plate in available) {
    // The epsilon absorbs binary-float dust: 2.5 * 3 is 7.500000000000001, and
    // without it a perfectly loadable weight would come back one plate short.
    while (remaining >= plate - 0.001) {
      perSide.add(plate);
      remaining -= plate;
    }
  }

  final loaded = perSide.fold<double>(0, (sum, p) => sum + p);
  return PlateLoad(
    perSide: perSide,
    achieved: bar + loaded * 2,
    target: target,
    bar: bar,
  );
}

/// Collapses `[20, 20, 5]` into `[(20, 2), (5, 1)]` for display.
///
/// Showing "20 × 2" beats drawing two identical rows: it's the count you check
/// when loading, not the list.
List<({double plate, int count})> groupPlates(List<double> perSide) {
  final grouped = <({double plate, int count})>[];
  for (final plate in perSide) {
    if (grouped.isNotEmpty && grouped.last.plate == plate) {
      final last = grouped.removeLast();
      grouped.add((plate: plate, count: last.count + 1));
    } else {
      grouped.add((plate: plate, count: 1));
    }
  }
  return grouped;
}

/// Parses a stored inventory ("25,20,15") back into numbers.
///
/// Anything unparseable falls back to [fallback] rather than leaving the user
/// with no plates at all — a broken setting should not make the calculator
/// useless.
List<double> parsePlates(String? raw, {required List<double> fallback}) {
  if (raw == null || raw.trim().isEmpty) return fallback;
  final parsed = raw
      .split(',')
      .map((part) => double.tryParse(part.trim()))
      .whereType<double>()
      .where((value) => value > 0)
      .toList();
  if (parsed.isEmpty) return fallback;
  return parsed..sort((a, b) => b.compareTo(a));
}

/// Serialises an inventory for storage.
String encodePlates(Iterable<double> plates) {
  final sorted = [...plates]..sort((a, b) => b.compareTo(a));
  return sorted.map(formatPlate).join(',');
}

/// Formats a plate weight without a trailing `.0`, e.g. `2.5` and `20`.
String formatPlate(double value) {
  return value == value.roundToDouble()
      ? value.round().toString()
      : value.toString();
}

/// The plate denominations available in the current unit.
final availablePlatesProvider = Provider<List<double>>((ref) {
  final unit = ref.watch(weightUnitProvider);
  final key = unit == WeightUnit.kg ? platesKgSetting : platesLbsSetting;
  final fallback = unit == WeightUnit.kg ? defaultPlatesKg : defaultPlatesLbs;
  final raw = ref.watch(rawSettingProvider(key)).value;
  return parsePlates(raw, fallback: fallback);
});

/// The bar weight in the current unit.
final barWeightProvider = Provider<double>((ref) {
  final unit = ref.watch(weightUnitProvider);
  final key = unit == WeightUnit.kg ? barKgSetting : barLbsSetting;
  final bars = barOptionsFor(unit);
  final raw = ref.watch(rawSettingProvider(key)).value;
  final parsed = double.tryParse(raw ?? '');
  // Only a bar we actually offer: a stored value from some other build
  // shouldn't put an unloadable bar weight on screen. Zero is among the
  // options now, so "no bar" survives a restart like any other choice.
  return parsed != null && bars.contains(parsed) ? parsed : bars.first;
});

/// The bar options offered for [unit], including "no bar" at the end.
///
/// Zero is a real answer, not a placeholder. "Plate-loaded" does not mean "on a
/// barbell": a hack squat, a leg press and a plate-loaded T-bar all take plates
/// onto a carriage whose weight is not 20 kg — and adding a bar that isn't
/// there made the calculator's total wrong by exactly one bar, every time.
///
/// Last rather than first, so it never reads as the default.
List<double> barOptionsFor(WeightUnit unit) => [
  ...(unit == WeightUnit.kg ? barsKg : barsLbs),
  0,
];

/// How a bar weight reads on a picker.
String formatBar(double bar, WeightUnit unit) =>
    bar == 0 ? 'None' : '${formatPlate(bar)} ${unit.label}';

/// The bar for one exercise, in the current unit.
///
/// Falls back to the gym-wide default when the exercise has no bar of its own,
/// which is every exercise until someone says otherwise.
///
/// The stored value is kilograms — the unit everything is stored in — so a
/// pounds user who sets "no bar" still gets zero, and a 20 kg bar does not
/// become a 20 lb one by changing the display unit.
double barForExercise(double? storedKg, double gymDefault, WeightUnit unit) {
  if (storedKg == null) return gymDefault;
  if (storedKg == 0) return 0;
  return weightIn(storedKg, unit);
}
