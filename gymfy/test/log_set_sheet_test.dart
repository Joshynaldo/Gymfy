// The sheet you log a set in: a keypad, two steps, and the one place the
// design template was deliberately not followed.
//
// Providers are overridden rather than pointing at a real database — drift
// keeps a stream-cleanup timer alive that `pumpAndSettle` waits on forever. See
// the note in `support/default_accent.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/features/overload/data/overload_math.dart';
import 'package:gymfy/features/workout/widgets/log_set_sheet.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/units.dart';

import 'support/default_accent.dart';

final _bench = Exercise(
  id: 'barbell_bench_press',
  name: 'Barbell bench press',
  muscleIds: const ['chest'],
  isPlateLoaded: false,
  isCustom: false,
  isArchived: false,
);

LoggedSet _set({double weight = 100, int reps = 8, bool isWarmup = false}) =>
    LoggedSet(
      id: 1,
      sessionId: 1,
      exerciseId: _bench.id,
      setNumber: 1,
      weight: weight,
      reps: reps,
      isWarmup: isWarmup,
    );

/// Opens the sheet and hands back a holder for whatever it returns.
Future<List<LoggedSetInput?>> _open(
  WidgetTester tester, {
  double initialWeight = 100,
  int initialReps = 8,
  WeightUnit unit = WeightUnit.kg,
  bool isWarmup = false,
  OverloadSuggestion? suggestion,
  LoggedSet? repeatable,
}) async {
  final results = <LoggedSetInput?>[];

  // A phone, not the 800x600 the test binding defaults to. The sheet is a
  // header, a readout, twelve keys and two buttons — on the default surface the
  // primary button lands past the bottom edge and every tap on it silently
  // misses, which reads in the failure output as the keypad not working.
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [...defaultDisplayOverrides],
      child: MaterialApp(
        theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  results.add(
                    await showLogSetSheet(
                      context: context,
                      exercise: _bench,
                      isWarmup: isWarmup,
                      initialWeight: initialWeight,
                      initialReps: initialReps,
                      unit: unit,
                      suggestion: suggestion,
                      repeatable: repeatable,
                    ),
                  );
                },
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

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.widgetWithText(Center, key).last);
  await tester.pump();
}

