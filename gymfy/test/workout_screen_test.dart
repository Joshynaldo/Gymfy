// The Workout tab: it opens on the *active* split's days rather than on a list
// of splits, and the switcher is how you reach the others.

// Flutter exports an animation curve called `Split`, which collides with the
// database's split row class.
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/features/workout/screens/workout_screen.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

final _ppl = Split(
  id: 1,
  name: 'Push / Pull / Legs',
  position: 0,
  isActive: true,
  createdAt: DateTime(2026, 7, 1),
);

final _upperLower = Split(
  id: 2,
  name: 'Upper / Lower',
  position: 1,
  isActive: false,
  createdAt: DateTime(2026, 6, 1),
);

final _pushDay = WorkoutDay(id: 10, splitId: 1, name: 'Push', position: 0);
final _pullDay = WorkoutDay(id: 11, splitId: 1, name: 'Pull', position: 1);

final _bench = Exercise(
  id: 'barbell_bench_press',
  name: 'Barbell Bench Press',
  muscleIds: const ['chest'],
  isPlateLoaded: true,
  isCustom: false,
  isArchived: false,
);

/// Renders the tab with the split/day data injected, so no database is opened.
Future<void> _pumpTab(
  WidgetTester tester, {
  required List<Split> splits,
  required Split? active,
  List<ScheduledDay> days = const [],
  Map<int, List<PlannedExercise>> exercises = const {},
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        defaultAccentOverride,
        splitListProvider.overrideWith((ref) => Stream.value(splits)),
        activeSplitProvider.overrideWith((ref) => Stream.value(active)),
        scheduledDaysProvider.overrideWith(
          (ref, splitId) => Stream.value(
            days.where((d) => d.day.splitId == splitId).toList(),
          ),
        ),
        dayExercisesProvider.overrideWith(
          (ref, dayId) => Stream.value(exercises[dayId] ?? const []),
        ),
      ],
      child: const MaterialApp(home: WorkoutScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the active split\'s days are the first thing on screen', (
    tester,
  ) async {
    await _pumpTab(
      tester,
      splits: [_ppl, _upperLower],
      active: _ppl,
      days: [
        ScheduledDay(day: _pushDay, weekdays: const [1]),
        ScheduledDay(day: _pullDay, weekdays: const [4]),
      ],
    );

    // The split name is the title, and its days are already listed — no tap in
    // between, which was the whole point of the redesign.
    expect(find.text('Push / Pull / Legs'), findsOneWidget);
    expect(find.text('Push'), findsOneWidget);
    expect(find.text('Pull'), findsOneWidget);
    // The inactive split is not shown here at all.
    expect(find.text('Upper / Lower'), findsNothing);
  });

  testWidgets('a day card lists its exercises and targets inline', (
    tester,
  ) async {
    await _pumpTab(
      tester,
      splits: [_ppl],
      active: _ppl,
      days: [ScheduledDay(day: _pushDay, weekdays: const [1])],
      exercises: {
        10: [
          PlannedExercise(
            entry: WorkoutExercise(
              id: 1,
              dayId: 10,
              exerciseId: _bench.id,
              defaultSets: 3,
              defaultReps: 8,
              defaultRepsMax: 12,
              position: 0,
              warmupSets: 0,
            ),
            exercise: _bench,
          ),
        ],
      },
    );

    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('3 × 8–12'), findsOneWidget);
    expect(find.textContaining('1 exercise'), findsOneWidget);
  });

  testWidgets('a day with no exercises says so instead of looking broken', (
    tester,
  ) async {
    await _pumpTab(
      tester,
      splits: [_ppl],
      active: _ppl,
      days: [ScheduledDay(day: _pushDay, weekdays: const [])],
    );

    expect(find.textContaining('No exercises yet'), findsOneWidget);
    // "Not scheduled" is named rather than left blank — the day won't show up
    // on any weekday until it's fixed.
    expect(find.textContaining('Not scheduled'), findsOneWidget);
  });

  testWidgets('the switcher lists every split and marks the active one', (
    tester,
  ) async {
    await _pumpTab(
      tester,
      splits: [_ppl, _upperLower],
      active: _ppl,
      days: [ScheduledDay(day: _pushDay, weekdays: const [1])],
    );

    await tester.tap(find.byIcon(Icons.swap_horiz));
    await tester.pumpAndSettle();

    expect(find.text('Upper / Lower'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    // The two ways out of a single-split app.
    expect(find.text('New split'), findsOneWidget);
    expect(find.text('Manage splits'), findsOneWidget);
  });

  testWidgets('with no splits at all the tab offers to create one', (
    tester,
  ) async {
    await _pumpTab(tester, splits: const [], active: null);

    expect(find.text('No splits yet'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'New split'), findsOneWidget);
    // Nothing to switch between yet, so the app bar stays bare.
    expect(find.byIcon(Icons.swap_horiz), findsNothing);
  });

  testWidgets('splits but no active one asks which to follow', (tester) async {
    // Reachable by deleting the active split. Guessing one would silently put
    // the user on a programme they didn't choose.
    await _pumpTab(tester, splits: [_upperLower], active: null);

    expect(find.text('No active split'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Choose a split'),
      findsOneWidget,
    );
  });

  testWidgets('a day can be added to the active split', (tester) async {
    await _pumpTab(
      tester,
      splits: [_ppl],
      active: _ppl,
      days: [ScheduledDay(day: _pushDay, weekdays: const [1])],
    );

    expect(find.widgetWithText(FloatingActionButton, 'Add day'), findsOneWidget);
  });
}
