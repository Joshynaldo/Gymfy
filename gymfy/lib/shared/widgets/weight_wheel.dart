import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/units.dart';
import 'number_wheel.dart';

/// The steps a weight wheel offers below the whole number, per unit.
///
/// Quarter-kilos because a pair of 0.25 kg micro plates is the smallest real
/// jump; half-pounds for the same reason on a pound bar. Anything finer would
/// be scrolling past numbers nobody can load.
const _kgFractions = [0.0, 0.25, 0.5, 0.75];
const _lbsFractions = [0.0, 0.5];

/// The largest whole number offered, per unit. Above these you are no longer
/// logging a lift, you are mis-scrolling.
const _maxKg = 300;
const _maxLbs = 660;

/// Picks a weight with two drums: whole numbers and the fraction.
///
/// Two wheels rather than one 1200-item drum of quarter-kilos. A single wheel
/// technically offers the same values, but getting from 0 to 100 kg means
/// scrolling past four hundred entries — the split makes the common move (pick
/// 82, then .5) two quick flicks.
///
/// Works entirely in the display unit: the caller converts once, at the edges,
/// like everything else that shows a weight.
class WeightWheel extends ConsumerStatefulWidget {
  const WeightWheel({
    super.key,
    required this.initialWeight,
    required this.unit,
    required this.onChanged,
    this.label = 'Weight',
  });

  /// Starting value, in [unit].
  final double initialWeight;
  final WeightUnit unit;

  /// Called with the new weight, in [unit], on every change.
  final ValueChanged<double> onChanged;

  final String label;

  @override
  ConsumerState<WeightWheel> createState() => _WeightWheelState();
}

class _WeightWheelState extends ConsumerState<WeightWheel> {
  late final List<double> _fractions = widget.unit == WeightUnit.kg
      ? _kgFractions
      : _lbsFractions;
  late final int _maxWhole =
      widget.unit == WeightUnit.kg ? _maxKg : _maxLbs;

  late final FixedExtentScrollController _wholeController;
  late final FixedExtentScrollController _fractionController;

  late int _whole;
  late int _fractionIndex;

  @override
  void initState() {
    super.initState();
    final start = widget.initialWeight.clamp(0.0, _maxWhole.toDouble());
    _whole = start.floor();
    // Nearest offered step, so an odd stored value (a converted weight, or one
    // typed before the wheel existed) lands somewhere sensible instead of
    // always snapping down to .0.
    final remainder = start - _whole;
    _fractionIndex = _nearestFraction(remainder);
    // Rounding .9 up rolls into the next whole number.
    if (_fractionIndex == _fractions.length) {
      _fractionIndex = 0;
      _whole = (_whole + 1).clamp(0, _maxWhole);
    }

    _wholeController = FixedExtentScrollController(initialItem: _whole);
    _fractionController = FixedExtentScrollController(
      initialItem: _fractionIndex,
    );
  }

  /// Index of the closest fraction to [remainder], or `_fractions.length` when
  /// the nearest step is a whole number above.
  int _nearestFraction(double remainder) {
    var best = 0;
    var bestDistance = (remainder - _fractions.first).abs();
    for (var i = 1; i < _fractions.length; i++) {
      final distance = (remainder - _fractions[i]).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    return (1 - remainder) < bestDistance ? _fractions.length : best;
  }

  @override
  void dispose() {
    _wholeController.dispose();
    _fractionController.dispose();
    super.dispose();
  }

  void _report() {
    widget.onChanged(_whole + _fractions[_fractionIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 3,
          child: NumberWheel(
            label: widget.label,
            controller: _wholeController,
            itemCount: _maxWhole + 1,
            labelAt: (index) => '$index',
            onChanged: (index) {
              _whole = index;
              _report();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: NumberWheel(
            label: widget.unit.label,
            controller: _fractionController,
            itemCount: _fractions.length,
            // Shown as ".25" rather than "0.25": it reads as a continuation of
            // the number on the left, which is what it is.
            labelAt: (index) => _fractionLabel(_fractions[index]),
            onChanged: (index) {
              _fractionIndex = index;
              _report();
            },
          ),
        ),
      ],
    );
  }
}

String _fractionLabel(double fraction) {
  if (fraction == 0) return '.0';
  return '.${(fraction * 100).round().toString().padLeft(2, '0')}'
      .replaceAll(RegExp(r'0$'), '');
}
