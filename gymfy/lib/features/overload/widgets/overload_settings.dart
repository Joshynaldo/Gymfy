import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/utils/units.dart';
import '../data/overload_math.dart';
import '../data/overload_preference.dart';
import '../data/percent_target.dart';

/// The whole progressive-overload configuration, in one panel.
///
/// Used verbatim by both Settings and the onboarding step. One widget rather
/// than two look-alikes: the two would drift the first time an option was added,
/// and then the app would be explaining the same feature two different ways.
class OverloadSettingsPanel extends ConsumerWidget {
  const OverloadSettingsPanel({super.key, this.showDeload = true});

  /// Deload is the one genuinely advanced option here. Onboarding leaves it out
  /// — it's a question about month three, asked before workout one.
  final bool showDeload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final unit = ref.watch(weightUnitProvider);
    final config = ref.watch(overloadConfigProvider);

    void update(OverloadConfig next) => setOverloadConfig(ref, next);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.overloadSuggestTitle),
          subtitle: Text(l10n.overloadSuggestSubtitle),
          value: config.enabled,
          onChanged: (value) => update(config.copyWith(enabled: value)),
        ),
        // Everything below is meaningless while suggestions are off, and a
        // greyed-out wall of controls is worse than none.
        if (config.enabled) ...[
          const SizedBox(height: 12),
          Text(l10n.overloadHowMuchTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<OverloadMode>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              for (final mode in OverloadMode.values)
                ButtonSegment(
                  value: mode,
                  label: Text(mode.localizedLabel(l10n)),
                ),
            ],
            selected: {config.mode},
            onSelectionChanged: (selection) =>
                update(config.copyWith(mode: selection.first)),
          ),
          const SizedBox(height: 8),
          _ModeDetail(config: config, unit: unit, onChanged: update),
          if (showDeload) ...[
            const SizedBox(height: 20),
            Text(l10n.overloadDeloadTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              l10n.overloadDeloadCaption,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                AppChip(
                  label: l10n.overloadDeloadNever,
                  selected: config.deloadWeeks == null,
                  onTap: () => update(config.copyWith(clearDeload: true)),
                ),
                for (final weeks in overloadDeloadOptions)
                  AppChip(
                    label: l10n.overloadDeloadInARow(weeks),
                    selected: config.deloadWeeks == weeks,
                    onTap: () => update(config.copyWith(deloadWeeks: weeks)),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

/// The chips and explanation for whichever mode is selected.
class _ModeDetail extends StatelessWidget {
  const _ModeDetail({
    required this.config,
    required this.unit,
    required this.onChanged,
  });

  final OverloadConfig config;
  final WeightUnit unit;
  final ValueChanged<OverloadConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final caption = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return switch (config.mode) {
      // Nothing to choose — the point of Auto is that the app already knows a
      // squat isn't a lateral raise.
      OverloadMode.auto => Text(
        l10n.overloadAutoCaption(
          formatWeightUnit(5, unit, l10n: l10n),
          formatWeightUnit(2.5, unit, l10n: l10n),
          formatWeightUnit(1.25, unit, l10n: l10n),
        ),
        style: caption,
      ),
      OverloadMode.fixed => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final step in overloadFixedSteps)
                AppChip(
                  label: formatWeightUnit(step, unit, l10n: l10n),
                  selected: config.fixedKg == step,
                  onTap: () => onChanged(config.copyWith(fixedKg: step)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(l10n.overloadFixedCaption, style: caption),
        ],
      ),
      OverloadMode.percent => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final step in overloadPercentSteps)
                AppChip(
                  label: formatPercent(step, l10n: l10n),
                  selected: config.percent == step,
                  onTap: () => onChanged(config.copyWith(percent: step)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            // Concrete beats abstract: "2.5%" means nothing until you see what
            // it does to a weight you actually lift.
            _percentExample(config.percent, unit, l10n),
            style: caption,
          ),
        ],
      ),
    };
  }
}

/// Spells a percentage out against two real weights.
String _percentExample(double percent, WeightUnit unit, AppLocalizations l10n) {
  final light = weightToKilograms(40, unit);
  final heavy = weightToKilograms(100, unit);
  return l10n.overloadPercentExample(
    formatWeightUnit(light * percent / 100, unit, l10n: l10n),
    formatWeightUnit(light, unit, l10n: l10n),
    formatWeightUnit(heavy * percent / 100, unit, l10n: l10n),
    formatWeightUnit(heavy, unit, l10n: l10n),
  );
}

/// Kept here so the panel and the maths stay in step: both need to know that
/// core work is never auto-progressed.
bool exerciseCanProgress(List<String> muscleIds) =>
    defaultIncrementKg(muscleIds) != null;
