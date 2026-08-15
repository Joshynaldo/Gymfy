// Ranking a lift by bodyweight ratio: the right tier at every boundary, honest
// progress toward the next one, and nulls instead of guesses.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/calculator/data/strength_rank.dart';
import 'package:gymfy/features/calculator/data/strength_standards.dart';

void main() {
  // Male bench: novice 0.75, intermediate 1.0, advanced 1.5, elite 2.0.
  StrengthRank? bench(double oneRm, {double bodyweight = 80}) {
    return rankFor(
      exerciseId: 'barbell_bench_press',
      sex: LifterSex.male,
      oneRm: oneRm,
      bodyweightKg: bodyweight,
    );
  }

  group('tiers', () {
    test('below the first bar you are still a beginner', () {
      final rank = bench(50)!; // 0.625×
      expect(rank.tier, StrengthTier.beginner);
      expect(rank.next, StrengthTier.novice);
    });

    test('hitting a bar exactly earns the tier', () {
      // 60 / 80 = 0.75, exactly novice.
      expect(bench(60)!.tier, StrengthTier.novice);
      // 80 / 80 = 1.0, exactly intermediate.
      expect(bench(80)!.tier, StrengthTier.intermediate);
    });

    test('a hair under a bar does not earn it', () {
      expect(bench(79.9)!.tier, StrengthTier.novice);
    });

    test('elite has nothing above it', () {
      final rank = bench(170)!; // 2.125×
      expect(rank.tier, StrengthTier.elite);
      expect(rank.next, isNull);
      expect(rank.progressToNext, isNull);
      expect(rank.weightToNext, isNull);
    });

    test('the same lift ranks differently at a different bodyweight', () {
      // 100 kg is intermediate at 80 kg bodyweight, advanced at 65.
      expect(bench(100)!.tier, StrengthTier.intermediate);
      expect(bench(100, bodyweight: 65)!.tier, StrengthTier.advanced);
    });

    test('women are ranked against the women\'s table', () {
      // The very same 0.75× ratio: novice for men, intermediate for women.
      final female = rankFor(
        exerciseId: 'barbell_bench_press',
        sex: LifterSex.female,
        oneRm: 45,
        bodyweightKg: 60,
      )!;
      expect(female.tier, StrengthTier.intermediate);
      expect(bench(60)!.tier, StrengthTier.novice);

      // And 0.95× clears the women's advanced bar (0.9) but not the men's.
      final strong = rankFor(
        exerciseId: 'barbell_bench_press',
        sex: LifterSex.female,
        oneRm: 57,
        bodyweightKg: 60,
      )!;
      expect(strong.tier, StrengthTier.advanced);
      expect(bench(76)!.tier, StrengthTier.novice);
    });
  });

  group('progress toward the next tier', () {
    test('runs from the bar you cleared to the one you are chasing', () {
      // 90 / 80 = 1.125 — a quarter of the way from 1.0 to 1.5.
      final rank = bench(90)!;
      expect(rank.tier, StrengthTier.intermediate);
      expect(rank.progressToNext, closeTo(0.25, 0.001));
    });

    test('a beginner measures from zero, not from a missing bar', () {
      // 30 / 80 = 0.375, half of the 0.75 novice bar.
      expect(bench(30)!.progressToNext, closeTo(0.5, 0.001));
    });

    test('sitting exactly on a bar means starting the next tier fresh', () {
      expect(bench(80)!.progressToNext, closeTo(0.0, 0.001));
    });

    test('says how many kilos are missing', () {
      // Advanced needs 1.5 × 80 = 120 kg.
      expect(bench(90)!.weightToNext, closeTo(30, 0.001));
    });

    test('ratio is reported as lifted over bodyweight', () {
      expect(bench(120)!.ratio, closeTo(1.5, 0.001));
    });
  });

  group('nothing to say', () {
    test('unranked exercises get no rank', () {
      expect(
        rankFor(
          exerciseId: 'dumbbell_lateral_raise',
          sex: LifterSex.male,
          oneRm: 20,
          bodyweightKg: 80,
        ),
        isNull,
      );
    });

    test('a missing bodyweight is not an excuse to invent one', () {
      expect(bench(100, bodyweight: 0), isNull);
      expect(bench(100, bodyweight: -80), isNull);
    });

    test('no one-rep max means no rank', () {
      expect(bench(0), isNull);
    });
  });
}
