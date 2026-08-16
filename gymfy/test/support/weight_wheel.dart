// Driving a [WeightWheel] from a widget test.
//
// The wheel has no text field to type into, so tests scroll it the way a thumb
// would. One notch is one item extent; [_itemExtent] must match the one in
// NumberWheel, and a mismatch shows up immediately as a wrong value rather than
// as a silent no-op.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/shared/widgets/weight_wheel.dart';

const _itemExtent = 40.0;

/// Scrolls the weight wheel to [whole] plus the fraction at [fractionIndex]
/// (0 = .0, 1 = .25 in kilograms or .5 in pounds).
///
/// Assumes the wheel is currently at zero, which is where every dialog under
/// test starts it.
Future<void> pickWeight(
  WidgetTester tester, {
  required int whole,
  int fractionIndex = 0,
}) async {
  final wheels = find.descendant(
    of: find.byType(WeightWheel),
    matching: find.byType(ListWheelScrollView),
  );

  if (whole != 0) {
    await tester.drag(wheels.at(0), Offset(0, -_itemExtent * whole));
    await tester.pumpAndSettle();
  }
  if (fractionIndex != 0) {
    await tester.drag(wheels.at(1), Offset(0, -_itemExtent * fractionIndex));
    await tester.pumpAndSettle();
  }
}
