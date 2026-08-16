// The weight wheel: two drums, the unit's own steps, and no keyboard.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/shared/utils/units.dart';
import 'package:gymfy/shared/widgets/weight_wheel.dart';

import 'support/default_accent.dart';
import 'support/weight_wheel.dart';

void main() {
  late List<double> reported;

  setUp(() => reported = []);

  Future<void> pump(
    WidgetTester tester, {
    double initialWeight = 0,
    WeightUnit unit = WeightUnit.kg,
  }) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [defaultAccentOverride],
        child: MaterialApp(
          home: Scaffold(
            body: WeightWheel(
              initialWeight: initialWeight,
              unit: unit,
              onChanged: reported.add,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('starts silent — it reports only what the user changes', (
    tester,
  ) async {
    await pump(tester, initialWeight: 60);

    // The caller already has this value; re-reporting on build would make an
    // untouched dialog look edited.
    expect(reported, isEmpty);
  });

  testWidgets('the whole drum picks whole numbers', (tester) async {
    await pump(tester);

    await pickWeight(tester, whole: 82);

    expect(reported.last, 82);
  });

  testWidgets('the fraction drum adds quarters in kilograms', (tester) async {
    await pump(tester);

    await pickWeight(tester, whole: 82, fractionIndex: 2);

    // Index 2 of [.0, .25, .5, .75].
    expect(reported.last, 82.5);
  });

  testWidgets('kilograms offer quarter steps', (tester) async {
    await pump(tester);

    // A pair of 0.25 kg micro plates is the smallest real jump. Only the
    // quarter is checked: the drum builds lazily, so .75 isn't rendered while
    // the wheel sits at .0, and asserting on it would test the viewport rather
    // than the steps.
    expect(find.text('.25'), findsOneWidget);
  });

  testWidgets('pounds offer halves, not quarters', (tester) async {
    await pump(tester, unit: WeightUnit.lbs);

    expect(find.text('.5'), findsOneWidget);
    expect(find.text('.25'), findsNothing);
  });

  testWidgets('the unit is named on the fraction drum', (tester) async {
    await pump(tester, unit: WeightUnit.lbs);

    expect(find.text('lbs'), findsOneWidget);
  });

  testWidgets('an existing weight opens on itself', (tester) async {
    await pump(tester, initialWeight: 82.5);

    // Reopening a logged set should show what was logged, not zero.
    expect(find.text('82'), findsOneWidget);
    expect(find.text('.5'), findsOneWidget);
  });

  testWidgets('a weight between steps opens on the nearest one', (
    tester,
  ) async {
    // 82.4 isn't offered — a converted pounds figure, or something typed
    // before the wheel existed. Snapping to .5 beats always falling to .0.
    await pump(tester, initialWeight: 82.4);

    expect(find.text('82'), findsOneWidget);
    expect(find.text('.5'), findsOneWidget);
  });

  testWidgets('a weight just under a whole number rolls up to it', (
    tester,
  ) async {
    // 82.9 is nearer 83 than 82.75, so it must not stick on the lower drum.
    await pump(tester, initialWeight: 82.9);

    expect(find.text('83'), findsOneWidget);
    expect(find.text('.0'), findsOneWidget);
  });

  testWidgets('zero is a valid starting point', (tester) async {
    await pump(tester);

    // Several screens treat zero as "not set", so it has to be reachable and
    // has to be where an empty input starts.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('.0'), findsOneWidget);
  });

  testWidgets('a negative stored weight is clamped rather than shown', (
    tester,
  ) async {
    await pump(tester, initialWeight: -5);

    expect(find.text('0'), findsOneWidget);
  });
}
