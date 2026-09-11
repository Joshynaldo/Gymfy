// The rank badge on the exercise detail screen: silent for exercises it can't
// speak to, explicit about tested vs estimated, and nudging only when the one
// missing thing is setup.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/calculator/data/rank_inputs.dart';
import 'package:gymfy/features/calculator/data/tested_one_rm_repository.dart';
import 'package:gymfy/features/calculator/widgets/exercise_rank_badge.dart';
import 'package:gymfy/features/progress/data/measurements_repository.dart';
import 'package:gymfy/features/progress/data/progress_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/units.dart';

import 'support/default_accent.dart';

void main() {
  const bench = 'barbell_bench_press';

  ExerciseHistoryPoint set(double weight, int reps) {
    return ExerciseHistoryPoint(
      date: DateTime(2026, 7, 8),
      topWeight: weight,
      repsAtTop: reps,
      totalVolume: weight * reps,
    );
  }

  /// Pumps just the badge with every provider it can reach overridden, so no
  /// exercise falls through to a real database query.
  Future<void> pump(
    WidgetTester tester, {
    String exerciseId = bench,
    LifterSex? sex = LifterSex.male,
    double? bodyweight = 80,
    List<ExerciseHistoryPoint> history = const [],
    double? tested,
    WeightUnit unit = WeightUnit.kg,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          defaultAccentOverride,
          storedWeightUnitProvider.overrideWith((ref) => Stream.value(unit)),
          lifterSexProvider.overrideWith((ref) => Stream.value(sex)),
          latestBodyweightProvider.overrideWith(
            (ref) => bodyweight == null
                ? null
                : (day: DateTime(2026, 7, 20), value: bodyweight),
          ),
          exerciseHistoryProvider(
            exerciseId,
          ).overrideWith((ref) => Stream.value(history)),
          testedOneRmProvider(exerciseId).overrideWith(
            (ref) => Stream.value(
              tested == null
                  ? null
                  : TestedOneRm(
                      exerciseId: exerciseId,
                      weightKg: tested,
                      testedOn: DateTime(2026, 7, 20),
                      updatedAt: DateTime(2026, 7, 20),
                    ),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: ExerciseRankBadge(exerciseId: exerciseId)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('stays out of the way for an exercise with no standards', (
    tester,
  ) async {
    await pump(
      tester,
      exerciseId: 'dumbbell_lateral_raise',
      history: [set(12, 10)],
    );

    expect(find.text('Your rank'), findsNothing);
    expect(find.text('This lift can be ranked'), findsNothing);
  });

  testWidgets('nudges when only the setup is missing', (tester) async {
    await pump(tester, sex: null, bodyweight: null, history: [set(100, 5)]);

    expect(find.text('This lift can be ranked'), findsOneWidget);
    expect(find.text('Your rank'), findsNothing);
  });

  testWidgets('nudges when the bodyweight alone is missing', (tester) async {
    await pump(tester, bodyweight: null, history: [set(100, 5)]);

    expect(find.text('This lift can be ranked'), findsOneWidget);
  });

  testWidgets('says nothing when a ranked lift has never been logged', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Your rank'), findsNothing);
    expect(find.text('This lift can be ranked'), findsNothing);
  });

  testWidgets('shows the tier and what is left to the next one', (
    tester,
  ) async {
    // 100 kg x 5 estimates ~114.5 kg; at 80 kg bodyweight that is 1.43x, which
    // clears the male intermediate bar (1.0x) but not advanced (1.5x).
    await pump(tester, history: [set(100, 5)]);

    expect(find.text('Your rank'), findsOneWidget);
    expect(find.text('Intermediate'), findsOneWidget);
    expect(find.textContaining('estimated'), findsOneWidget);
    expect(find.textContaining('1.43× bodyweight'), findsOneWidget);
    expect(find.textContaining('to Advanced'), findsOneWidget);
  });

  testWidgets('shows the same rank in pounds when that is the unit', (
    tester,
  ) async {
    // The same 100 kg × 5 as above. 114.5 kg is 252 lbs.
    await pump(tester, history: [set(100, 5)], unit: WeightUnit.lbs);

    expect(find.textContaining('252 lbs'), findsOneWidget);
    expect(find.textContaining('kg'), findsNothing);
    // The ratio is unit-free, so it must not move — this is the check that
    // catches a conversion accidentally applied to the bodyweight ratio.
    expect(find.textContaining('1.43× bodyweight'), findsOneWidget);
    expect(find.text('Intermediate'), findsOneWidget);
  });

  testWidgets('prefers a tested max and labels it as tested', (tester) async {
    await pump(tester, history: [set(100, 5)], tested: 130);

    expect(find.text('Advanced'), findsOneWidget);
    expect(find.textContaining('130 kg tested'), findsOneWidget);
    expect(find.textContaining('estimated'), findsNothing);
  });

  testWidgets('elite has nothing left to chase', (tester) async {
    await pump(tester, tested: 170);

    expect(find.text('Elite'), findsOneWidget);
    expect(find.text('Top tier — nothing above this'), findsOneWidget);
    expect(find.textContaining('kg to '), findsNothing);
  });

  testWidgets('the same lift ranks higher against the women\'s table', (
    tester,
  ) async {
    await pump(tester, sex: LifterSex.female, tested: 130);

    // 1.63x clears the female elite bar (1.2x) where the male table calls it
    // advanced.
    expect(find.text('Elite'), findsOneWidget);
    expect(find.text('Advanced'), findsNothing);
  });
}
