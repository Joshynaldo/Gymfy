// Verifies the exercise list screen's search + muscle-group filtering, using
// injected data (no database or device needed).

// Flutter exports an animation curve called `Split`, which collides with the
// database's split row class.
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/shared/widgets/app_button.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
import 'package:gymfy/features/exercises/screens/exercise_library_screen.dart';
import 'package:gymfy/shared/widgets/exercise_thumbnail.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

final _sample = <Exercise>[
  Exercise(
    id: 'barbell_bench_press',
    name: 'Barbell Bench Press',
    muscleIds: const ['chest', 'triceps'],
    gifPath: 'assets/exercises/barbell_bench_press.gif',
    isPlateLoaded: false,
    isCustom: false,
    isArchived: false,
  ),
  Exercise(
    id: 'pull_up',
    name: 'Pull-Up',
    muscleIds: const ['lats', 'biceps'],
    isPlateLoaded: false,
    isCustom: false,
    isArchived: false,
  ),
  Exercise(
    id: 'barbell_back_squat',
    name: 'Barbell Back Squat',
    muscleIds: const ['quads', 'glutes'],
    isPlateLoaded: false,
    isCustom: false,
    isArchived: false,
  ),
  // A user-created one, on a muscle none of the others use so it stays out of
  // the filter tests above.
  Exercise(
    id: 'custom_cable_lateral_raise',
    name: 'Cable Lateral Raise',
    muscleIds: const ['side_deltoid'],
    isPlateLoaded: false,
    isCustom: true,
    isArchived: false,
  ),
];

final _split = Split(
  id: 1,
  name: 'PPL',
  position: 0,
  isActive: true,
  createdAt: DateTime(2026, 7, 1),
);

final _days = [
  SplitDay(
    split: _split,
    day: WorkoutDay(id: 1, splitId: 1, name: 'Push', position: 0),
  ),
  SplitDay(
    split: _split,
    day: WorkoutDay(id: 2, splitId: 1, name: 'Pull', position: 1),
  ),
];

