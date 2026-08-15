// Units for body measurements.
//
// Only one measurement is a weight. The rest are lengths in centimetres and
// have nothing to do with the kg/lbs setting, so every screen that shows a
// measurement needs to ask "is this the weight one?" — this puts that question
// in one place rather than repeating the conditional per screen.

import '../../../shared/models/body_measurement.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';

extension MeasurementDisplay on MeasurementField {
  /// Whether this field follows the weight-unit setting.
  bool get isWeight => this == MeasurementField.weight;

  /// The unit label to show, e.g. "lbs" for weight but always "cm" for a waist.
  String labelIn(WeightUnit weightUnit) => isWeight ? weightUnit.label : unit;

  /// Converts a stored value for display.
  double displayValue(double stored, WeightUnit weightUnit) =>
      isWeight ? weightIn(stored, weightUnit) : stored;

  /// Converts a value the user typed back to what gets stored.
  double storedValue(double typed, WeightUnit weightUnit) =>
      isWeight ? weightToKilograms(typed, weightUnit) : typed;

  /// Formats a stored value without its unit label.
  String formatValue(double stored, WeightUnit weightUnit) {
    if (!isWeight) return formatWeight(stored);
    // Rounded so a converted weight doesn't read as 181.88499 lbs.
    return formatWeightIn(roundToLoadable(stored, weightUnit), weightUnit);
  }

  /// Formats a stored value with its unit label, e.g. "82.5 kg" or "94 cm".
  String formatWithUnit(double stored, WeightUnit weightUnit) =>
      '${formatValue(stored, weightUnit)} ${labelIn(weightUnit)}';

  /// Parses a typed value into what should be stored, or null if unusable.
  double? parseStored(String text, WeightUnit weightUnit) {
    final value = parseWeight(text);
    if (value == null) return null;
    return storedValue(value, weightUnit);
  }
}
