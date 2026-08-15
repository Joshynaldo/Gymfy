// The rank screen: asks for missing inputs, ranks what it can, is explicit
// about tested vs estimated maxes, and lists the lifts it has nothing for.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/calculator/data/rank_inputs.dart';
import 'package:gymfy/features/calculator/data/strength_standards.dart';
import 'package:gymfy/features/calculator/data/tested_one_rm_repository.dart';
import 'package:gymfy/features/calculator/screens/strength_rank_screen.dart';
import 'package:gymfy/features/progress/data/measurements_repository.dart';
import 'package:gymfy/features/progress/data/progress_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

void main() {
  ExerciseHistoryPoint set(double weight, int reps) {
    return ExerciseHistoryPoint(
      date: DateTime(2026, 7, 8),
      topWeight: weight,
      repsAtTop: reps,
      totalVolume: weight * reps,
    );
  }

  /// Pumps the screen with every family provider it reaches for overridden, so
  /// no exercise falls through to a real database query.
  Future<void> pump(
    WidgetTester tester, {
    required LifterSex? sex,
    required double? bodyweight,
    Map<String, List<ExerciseHistoryPoint>> history = const {},
    Map<String, double> tested = const {},
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          defaultAccentOverride,
          defaultWeightUnitOverride,
          lifterSexProvider.overrideWith((ref) => Stream.value(sex)),
          latestBodyweightProvider.overrideWith(
            (ref) => bodyweight == null
                ? null
                : (day: DateTime(2026, 7, 20), value: bodyweight),
          ),
          for (final exerciseId in strengthStandards.keys) ...[
            exerciseHistoryProvider(exerciseId).overrideWith(
              (ref) => Stream.value(history[exerciseId] ?? const []),
            ),
            testedOneRmProvider(exerciseId).overrideWith((ref) {
              final weight = tested[exerciseId];
              return Stream.value(
                weight == null
                    ? null
                    : TestedOneRm(
                        exerciseId: exerciseId,
                        weightKg: weight,
                        testedOn: DateTime(2026, 7, 20),
                        updatedAt: DateTime(2026, 7, 20),
                      ),
              );
            }),
          ],
        ],
        child: const MaterialApp(home: StrengthRankScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('asks for setup instead of ranking on guesses', (tester) async {
    await pump(tester, sex: null, bodyweight: null);

    expect(find.text('Before we can rank you'), findsOneWidget);
    expect(find.text('Beginner'), findsNothing);
  });

  testWidgets('ranks a logged lift against the bodyweight ratio', (
    tester,
  ) async {
    await pump(
      tester,
      sex: LifterSex.male,
      bodyweight: 80,
      // 100 kg × 5 estimates ~114.3 kg = 1.43× — intermediate (1.0), not yet
      // advanced (1.5).
      history: {
        'barbell_bench_press': [set(100, 5)],
      },
    );

    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Intermediate'), findsOneWidget);
    expect(find.textContaining('1.43× bodyweight'), findsOneWidget);
    expect(find.textContaining('estimated'), findsOneWidget);
    // Advanced needs 1.5 × 80 = 120 kg, so a few kilos short.
    expect(find.textContaining('to Advanced'), findsOneWidget);
  });

  testWidgets('a tested max is used and labelled as tested', (tester) async {
    await pump(
      tester,
      sex: LifterSex.male,
      bodyweight: 80,
      history: {
        'barbell_bench_press': [set(100, 5)],
      },
      // Beats the estimate and is a fact, so it must win.
      tested: {'barbell_bench_press': 130},
    );

    expect(find.text('Advanced'), findsOneWidget);
    expect(find.textContaining('130 kg tested'), findsOneWidget);
    expect(find.textContaining('estimated'), findsNothing);
  });

  testWidgets('elite has no next tier to chase', (tester) async {
    await pump(
      tester,
      sex: LifterSex.male,
      bodyweight: 80,
      // 2.5× bodyweight squat.
      tested: {'barbell_back_squat': 200},
    );

    expect(find.text('Elite'), findsOneWidget);
    expect(find.text('Top tier — nothing above this'), findsOneWidget);
  });

  testWidgets('the same lift ranks by the women\'s table when chosen', (
    tester,
  ) async {
    await pump(
      tester,
      sex: LifterSex.female,
      bodyweight: 80,
      tested: {'barbell_bench_press': 80}, // 1.0×
    );

    // 1.0× is intermediate on the men's table but clears the women's advanced
    // bar (0.9), short of elite (1.2).
    expect(find.text('Advanced'), findsOneWidget);
    expect(find.text('Intermediate'), findsNothing);
  });

  testWidgets('names the ranked lifts it has nothing for', (tester) async {
    await pump(
      tester,
      sex: LifterSex.male,
      bodyweight: 80,
      history: {
        'barbell_bench_press': [set(100, 5)],
      },
    );

    expect(find.textContaining('Not logged yet'), findsOneWidget);
    expect(find.textContaining('Deadlift'), findsOneWidget);
  });

  testWidgets('nothing logged at all explains itself', (tester) async {
    await pump(tester, sex: LifterSex.male, bodyweight: 80);

    expect(find.text('No ranked lifts yet'), findsOneWidget);
  });
}
