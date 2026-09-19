// The multi-select exercise picker used by the day builder: searching by name
// or muscle, filtering with the muscle chips, and returning every exercise
// picked in one go.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
import 'package:gymfy/features/workout/screens/widgets/exercise_picker.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/widgets/exercise_thumbnail.dart';

import 'support/default_accent.dart';

final _sample = <Exercise>[
  Exercise(
    id: 'barbell_bench_press',
    name: 'Barbell Bench Press',
    muscleIds: const ['chest', 'triceps'],
    gifPath: 'assets/exercises/barbell_bench_press.gif',
    isPlateLoaded: true,
    isCustom: false,
    isArchived: false,
  isTimed: false,
  equipment: 'other',
  ),
  Exercise(
    id: 'push_up',
    name: 'Push-Up',
    muscleIds: const ['chest'],
    isPlateLoaded: false,
    isCustom: false,
    isArchived: false,
  isTimed: false,
  equipment: 'other',
  ),
  Exercise(
    id: 'pull_up',
    name: 'Pull-Up',
    muscleIds: const ['lats', 'biceps'],
    isPlateLoaded: false,
    isCustom: false,
    isArchived: false,
  isTimed: false,
  equipment: 'other',
  ),
];

/// Opens the picker over a real route and returns a getter for whatever the
/// sheet eventually popped.
///
/// The picker is a modal bottom sheet, so it needs a route to open over —
/// pumping the sheet widget on its own would skip the part under test (what the
/// confirm button hands back). The result is read through a getter because it
/// only arrives once the sheet closes.
Future<List<String>? Function()> _openPicker(WidgetTester tester) async {
  List<String>? result;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        defaultAccentOverride,
        exerciseListProvider.overrideWith((ref) => Stream.value(_sample)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showExercisePicker(context);
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

  return () => result;
}

void main() {
  testWidgets('lists every exercise', (tester) async {
    await _openPicker(tester);

    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Push-Up'), findsOneWidget);
    expect(find.text('Pull-Up'), findsOneWidget);
  });

  testWidgets('search matches a muscle name, not just the exercise name', (
    tester,
  ) async {
    await _openPicker(tester);

    await tester.enterText(find.byType(TextField), 'lats');
    await tester.pumpAndSettle();

    // "Lats" appears nowhere in "Pull-Up" — searching by muscle is the whole
    // point of the field, and it is invisible unless a test pins it down.
    expect(find.text('Pull-Up'), findsOneWidget);
    expect(find.text('Push-Up'), findsNothing);
  });

  testWidgets('a muscle chip narrows the list', (tester) async {
    await _openPicker(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Chest'));
    await tester.pumpAndSettle();

    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Push-Up'), findsOneWidget);
    expect(find.text('Pull-Up'), findsNothing);
  });

  testWidgets('nothing can be added until something is picked', (tester) async {
    await _openPicker(tester);

    expect(find.text('Nothing selected'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Add'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('several exercises come back from one trip', (tester) async {
    final resultOf = await _openPicker(tester);

    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pull-Up'));
    await tester.pumpAndSettle();

    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Add 2'));
    await tester.pumpAndSettle();

    expect(resultOf(), ['barbell_bench_press', 'pull_up']);
  });

  testWidgets('a selection survives the filter changing under it', (
    tester,
  ) async {
    final resultOf = await _openPicker(tester);

    await tester.tap(find.text('Pull-Up'));
    await tester.pumpAndSettle();

    // Narrowing to Chest hides the Pull-Up row entirely. It must stay picked:
    // silently dropping it would mean building a day one muscle at a time.
    await tester.tap(find.widgetWithText(FilterChip, 'Chest'));
    await tester.pumpAndSettle();
    expect(find.text('Pull-Up'), findsNothing);
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.text('Push-Up'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add 2'));
    await tester.pumpAndSettle();

    expect(resultOf(), ['pull_up', 'push_up']);
  });

  testWidgets('tapping a picked exercise again unpicks it', (tester) async {
    await _openPicker(tester);

    await tester.tap(find.text('Push-Up'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.text('Push-Up'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing selected'), findsOneWidget);
  });

  testWidgets('rows show a still of the movement', (tester) async {
    await _openPicker(tester);

    // This is the screen where the thumbnail earns the most: you are scanning
    // a long list for a lift you already have in mind, and a shape matches
    // faster than a name.
    expect(find.byType(ExerciseThumbnail), findsNWidgets(3));
    // Only the bench press has one in the fixtures; the other two have to fall
    // back to the icon rather than leaving a hole in the row.
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('picking a row swaps its still for a tick', (tester) async {
    await _openPicker(tester);

    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pumpAndSettle();

    // The row has to say "picked" more loudly than it says which exercise it
    // is, so the picture gets out of the way entirely.
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('dismissing returns null rather than an empty list', (
    tester,
  ) async {
    final resultOf = await _openPicker(tester);

    Navigator.of(tester.element(find.text('Add exercises'))).pop();
    await tester.pumpAndSettle();

    // "Cancelled" and "picked nothing" have to stay the same answer, or the
    // caller ends up showing a "0 added" snackbar for a dismissed sheet.
    expect(resultOf(), isNull);
  });
}
