import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets/app_picker.dart';
import '../data/logging_preferences.dart';

/// The Settings section for how sets are logged: effort rating and the
/// warm-up ramp.
///
/// Its own widget, in the workout feature, so Settings only has to place it —
/// the keys and their meaning live next to the screens that read them.
class LoggingSettingsPanel extends ConsumerWidget {
  const LoggingSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final mode =
        ref.watch(effortRatingModeProvider).value ?? EffortRatingMode.off;
    final ramp = ref.watch(warmupRampProvider).value ?? defaultWarmupRamp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.workoutLoggingRateTitle,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 10),
              SegmentedButton<EffortRatingMode>(
                segments: [
                  for (final option in EffortRatingMode.values)
                    ButtonSegment(
                      value: option,
                      label: Text(option.localizedLabel(l10n)),
                    ),
                ],
                selected: {mode},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    setEffortRatingMode(ref, selection.first),
              ),
              const SizedBox(height: 10),
              Text(
                switch (mode) {
                  EffortRatingMode.off => l10n.workoutLoggingOffCaption,
                  EffortRatingMode.rpe => l10n.workoutLoggingRpeCaption,
                  EffortRatingMode.rir => l10n.workoutLoggingRirCaption,
                },
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(LucideIcons.footprints),
          title: Text(l10n.workoutWarmupRampTitle),
          subtitle: Text(
            l10n.workoutWarmupRampSubtitle(formatWarmupRamp(ramp)),
          ),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () async {
            final picked = await showOptionPicker<String>(
              context: context,
              title: l10n.workoutWarmupRampTitle,
              options: [
                for (final preset in warmupRampPresets)
                  (
                    value: encodeWarmupRamp(preset),
                    label: formatWarmupRamp(preset),
                    subtitle: l10n.workoutWarmupRampSteps(preset.length),
                  ),
              ],
              selected: encodeWarmupRamp(ramp),
            );
            if (picked == null) return;
            await setWarmupRamp(ref, parseWarmupRamp(picked));
          },
        ),
      ],
    );
  }
}
