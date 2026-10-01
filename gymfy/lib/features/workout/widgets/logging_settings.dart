import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                'Rate how hard each set was',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 10),
              SegmentedButton<EffortRatingMode>(
                segments: [
                  for (final option in EffortRatingMode.values)
                    ButtonSegment(value: option, label: Text(option.label)),
                ],
                selected: {mode},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    setEffortRatingMode(ref, selection.first),
              ),
              const SizedBox(height: 10),
              Text(
                switch (mode) {
                  EffortRatingMode.off =>
                    'Off: the log sheet asks for weight and reps only.',
                  EffortRatingMode.rpe =>
                    'RPE 6–10, optional on every working set. A top set rated '
                        '9.5 or 10 holds the overload suggestion at the same '
                        'weight next time.',
                  EffortRatingMode.rir =>
                    'Reps left in the tank, optional on every working set. A '
                        'top set with none left holds the overload suggestion '
                        'at the same weight next time.',
                },
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.stairs_outlined),
          title: const Text('Warm-up ramp'),
          subtitle: Text(
            '${formatWarmupRamp(ramp)} of your working weight, after the bar',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final picked = await showOptionPicker<String>(
              context: context,
              title: 'Warm-up ramp',
              options: [
                for (final preset in warmupRampPresets)
                  (
                    value: encodeWarmupRamp(preset),
                    label: formatWarmupRamp(preset),
                    subtitle: '${preset.length} steps',
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
