import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../exercises/data/exercise_seed_data.dart';
import '../../progress/data/progress_repository.dart';
import 'rank_inputs.dart';
import 'strength_rank.dart';
import 'strength_standards.dart';
import 'tested_one_rm_repository.dart';

/// One ranked lift, ready to render.
typedef RankedLift = ({
  String exerciseId,
  String name,
  double oneRm,

  /// True when [oneRm] is a max the user tested, false when it's estimated
  /// from logged sets. The screen says which, so a rank built on a guess is
  /// never mistaken for one built on a test.
  bool tested,
  StrengthRank rank,
});

/// Ranked lifts plus the ones that can't be ranked yet.
typedef RankedLifts = ({
  /// Strongest tier first — the interesting read is which lift lags.
  List<RankedLift> ranked,

  /// Names of ranked exercises with no 1RM to go on yet.
  List<String> unlogged,
});

/// Display name for a seeded exercise id, falling back to the id itself if the
/// seed data ever loses it.
String exerciseNameFor(String exerciseId) {
  for (final exercise in exerciseSeedData) {
    if (exercise.id.value == exerciseId) return exercise.name.value;
  }
  return exerciseId;
}

/// Ranks a single exercise, or returns null when it can't be ranked yet —
/// no strength standards for it, no sex or bodyweight on file, or no logged
/// set to work from.
///
/// Uses the tested one-rep max where the user entered one and the estimate from
/// logged sets otherwise — the same precedence the badge on the progress screen
/// uses, so the two never disagree.
///
/// Both the rank screen and the badge on the exercise detail screen read this,
/// so a lift can't show one tier in one place and another elsewhere.
final exerciseRankProvider = Provider.family<RankedLift?, String>((
  ref,
  exerciseId,
) {
  final inputs = ref.watch(rankInputsProvider);
  final sex = inputs.sex;
  final bodyweight = inputs.bodyweightKg;
  if (sex == null || bodyweight == null) return null;
  if (!hasStrengthStandard(exerciseId)) return null;

  final tested = ref.watch(testedOneRmProvider(exerciseId)).value;
  final history = ref.watch(exerciseHistoryProvider(exerciseId)).value;
  final estimate = bestEstimatedOneRm(history ?? const []);

  final oneRm = tested?.weightKg ?? estimate?.oneRm;
  if (oneRm == null) return null;

  final rank = rankFor(
    exerciseId: exerciseId,
    sex: sex,
    oneRm: oneRm,
    bodyweightKg: bodyweight,
  );
  if (rank == null) return null;

  return (
    exerciseId: exerciseId,
    name: exerciseNameFor(exerciseId),
    oneRm: oneRm,
    tested: tested != null,
    rank: rank,
  );
});

/// Ranks every lift that has strength standards.
///
/// Returns empty lists when the lifter's sex or bodyweight is unknown; the
/// screen shows [RankSetupPrompt] in that case rather than a partial answer.
final rankedLiftsProvider = Provider<RankedLifts>((ref) {
  final inputs = ref.watch(rankInputsProvider);
  if (inputs.sex == null || inputs.bodyweightKg == null) {
    return (ranked: const [], unlogged: const []);
  }

  final ranked = <RankedLift>[];
  final unlogged = <String>[];

  for (final exerciseId in strengthStandards.keys) {
    final lift = ref.watch(exerciseRankProvider(exerciseId));
    if (lift == null) {
      unlogged.add(exerciseNameFor(exerciseId));
      continue;
    }
    ranked.add(lift);
  }

  ranked.sort((a, b) {
    final byTier = b.rank.tier.index.compareTo(a.rank.tier.index);
    if (byTier != 0) return byTier;
    // Within a tier, whoever is closer to promotion goes first.
    return (b.rank.progressToNext ?? 1).compareTo(a.rank.progressToNext ?? 1);
  });
  unlogged.sort();

  return (ranked: ranked, unlogged: unlogged);
});
