import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/data/settings_repository.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../data/rank_inputs.dart';
import '../data/ranked_lifts.dart';
import '../data/strength_standards.dart';
import '../widgets/rank_setup_prompt.dart';

/// Where your lifts place against published strength standards.
class StrengthRankScreen extends ConsumerWidget {
  const StrengthRankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inputs = ref.watch(rankInputsProvider);
    final lifts = ref.watch(rankedLiftsProvider);
    final ready = inputs.sex != null && inputs.bodyweightKg != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Strength rank')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (!ready)
            RankSetupPrompt(inputs: inputs)
          else ...[
            _Basis(inputs: inputs),
            const SizedBox(height: 16),
            for (final lift in lifts.ranked) ...[
              _LiftCard(lift: lift),
              const SizedBox(height: 12),
            ],
            if (lifts.ranked.isEmpty) const _NothingRankedYet(),
            if (lifts.unlogged.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Not logged yet: ${lifts.unlogged.join(', ')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Standards are population averages from published tables, not '
              'physics. Limb lengths and bodyweight both skew them — treat a '
              'rank as a rough bracket, not a verdict.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// What the ranks are being computed from, and how to change it.
class _Basis extends ConsumerWidget {
  const _Basis({required this.inputs});

  final RankInputs inputs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);
    final measuredOn = inputs.measuredOn;

    return Row(
      children: [
        Expanded(
          child: Text(
            '${inputs.sex!.label} standards • '
            '${formatWeightUnit(inputs.bodyweightKg!, unit)} bodyweight'
            '${measuredOn == null ? '' : ' (${formatShortDate(measuredOn)})'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextButton(
          // Switching the table is one tap; nothing else about a rank depends
          // on this setting.
          onPressed: () => ref.read(settingsRepositoryProvider).write(
            lifterSexSetting,
            inputs.sex == LifterSex.male
                ? LifterSex.female.name
                : LifterSex.male.name,
          ),
          child: Text(
            'Use ${inputs.sex == LifterSex.male ? 'female' : 'male'}',
          ),
        ),
      ],
    );
  }
}

/// One lift: its tier, the ratio behind it, and the gap to the next tier.
class _LiftCard extends ConsumerWidget {
  const _LiftCard({required this.lift});

  final RankedLift lift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final unit = ref.watch(weightUnitProvider);
    final rank = lift.rank;
    final next = rank.next;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(lift.name, style: theme.textTheme.titleSmall),
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
          const SizedBox(height: 4),
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
          const SizedBox(height: 6),
          Text(
            next == null
                ? 'Top tier — nothing above this'
                : '${formatWeightUnit(rank.weightToNext!, unit)} '
                      'to ${next.label}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _NothingRankedYet extends StatelessWidget {
  const _NothingRankedYet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 24),
        Icon(
          Icons.military_tech_outlined,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text('No ranked lifts yet', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Log a set of one of the big barbell lifts — bench, squat, deadlift, '
          'overhead press, row or RDL — and its rank appears here.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
