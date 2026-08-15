// Verifies the exercise list screen's search + muscle-group filtering, using
// injected data (no database or device needed).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
import 'package:gymfy/features/exercises/screens/exercise_library_screen.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/models/exercise_category.dart';

import 'support/default_accent.dart';

final _sample = <Exercise>[
  Exercise(
    id: 'barbell_bench_press',
    name: 'Barbell Bench Press',
    muscleIds: const ['chest', 'triceps'],
    category: ExerciseCategory.push,
  ),
  Exercise(
    id: 'pull_up',
    name: 'Pull-Up',
    muscleIds: const ['lats', 'biceps'],
    category: ExerciseCategory.pull,
  ),
  Exercise(
    id: 'barbell_back_squat',
    name: 'Barbell Back Squat',
    muscleIds: const ['quads', 'glutes'],
    category: ExerciseCategory.legs,
  ),
];

Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        defaultAccentOverride,
        exerciseListProvider.overrideWith((ref) => Stream.value(_sample)),
      ],
      child: const MaterialApp(home: ExerciseLibraryScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists every exercise from the provider', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Pull-Up'), findsOneWidget);
    expect(find.text('Barbell Back Squat'), findsOneWidget);
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
}
