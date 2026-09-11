// The Stats tab's rank section and all-time totals.
//
// The emblems carry meaning that no text on screen repeats — a tier's colour
// and its pip count *are* the ladder — so both are pinned down here. So is the
// overall tier, which is a judgement call rather than a lookup.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/calculator/data/ranked_lifts.dart';
import 'package:gymfy/features/calculator/data/strength_standards.dart';
import 'package:gymfy/features/calculator/data/tier_style.dart';
import 'package:gymfy/features/calculator/widgets/rank_emblem.dart';
import 'package:gymfy/features/home/data/activity_repository.dart';
import 'package:gymfy/features/home/data/recap.dart';
import 'package:gymfy/features/home/data/recap_repository.dart';
import 'package:gymfy/features/muscle_map/data/muscle_fatigue_repository.dart';
import 'package:gymfy/features/muscle_map/data/muscle_volume_repository.dart';
import 'package:gymfy/features/progress/data/measurements_repository.dart';
import 'package:gymfy/features/stats/data/training_totals.dart';
import 'package:gymfy/features/stats/widgets/stats_sections.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/shared/data/lifter_sex.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

RankedLift _lift(String name, StrengthTier tier, {double oneRm = 100}) {
  return (
    exerciseId: name.toLowerCase().replaceAll(' ', '_'),
    name: name,
    oneRm: oneRm,
    tested: false,
    rank: (
      tier: tier,
      next: tier.next,
      ratio: 1.2,
      progressToNext: tier.next == null ? null : 0.4,
      weightToNext: tier.next == null ? null : 12.5,
    ),
  );
}

