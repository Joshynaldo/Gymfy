// Logging a set you built on the plate stacker, all the way to a saved set.
//
// The bug this pins down: the sheet has two steps (weight, then reps) and an
// optional plate stacker that replaces the keypad. Those two were wired as one
// choice instead of two, so "Stack plates" won the whole sheet — step two
// showed the stacker again instead of a rep pad, there was no way to enter a
// rep count, and "Save set" sat disabled forever. You loaded the bar, tapped
// through, and the set was simply never written.
//
// Silent, and only on plate-loaded exercises with the stacker switched on,
// which is exactly why it reads as "weights don't always save".
//
// A real in-memory database here rather than overrides: the stacker reads the
// unit, the bar and the plate inventory, and stubbing those would be stubbing
// the thing under test.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/workout/widgets/log_set_sheet.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/units.dart';

import 'support/default_accent.dart';

final _squat = Exercise(
  id: 'barbell_back_squat',
  name: 'Barbell back squat',
  muscleIds: const ['quads'],
  isPlateLoaded: true,
  isCustom: false,
  isArchived: false,
  isTimed: false,
  equipment: 'other',
);

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late List<LoggedSetInput?> results;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    results = [];
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        defaultAccentOverride,
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// Opens the sheet on a plate-loaded exercise.
  ///
  /// A tall surface, not the 800x600 the binding defaults to: the stacker is
  /// taller than the keypad it replaces, and on a short surface the buttons
  /// under it land off-screen — which fails as "the tap did nothing", the same
  /// symptom as the bug.
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async => results.add(
                    await showLogSetSheet(
                      context: context,
                      exercise: _squat,
                      isWarmup: false,
                      initialWeight: 60,
                      initialReps: 8,
                      unit: WeightUnit.kg,
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
  }

  Future<void> tapText(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('the stacker hands over to the rep pad on step two', (
    tester,
  ) async {
    await open(tester);

    await tapText(tester, 'Stack plates');
    expect(
      find.text('STEP 1 — WEIGHT'),
      findsNothing,
      reason: 'the stacker replaces the keypad for the weight step',
    );

    await tapText(tester, 'Next: reps');

    expect(
      find.text('STEP 2 — REPS'),
      findsOneWidget,
      reason: 'the stacker is for the weight only; reps still need a pad',
    );
  });

  testWidgets('a set built on the stacker can actually be saved', (
    tester,
  ) async {
    // The whole point. Everything above is the mechanism; this is the outcome
    // the user cares about, and it was silently impossible.
    await open(tester);

    await tapText(tester, 'Stack plates');
    await tapText(tester, 'Next: reps');
    await tapText(tester, '8');
    await tapText(tester, 'Save set');

    expect(results, hasLength(1));
    expect(results.single, isNotNull, reason: 'the sheet returned no set');
    expect(results.single!.reps, 8);
    expect(
      results.single!.weight,
      greaterThan(0),
      reason: 'the weight built on the bar has to survive the trip',
    );
  });

  testWidgets('switching back to the keypad keeps the stacked weight', (
    tester,
  ) async {
    // The toggle is a change of input method, not a reset. Loading the bar and
    // then deciding to type instead must not silently throw the weight away —
    // the old code assigned it without a `setState`, so the readout could show
    // a number the sheet no longer had.
    await open(tester);

    await tapText(tester, 'Stack plates');
    await tapText(tester, 'Type a weight');

    expect(find.text('STEP 1 — WEIGHT'), findsOneWidget);
    expect(
      find.text('60'),
      findsOneWidget,
      reason: 'the weight the stacker was showing is still on the readout',
    );
  });
}
