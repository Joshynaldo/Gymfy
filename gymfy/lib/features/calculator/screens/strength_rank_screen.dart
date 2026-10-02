import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/accent_color.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/data/settings_repository.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/app_card.dart';
import '../data/rank_inputs.dart';
import '../data/ranked_lifts.dart';
import '../widgets/rank_setup_prompt.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';

/// Where your lifts place against published strength standards.
class StrengthRankScreen extends ConsumerWidget {
  const StrengthRankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final inputs = ref.watch(rankInputsProvider);
    final lifts = ref.watch(rankedLiftsProvider);
    final ready = inputs.sex != null && inputs.bodyweightKg != null;

    return GlassScaffold(
      appBar: GlassAppBar(title: Text(l10n.calculatorRankTitle)),
      body: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32) + barInsets(context),
        children: [
          if (!ready)
            RankSetupPrompt(inputs: inputs)
          else ...[
            _Basis(inputs: inputs),
            if (lifts.ranked.isNotEmpty)
              AppSectionHeader(
                title: l10n.calculatorYourLifts,
                count: lifts.ranked.length,
              ),
            for (final lift in lifts.ranked) _LiftCard(lift: lift),
            if (lifts.ranked.isEmpty) const _NothingRankedYet(),
            if (lifts.unlogged.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  l10n.calculatorRankNotLogged(lifts.unlogged.join(', ')),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // A caveat, not a footnote. Someone reading "Novice" next to
            // their best squat deserves to see why that word is softer than
            // it looks, in the same weight as the ranks themselves.
            AppPanel(
              icon: LucideIcons.scale,
              title: l10n.calculatorRankHowToReadTitle,
              child: Text(
                l10n.calculatorRankHowToReadMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
    final l10n = context.l10n;
    final unit = ref.watch(weightUnitProvider);
    final measuredOn = inputs.measuredOn;
    final standards = l10n.calculatorRankStandards(inputs.sex!.name);
    final bodyweight = formatWeightUnit(inputs.bodyweightKg!, unit, l10n: l10n);
    final other = inputs.sex == LifterSex.male
        ? LifterSex.female
        : LifterSex.male;

    return AppPanel(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              measuredOn == null
                  ? l10n.calculatorRankBasis(standards, bodyweight)
                  : l10n.calculatorRankBasisDated(
                      standards,
                      bodyweight,
                      formatShortDate(measuredOn, l10n: l10n),
                    ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            // Switching the table is one tap; nothing else about a rank depends
            // on this setting.
            onPressed: () => ref
                .read(settingsRepositoryProvider)
                .write(lifterSexSetting, other.name),
            child: Text(l10n.calculatorRankUseSex(other.name)),
          ),
        ],
      ),
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
    final l10n = context.l10n;
    final accent = ref.watch(accentColorProvider);
    final unit = ref.watch(weightUnitProvider);
    final rank = lift.rank;
    final next = rank.next;
    final oneRm = formatWeightUnit(lift.oneRm, unit, l10n: l10n);
    final ratio = formatDecimal(rank.ratio, 2, l10n: l10n);

    return AppPanel(
      title: lift.name,
      subtitle: lift.tested
          ? l10n.calculatorLiftTested(oneRm, ratio)
          : l10n.calculatorLiftEstimated(oneRm, ratio),
      trailing: _TierPill(label: rank.tier.localizedLabel(l10n)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                ? l10n.calculatorLiftTopTier
                : l10n.calculatorLiftToNext(
                    formatWeightUnit(rank.weightToNext!, unit, l10n: l10n),
                    next.localizedLabel(l10n),
                  ),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// The tier name, in the accent colour.
class _TierPill extends ConsumerWidget {
  const _TierPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NothingRankedYet extends StatelessWidget {
  const _NothingRankedYet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Column(
      children: [
        const SizedBox(height: 24),
        Icon(
          LucideIcons.medal,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.calculatorNothingRankedTitle,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.calculatorNothingRankedMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
