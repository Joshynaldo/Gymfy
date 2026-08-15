// The 1RM badge on the exercise progress screen: estimate by default, tested
// max when one exists, and an invitation to enter one when there's no history.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/calculator/data/tested_one_rm_repository.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
import 'package:gymfy/features/progress/data/progress_repository.dart';
import 'package:gymfy/features/progress/screens/exercise_progress_screen.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/models/exercise_category.dart';

import 'support/default_accent.dart';

void main() {
  const exerciseId = 'barbell_bench_press';

  final exercise = Exercise(
    id: exerciseId,
    name: 'Barbell Bench Press',
    muscleIds: const ['chest'],
    category: ExerciseCategory.push,
  );

  final history = [
    ExerciseHistoryPoint(
      date: DateTime(2026, 7, 8),
      topWeight: 100,
      repsAtTop: 5,
      totalVolume: 1500,
    ),
  ];

  Future<void> pump(
    WidgetTester tester, {
    required List<ExerciseHistoryPoint> points,
    TestedOneRm? tested,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          defaultAccentOverride,
          defaultWeightUnitOverride,
          exerciseProvider(
            exerciseId,
          ).overrideWith((ref) => Stream.value(exercise)),
          exerciseHistoryProvider(
            exerciseId,
          ).overrideWith((ref) => Stream.value(points)),
          testedOneRmProvider(
            exerciseId,
          ).overrideWith((ref) => Stream.value(tested)),
        ],
        child: const MaterialApp(
          home: ExerciseProgressScreen(exerciseId: exerciseId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('falls back to the estimate when nothing was tested', (
    tester,
  ) async {
    await pump(tester, points: history);

    expect(find.text('Estimated 1RM'), findsOneWidget);
    expect(find.text('≈ 114.5 kg'), findsOneWidget);
    expect(find.textContaining('From 100 kg × 5'), findsOneWidget);
    expect(find.text('Tested 1RM'), findsNothing);
  });

  testWidgets('a tested max wins, with the estimate as a second opinion', (
    tester,
  ) async {
    await pump(
      tester,
      points: history,
      tested: TestedOneRm(
        exerciseId: exerciseId,
        weightKg: 125,
        testedOn: DateTime(2026, 7, 20),
        updatedAt: DateTime(2026, 7, 20),
      ),
    );

    expect(find.text('Tested 1RM'), findsOneWidget);
    expect(find.text('125 kg'), findsOneWidget);
    // The estimate is still shown — if the log outruns the test, retest.
    expect(find.textContaining('log suggests ≈ 114.5 kg'), findsOneWidget);
    expect(find.text('Estimated 1RM'), findsNothing);
  });

  testWidgets('opens the entry dialog when tapped', (tester) async {
    await pump(tester, points: history);

    await tester.tap(find.text('Estimated 1RM'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AlertDialog, 'Tested 1RM'), findsOneWidget);
    // Pre-filled with the estimate, so a close retest is one tap to save.
    expect(find.widgetWithText(TextField, '114.5'), findsOneWidget);
    // Nothing to clear yet.
    expect(find.text('Clear'), findsNothing);
  });
}
