// The warm-up calculator: ramp sets from a working weight, rounded with the
// plates you actually own, and logged as warm-ups.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/features/plates/data/plate_math.dart';
import 'package:gymfy/features/workout/data/logging_preferences.dart';
import 'package:gymfy/features/workout/data/warmup_calculator.dart';
import 'package:gymfy/features/workout/widgets/warmup_calculator_sheet.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/units.dart';

import 'support/default_accent.dart';

Exercise _exercise({bool plateLoaded = true}) => Exercise(
  id: 'barbell_back_squat',
  name: 'Barbell back squat',
  muscleIds: const ['quads'],
  isPlateLoaded: plateLoaded,
  isCustom: false,
  isArchived: false,
  isTimed: false,
  equipment: 'barbell',
);

List<WarmupStep> _plan({
  required double workingKg,
  List<int> percents = defaultWarmupRamp,
  WeightUnit unit = WeightUnit.kg,
  bool plateLoaded = true,
  List<double> plates = defaultPlatesKg,
  double bar = 20,
}) => planWarmups(
  workingKg: workingKg,
  percents: percents,
  unit: unit,
  plateLoaded: plateLoaded,
  plates: plates,
  bar: bar,
);

void main() {
  group('the ramp', () {
    test('a barbell starts with the empty bar, then climbs', () {
      final steps = _plan(workingKg: 100);

      expect(steps.map((s) => s.weightKg), [20, 40, 60, 80]);
      expect(steps.first.isEmptyBar, isTrue);
      expect(steps.first.reps, emptyBarReps);
    });

    test('reps fall as the weight climbs', () {
      final steps = _plan(workingKg: 100);

      expect(steps.map((s) => s.reps), [10, 5, 3, 2]);
    });

    test('each step says what goes on each side', () {
      final steps = _plan(workingKg: 100);

      expect(steps[1].perSide, [10]); // 40 kg
      expect(steps[2].perSide, [20]); // 60 kg
      expect(steps[3].perSide, [25, 5]); // 80 kg
    });

    test('rounds down to what the plates can make, never up', () {
      // 40 % of 102.5 is 41 — half a kilo per side nobody owns. A warm-up a
      // little light costs nothing; one a little heavy is taken out of the
      // working sets.
      final steps = _plan(workingKg: 102.5);

      expect(steps[1].weightKg, 40);
    });

    test('respects a limited inventory', () {
      // No 5s and no 2.5s: 80 % of 100 can only be made as 20 + 20 + 25 + 25.
      final steps = _plan(workingKg: 100, plates: const [25, 20, 10]);

      expect(steps.last.weightKg, 70);
      expect(steps.last.perSide, [25]);
    });

    test('steps that collapse onto the same weight are not repeated', () {
      // 25 kg on a 20 kg bar: every percentage is at or below the bar, so the
      // ramp is just the bar — not the bar four times.
      final steps = _plan(workingKg: 25);

      expect(steps, hasLength(1));
      expect(steps.single.isEmptyBar, isTrue);
    });

    test('nothing at or above the working weight', () {
      final steps = _plan(workingKg: 100, percents: const [50, 99]);

      expect(steps.every((s) => s.weightKg < 100), isTrue);
    });

    test('a machine with no bar starts straight at the first step', () {
      final steps = _plan(workingKg: 100, bar: 0);

      expect(steps.first.isEmptyBar, isFalse);
      expect(steps.first.weightKg, 40);
    });

    test('not plate-loaded rounds to the unit step instead', () {
      final steps = _plan(workingKg: 31, plateLoaded: false);

      // 12.4 → 12.5, 18.6 → 18.5, 24.8 → 25 — half-kilo steps, no empty bar.
      expect(steps.map((s) => s.weightKg), [12.5, 18.5, 25]);
      expect(steps.every((s) => s.perSide.isEmpty), isTrue);
    });

    test('pounds are loaded with pound plates and stored in kilograms', () {
      final steps = _plan(
        workingKg: weightToKilograms(225, WeightUnit.lbs),
        unit: WeightUnit.lbs,
        plates: defaultPlatesLbs,
        bar: 45,
      );

      final shown = steps.map((s) => weightIn(s.weightKg, WeightUnit.lbs));
      expect(shown.first, closeTo(45, 0.001));
      // 40 % of 225 is 90: 22.5 a side, made as 10 + 10 + 2.5.
      expect(shown.elementAt(1), closeTo(90, 0.001));
      expect(steps[1].perSide, [10, 10, 2.5]);
    });

    test('no working weight, no ramp', () {
      expect(_plan(workingKg: 0), isEmpty);
    });
  });

  group('reps per step', () {
    test('five, three, two, then singles', () {
      expect(warmupRepsFor(40), 5);
      expect(warmupRepsFor(50), 5);
      expect(warmupRepsFor(60), 3);
      expect(warmupRepsFor(80), 2);
      expect(warmupRepsFor(90), 1);
    });
  });

  group('the stored ramp', () {
    test('parses, sorts and de-duplicates', () {
      expect(parseWarmupRamp('80, 40,60,60'), [40, 60, 80]);
    });

    test('ignores values that are not a ramp step', () {
      expect(parseWarmupRamp('0,50,100,abc,70'), [50, 70]);
    });

    test('falls back to the default when unset or unreadable', () {
      expect(parseWarmupRamp(null), defaultWarmupRamp);
      expect(parseWarmupRamp('nonsense'), defaultWarmupRamp);
    });

    test('round-trips through storage', () {
      for (final preset in warmupRampPresets) {
        expect(parseWarmupRamp(encodeWarmupRamp(preset)), preset);
      }
    });
  });

  group('the sheet', () {
    Future<List<List<WarmupStep>?>> open(
      WidgetTester tester, {
      double workingKg = 100,
      bool plateLoaded = true,
    }) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final results = <List<WarmupStep>?>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...defaultDisplayOverrides],
          child: MaterialApp(
            theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async => results.add(
                      await showWarmupCalculator(
                        context: context,
                        exercise: _exercise(plateLoaded: plateLoaded),
                        workingKg: workingKg,
                        unit: WeightUnit.kg,
                        ramp: defaultWarmupRamp,
                        plates: defaultPlatesKg,
                        bar: 20,
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return results;
    }

    testWidgets('lists the ramp with plates per side', (tester) async {
      await open(tester);

      expect(find.text('Empty bar'), findsOneWidget);
      expect(find.text('40 kg × 5'), findsOneWidget);
      expect(find.text('60 kg × 3'), findsOneWidget);
      expect(find.text('80 kg × 2'), findsOneWidget);
      expect(find.text('80 % · 25 + 5 per side'), findsOneWidget);
      expect(find.text('Log 4 warm-up sets'), findsOneWidget);
    });

    testWidgets('logs every step by default', (tester) async {
      final results = await open(tester);

      await tester.tap(find.text('Log 4 warm-up sets'));
      await tester.pumpAndSettle();

      expect(results.single?.map((s) => s.weightKg), [20, 40, 60, 80]);
    });

    testWidgets('an unticked step is left out', (tester) async {
      final results = await open(tester);

      await tester.tap(find.text('Empty bar'));
      await tester.pump();
      expect(find.text('Log 3 warm-up sets'), findsOneWidget);

      await tester.tap(find.text('Log 3 warm-up sets'));
      await tester.pumpAndSettle();

      expect(results.single?.map((s) => s.weightKg), [40, 60, 80]);
    });

    testWidgets('the working weight can be nudged', (tester) async {
      await open(tester);

      // A pair of the smallest plates: 1.25 a side.
      await tester.tap(find.byTooltip('Heavier'));
      await tester.pump();

      expect(find.text('102.5'), findsOneWidget);
    });

    testWidgets('and typed', (tester) async {
      await open(tester, workingKg: 0);

      expect(
        find.text('Enter the weight you are working up to.'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('warmup-working-weight')),
        '60',
      );
      await tester.pump();

      expect(find.text('Empty bar'), findsOneWidget);
      expect(find.text('35 kg × 3'), findsOneWidget);
    });

    testWidgets('nothing to log, nothing to press', (tester) async {
      final results = await open(tester, workingKg: 0);

      await tester.tap(find.text('Log 0 warm-up sets'));
      await tester.pumpAndSettle();

      expect(results, isEmpty, reason: 'the button is disabled');
    });
  });
}