Future<void> _pumpScreen(
  WidgetTester tester, {
  List<SplitDay> days = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        defaultAccentOverride,
        exerciseListProvider.overrideWith((ref) => Stream.value(_sample)),
        // The "add to day" sheet reads this; without the override it would open
        // a real database just to find out there are no splits.
        allDaysProvider.overrideWith((ref) => Stream.value(days)),
      ],
      child: const MaterialApp(home: ExerciseLibraryScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Enters selection mode the way a user does — there is no other entry point.
Future<void> _selectByLongPress(WidgetTester tester, String name) async {
  await tester.longPress(find.text(name));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists every exercise from the provider', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Pull-Up'), findsOneWidget);
    expect(find.text('Barbell Back Squat'), findsOneWidget);
  });

  testWidgets('the search box only offers a clear button once used', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(find.byTooltip('Clear search'), findsNothing);

    await tester.enterText(find.byType(TextField), 'squat');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Clear search'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    // Clearing restores the full library, not just the empty field.
    expect(find.text('Pull-Up'), findsOneWidget);
    expect(find.byTooltip('Clear search'), findsNothing);
  });

  testWidgets('search box filters by name', (tester) async {
    await _pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'squat');
    await tester.pumpAndSettle();

    expect(find.text('Barbell Back Squat'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsNothing);
    expect(find.text('Pull-Up'), findsNothing);
  });

  testWidgets('muscle chip filters by muscle group', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Chest'));
    await tester.pumpAndSettle();

    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Pull-Up'), findsNothing);
    expect(find.text('Barbell Back Squat'), findsNothing);
  });

  testWidgets('two muscle chips widen the list rather than narrowing it', (
    tester,
  ) async {
    await _pumpScreen(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Chest'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Lats'));
    await tester.pumpAndSettle();

    // OR, not AND: picking two muscles asks for anything training either, which
    // is how a push or pull day gets planned. Requiring both would usually
    // return nothing.
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Pull-Up'), findsOneWidget);
    expect(find.text('Barbell Back Squat'), findsNothing);
  });

  testWidgets('tapping a chip again removes just that muscle', (tester) async {
    await _pumpScreen(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Chest'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Lats'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Chest'));
    await tester.pumpAndSettle();

    expect(find.text('Pull-Up'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsNothing);
  });

  testWidgets('All clears every muscle chip', (tester) async {
    await _pumpScreen(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Chest'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'All'));
    await tester.pumpAndSettle();

    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Pull-Up'), findsOneWidget);
    expect(find.text('Barbell Back Squat'), findsOneWidget);
  });

  testWidgets('search finds exercises by the muscle they train', (
    tester,
  ) async {
    await _pumpScreen(tester);

    // "Quads" appears nowhere in the squat's name.
    await tester.enterText(find.byType(TextField), 'quads');
    await tester.pumpAndSettle();

    expect(find.text('Barbell Back Squat'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsNothing);
  });

  testWidgets('a partial muscle name is enough', (tester) async {
    await _pumpScreen(tester);

    // Nobody types "side_deltoid" in full.
    await tester.enterText(find.byType(TextField), 'delt');
    await tester.pumpAndSettle();

    expect(find.text('Cable Lateral Raise'), findsOneWidget);
    expect(find.text('Pull-Up'), findsNothing);
  });

  testWidgets('search and muscle chips narrow together', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Chest'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'squat');
    await tester.pumpAndSettle();

    // The chips are OR among themselves but AND with the search box, so this
    // asks for a chest exercise named "squat" — there isn't one.
    expect(find.text('Nothing matches'), findsOneWidget);
  });

  testWidgets('offers a way to add an exercise', (tester) async {
    await _pumpScreen(tester);

    expect(find.widgetWithText(AppButton, 'Add exercise'), findsOneWidget);
  });

  testWidgets('long-pressing starts a selection', (tester) async {
    await _pumpScreen(tester);
    expect(find.text('Exercises'), findsOneWidget);

    await _selectByLongPress(tester, 'Pull-Up');

    expect(find.text('1 selected'), findsOneWidget);
    // The normal app bar and the Add FAB step aside while selecting.
    expect(find.text('Exercises'), findsNothing);
    expect(find.text('Add exercise'), findsNothing);
  });

  testWidgets('a plain tap adds to the selection once one is running', (
    tester,
  ) async {
    await _pumpScreen(tester);
    await _selectByLongPress(tester, 'Pull-Up');

    // A tap would normally navigate to the detail screen; in selection mode it
    // has to toggle instead.
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pumpAndSettle();

    expect(find.text('2 selected'), findsOneWidget);
  });

  testWidgets('tapping a selected exercise removes it again', (tester) async {
    await _pumpScreen(tester);
    await _selectByLongPress(tester, 'Pull-Up');
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsOneWidget);
  });

  testWidgets('emptying the selection leaves selection mode', (tester) async {
    await _pumpScreen(tester);
    await _selectByLongPress(tester, 'Pull-Up');

    // Deselecting the last one is the same as cancelling — there's no separate
    // "still selecting, but nothing picked" state to get stuck in.
    await tester.tap(find.text('Pull-Up'));
    await tester.pumpAndSettle();

    expect(find.text('Exercises'), findsOneWidget);
    expect(find.text('Add exercise'), findsOneWidget);
  });

  testWidgets('cancelling clears the selection', (tester) async {
    await _pumpScreen(tester);
    await _selectByLongPress(tester, 'Pull-Up');

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Exercises'), findsOneWidget);
    expect(find.textContaining('selected'), findsNothing);
  });

  testWidgets('the day picker lists every day under its split', (tester) async {
    await _pumpScreen(tester, days: _days);
    await _selectByLongPress(tester, 'Pull-Up');

    await tester.tap(find.byIcon(Icons.playlist_add));
    await tester.pumpAndSettle();

    expect(find.text('Add to day'), findsOneWidget);
    expect(find.text('PPL'), findsOneWidget);
    expect(find.text('Push'), findsOneWidget);
    expect(find.text('Pull'), findsOneWidget);
  });

  testWidgets('the picker counts what is being added', (tester) async {
    await _pumpScreen(tester, days: _days);
    await _selectByLongPress(tester, 'Pull-Up');
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.playlist_add));
    await tester.pumpAndSettle();

    expect(find.text('Add 2 exercises to day'), findsOneWidget);
  });

  testWidgets('with no splits the picker explains instead of showing nothing', (
    tester,
  ) async {
    await _pumpScreen(tester);
    await _selectByLongPress(tester, 'Pull-Up');

    await tester.tap(find.byIcon(Icons.playlist_add));
    await tester.pumpAndSettle();

    // An empty list here reads as a bug; the screen has to say what's missing.
    expect(find.text('No workout days yet'), findsOneWidget);
  });

  testWidgets('only user-created exercises are badged as custom', (
    tester,
  ) async {
    await _pumpScreen(tester);

    // Exactly one badge, and it's on the custom row — a badge on a built-in
    // exercise would promise an edit action that isn't there.
    expect(find.text('Custom'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Custom'),
        matching: find.widgetWithText(InkWell, 'Cable Lateral Raise'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('an exercise with an animation shows a still of it', (
    tester,
  ) async {
    await _pumpScreen(tester);

    // Recognising a lift by its shape is quicker than reading its name, which
    // is what this list is for. Only the bench press has one in the fixtures,
    // so the others must still fall back to the icon rather than a blank.
    expect(find.byType(ExerciseThumbnail), findsNWidgets(4));
    expect(find.byType(Image), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(InkWell, 'Barbell Bench Press'),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
  });
}
