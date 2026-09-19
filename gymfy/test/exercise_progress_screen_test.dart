// Regression test: the exercise progress screen must lay out and render its
// records + chart without throwing (an earlier version crashed on an infinite
// height from a stretch Row inside the scrolling list).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
import 'package:gymfy/features/progress/data/progress_repository.dart';
import 'package:gymfy/features/progress/screens/exercise_progress_screen.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

void main() {
  testWidgets('renders records and chart for an exercise with history', (
    tester,
  ) async {
    final exercise = Exercise(
      id: 'barbell_back_squat',
      name: 'Barbell Back Squat',
      muscleIds: const ['quads'],
      isPlateLoaded: false,
      isCustom: false,
      isArchived: false,
  isTimed: false,
  equipment: 'other',
    );
    final points = [
      ExerciseHistoryPoint(
        date: DateTime(2026, 1, 1),
        topWeight: 100,
        repsAtTop: 5,
        totalVolume: 1500,
      ),
      ExerciseHistoryPoint(
        date: DateTime(2026, 1, 8),
        topWeight: 110,
        repsAtTop: 3,
        totalVolume: 1200,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          defaultAccentOverride,
          exerciseProvider(
            'barbell_back_squat',
          ).overrideWith((ref) => Stream.value(exercise)),
          exerciseHistoryProvider(
            'barbell_back_squat',
          ).overrideWith((ref) => Stream.value(points)),
        ],
        child: const MaterialApp(
          home: ExerciseProgressScreen(exerciseId: 'barbell_back_squat'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Personal records'), findsOneWidget);
    expect(find.text('Top-set weight'), findsOneWidget);
    // Heaviest PR value shown.
    expect(find.text('110 kg'), findsOneWidget);
  });
}