void main() {
  group('entering a weight', () {
    testWidgets('opens prefilled, on the weight step', (tester) async {
      // The prefill is the last set you logged or what overload suggests, and
      // on a straight-sets day it is already right — which is what makes the
      // whole sheet two taps.
      await _open(tester);

      expect(find.text('100'), findsOneWidget);
      expect(find.text('STEP 1 — WEIGHT'), findsOneWidget);
      expect(find.text('kg'), findsOneWidget);
    });

    testWidgets('the keypad appends rather than replacing', (tester) async {
      await _open(tester, initialWeight: 0);

      await _tapKey(tester, '1');
      await _tapKey(tester, '0');
      await _tapKey(tester, '2');
      await _tapKey(tester, '.');
      await _tapKey(tester, '5');

      expect(find.text('102.5'), findsOneWidget);
    });

    testWidgets('a second decimal point is refused', (tester) async {
      // "102.5.5" parses to nothing, and a weight that silently becomes zero
      // on save is the worst outcome this screen has.
      await _open(tester, initialWeight: 0);

      await _tapKey(tester, '5');
      await _tapKey(tester, '.');
      await _tapKey(tester, '.');
      await _tapKey(tester, '5');

      expect(find.text('5.5'), findsOneWidget);
    });

    testWidgets('backspace is an icon, not a glyph', (tester) async {
      // U+232B has no glyph in the app's typeface, so it rendered as the
      // browser's last-resort box — caught in the preview, not by a test, which
      // is why there is now a test.
      await _open(tester);

      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
      expect(find.text('backspace'), findsNothing);
      expect(find.text('⌫'), findsNothing);
    });
  });

  group('entering reps', () {
    testWidgets('two digits are possible, and only Save commits', (
      tester,
    ) async {
      // The deliberate deviation from the design template, which saved the set
      // on the first digit of the rep count. One tap quicker, and twelve reps
      // impossible to log — in an app whose own targets read "6–8" and "12–15".
      final results = await _open(tester, initialWeight: 100);

      await tester.tap(find.text('Next: reps'));
      await tester.pumpAndSettle();

      await _tapKey(tester, '1');
      expect(results, isEmpty, reason: 'the first digit must not commit');

      await _tapKey(tester, '2');
      expect(find.text('12'), findsOneWidget);

      await tester.tap(find.text('Save set'));
      await tester.pumpAndSettle();

      expect(results.single?.reps, 12);
      expect(results.single?.weight, 100);
    });

    testWidgets('a third digit is refused', (tester) async {
      await _open(tester);
      await tester.tap(find.text('Next: reps'));
      await tester.pumpAndSettle();

      await _tapKey(tester, '9');
      await _tapKey(tester, '9');
      await _tapKey(tester, '9');

      expect(find.text('99'), findsOneWidget);
    });

    testWidgets('saving is refused until there is a number', (tester) async {
      // A set of zero reps is not a set. The button is visible but inert, so
      // the step still reads as "one more thing to do" rather than the sheet
      // looking finished.
      final results = await _open(tester);
      await tester.tap(find.text('Next: reps'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save set'));
      await tester.pumpAndSettle();

      expect(results, isEmpty);
      expect(find.text('Save set'), findsOneWidget);
    });
  });

  testWidgets('pounds go in, kilograms come out', (tester) async {
    // Every weight in the database is kilograms, always. The sheet speaks the
    // user's unit and converts once, on the way out — see units.dart.
    final results = await _open(tester, initialWeight: 0, unit: WeightUnit.lbs);

    await _tapKey(tester, '2');
    await _tapKey(tester, '2');
    await _tapKey(tester, '0');
    await tester.tap(find.text('Next: reps'));
    await tester.pumpAndSettle();
    await _tapKey(tester, '5');
    await tester.tap(find.text('Save set'));
    await tester.pumpAndSettle();

    expect(results.single?.weight, closeTo(99.79, 0.01));
  });

  testWidgets('the warm-up decision belongs to the sheet', (tester) async {
    // Which button opened it is only an opening bid: you often only know
    // whether that was a ramp-up once the bar is in your hands.
    final results = await _open(tester, isWarmup: false);

    await tester.tap(find.text('Warm-up'));
    await tester.pump();
    await tester.tap(find.text('Next: reps'));
    await tester.pumpAndSettle();
    await _tapKey(tester, '8');
    await tester.tap(find.text('Save set'));
    await tester.pumpAndSettle();

    expect(results.single?.isWarmup, isTrue);
  });

  testWidgets('repeating the last set skips both steps', (tester) async {
    // The straight-sets shortcut: three sets of the same thing is one tap each
    // after the first.
    final results = await _open(
      tester,
      repeatable: _set(weight: 92.5, reps: 6),
    );

    await tester.tap(find.text('Repeat last set'));
    await tester.pumpAndSettle();

    expect(results.single?.weight, 92.5);
    expect(results.single?.reps, 6);
  });

  testWidgets('a suggestion says why the weight is what it is', (tester) async {
    // A suggested number with no explanation is either obeyed blindly or
    // ignored. Saying why makes it something you can disagree with.
    await _open(
      tester,
      suggestion: const OverloadSuggestion(
        weight: 102.5,
        reason: OverloadReason.earned,
      ),
    );

    expect(find.textContaining('hit every set last time'), findsOneWidget);
  });

  testWidgets('a warm-up is never told what to lift', (tester) async {
    // The suggestion is a target for the working sets; putting it on the bar
    // for a ramp-up makes the ramp-up pointless.
    await _open(
      tester,
      isWarmup: true,
      suggestion: const OverloadSuggestion(
        weight: 102.5,
        reason: OverloadReason.earned,
      ),
    );

    expect(find.textContaining('hit every set last time'), findsNothing);
  });
}
