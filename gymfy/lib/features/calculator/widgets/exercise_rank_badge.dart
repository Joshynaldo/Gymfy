import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/utils/units.dart';
import '../data/rank_inputs.dart';
import '../data/ranked_lifts.dart';
import '../data/strength_standards.dart';

/// The strength rank for one exercise, sized to sit inside another screen.
///
/// Renders nothing at all for exercises with no published standards, or for
/// ranked lifts with nothing logged yet — the exercise detail screen shouldn't
/// grow an empty box for the many exercises this can't speak to.
///
/// The one case worth a nudge is a ranked lift where only the setup is missing:
/// there is real data to show and one answer unlocks it, so we say so and link
/// to the rank screen where that ask already lives.
class ExerciseRankBadge extends ConsumerWidget {
  const ExerciseRankBadge({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasStrengthStandard(exerciseId)) return const SizedBox.shrink();

    final inputs = ref.watch(rankInputsProvider);
    if (inputs.sex == null || inputs.bodyweightKg == null) {
      return const _SetupNudge();
    }

    final lift = ref.watch(exerciseRankProvider(exerciseId));
    if (lift == null) return const SizedBox.shrink();

    return _RankCard(lift: lift);
  }
}

class _RankCard extends ConsumerWidget {
  const _RankCard({required this.lift});

  final RankedLift lift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final unit = ref.watch(weightUnitProvider);
    final rank = lift.rank;
    final next = rank.next;

    return _Shell(
      // Tapping through to the full screen puts this lift in context against
      // the others, which is the obvious next question.
      onTap: () => context.go('/more/rank'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.military_tech_outlined, size: 20, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Your rank', style: theme.textTheme.titleSmall),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  rank.tier.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${formatWeightUnit(lift.oneRm, unit)} '
            '${lift.tested ? 'tested' : 'estimated'} • '
            '${rank.ratio.toStringAsFixed(2)}× bodyweight',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              // Elite has nothing above it, so the bar reads full rather than
              // empty — there's no progress left to make.
              value: rank.progressToNext ?? 1,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            next == null
                ? 'Top tier — nothing above this'
                : '${formatWeightUnit(rank.weightToNext!, unit)} '
                      'to ${next.label}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when this lift could be ranked but we don't know the lifter yet.
class _SetupNudge extends ConsumerWidget {
  const _SetupNudge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);

    return _Shell(
      onTap: () => context.go('/more/rank'),
      child: Row(
        children: [
          Icon(Icons.military_tech_outlined, size: 20, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This lift can be ranked', style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'Add your bodyweight and pick a standards table to see where '
                  'you sit.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// Shared tappable surface so the rank and the nudge look like one thing.
///
/// Owns the gap below itself, so a hidden badge collapses cleanly instead of
/// leaving a double gap in whatever list it was dropped into.
class _Shell extends StatelessWidget {
  const _Shell({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }
}