RecapSet _set(int session, double weight, int reps) => (
  date: DateTime(2026, 8, 20),
  sessionId: session,
  exerciseId: 'barbell_bench_press',
  weight: weight,
  reps: reps,
  muscleIds: const ['chest'],
);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    List<RankedLift> ranked = const [],
    LifterSex? sex = LifterSex.male,
    double? bodyweight = 82,
    List<RecapSet> sets = const [],
    Map<DateTime, int> minutes = const {},
  }) async {
    // Taller than the default so the totals below the body map are laid out.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Not : that bundle already pins the lifter
          // sex, and this test is about varying it.
          defaultAccentOverride,
          defaultWeightUnitOverride,
          lifterSexProvider.overrideWith((ref) => Stream.value(sex)),
          measurementHistoryProvider.overrideWith(
            (ref) => Stream.value([
              if (bodyweight != null)
                BodyMeasurement(
                  id: 1,
                  date: DateTime(2026, 8, 1),
                  weightKg: bodyweight,
                  updatedAt: DateTime(2026, 8, 1),
                ),
            ]),
          ),
          rankedLiftsProvider.overrideWithValue((
            ranked: ranked,
            unlogged: const <String>[],
          )),
          recapSetsProvider.overrideWith((ref) => Stream.value(sets)),
          activityMinutesProvider.overrideWith((ref) => Stream.value(minutes)),
          workoutStreakProvider.overrideWith((ref) => Stream.value(4)),
          weeklyMuscleIntensitiesProvider.overrideWith(
            (ref) => Stream.value(const <String, double>{}),
          ),
          muscleFatigueProvider.overrideWith(
            (ref) => Stream.value(const <String, double>{}),
          ),
        ],
        child: const MaterialApp(
          // The sections directly, now that Progress composes them rather
          // than a screen of their own owning them. Closer to what is under
          // test anyway: these assert on the rank and the totals, not on the
          // scaffolding around them.
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(children: [RankSection(), TotalsSection()]),
            ),
          ),
        ),
      ),
    );
    // Plain pumps: the body SVG is a real asset load the fake clock never
    // advances, so settling would wait forever.
    await tester.pump();
    await tester.pump();
  }

  group('the rank section', () {
    testWidgets('asks for setup rather than ranking on guesses', (
      tester,
    ) async {
      await pump(tester, sex: null, bodyweight: null);

      expect(find.text('Set it up'), findsOneWidget);
      expect(find.byType(RankEmblem), findsNothing);
    });

    testWidgets('draws an emblem per ranked lift, plus one overall', (
      tester,
    ) async {
      await pump(
        tester,
        ranked: [
          _lift('Deadlift', StrengthTier.advanced),
          _lift('Overhead Press', StrengthTier.novice),
        ],
      );

      expect(find.byType(RankEmblem), findsNWidgets(3));
      expect(find.text('Deadlift'), findsOneWidget);
      expect(find.text('Overhead Press'), findsOneWidget);
    });

    testWidgets('overall takes the weakest lift, not the strongest', (
      tester,
    ) async {
      // A single strong deadlift must not crown someone Advanced while their
      // press is Novice. The weakest big lift is the honest one-word answer,
      // and it also points at what to work on.
      await pump(
        tester,
        ranked: [
          _lift('Deadlift', StrengthTier.advanced),
          _lift('Overhead Press', StrengthTier.novice),
        ],
      );

      expect(find.text('Overall'), findsOneWidget);
      final overall = tester.widget<RankEmblem>(find.byType(RankEmblem).first);
      expect(overall.tier, StrengthTier.novice);
      expect(find.textContaining('Your best is advanced'), findsOneWidget);
    });

    testWidgets('says so when every lift sits at the same tier', (
      tester,
    ) async {
      await pump(
        tester,
        ranked: [
          _lift('Deadlift', StrengthTier.intermediate),
          _lift('Bench Press', StrengthTier.intermediate),
        ],
      );

      expect(
        find.textContaining('Every ranked lift is intermediate'),
        findsOneWidget,
      );
      expect(find.textContaining('Your best is'), findsNothing);
    });

    testWidgets('elite has no gap to the next tier to show', (tester) async {
      await pump(tester, ranked: [_lift('Deadlift', StrengthTier.elite)]);

      expect(find.text('Top'), findsOneWidget);
    });
  });

  group('tier styling', () {
    test('every tier has its own colour', () {
      final colors = StrengthTier.values.map(tierColor).toSet();
      expect(colors, hasLength(StrengthTier.values.length));
    });

    test('pips count up with the ladder', () {
      // The colours carry the order for anyone who knows medals, but "is
      // platinum above gold?" is a real question — the pips answer it without
      // a legend.
      expect(tierPips(StrengthTier.beginner), 1);
      expect(tierPips(StrengthTier.elite), StrengthTier.values.length);
      for (final tier in StrengthTier.values) {
        if (tier.next != null) {
          expect(tierPips(tier), lessThan(tierPips(tier.next!)));
        }
      }
    });
  });

  group('all-time totals', () {
    testWidgets('nothing logged shows no totals at all', (tester) async {
      // An all-time panel reading zero across the board is a worse first
      // impression than no panel.
      await pump(tester);

      expect(find.text('All time'), findsNothing);
    });

    testWidgets('counts workouts, sets, volume and days', (tester) async {
      await pump(
        tester,
        sets: [_set(1, 100, 10), _set(1, 100, 8), _set(2, 60, 12)],
        minutes: {DateTime(2026, 8, 20): 65},
      );

      expect(find.text('All time'), findsOneWidget);
      // Two distinct sessions across the three sets.
      expect(find.text('2'), findsWidgets);
      expect(find.text('3'), findsWidgets);
      expect(find.text('4'), findsWidgets); // the streak
      expect(find.text('1 h 05 min'), findsOneWidget);
    });
  });

  group('volumeComparison', () {
    test('says nothing below the smallest thing on the list', () {
      // "0.4 grand pianos" is meaningless and faintly discouraging on day one.
      expect(volumeComparison(100), isNull);
    });

    test('picks the largest comparison that fits', () {
      final small = volumeComparison(1500)!;
      expect(small.label, 'a small car');

      final big = volumeComparison(60000)!;
      expect(big.label, 'a humpback whale');
      expect(big.times, closeTo(2, 0.01));
    });

    test('the list only ever gets heavier', () {
      // The "largest that fits" walk depends on it.
      for (var i = 1; i < volumeComparisons.length; i++) {
        expect(
          volumeComparisons[i].kg,
          greaterThan(volumeComparisons[i - 1].kg),
        );
      }
    });
  });
}
