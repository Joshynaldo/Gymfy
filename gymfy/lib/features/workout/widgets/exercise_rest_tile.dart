import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/accent_color.dart';
import '../../../l10n/l10n.dart';
import '../data/rest_timer_repository.dart';
import 'rest_length_picker.dart';

/// Sets how long to rest between sets of one exercise.
///
/// Shows whether the exercise is following the global default or has its own
/// length, because "1:30" alone doesn't say whether changing the default would
/// move it.
class ExerciseRestTile extends ConsumerWidget {
  const ExerciseRestTile({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = ref.watch(accentColorProvider);
    final override = ref.watch(exerciseRestOverrideProvider(exerciseId)).value;
    final effective = ref.watch(restForExerciseProvider(exerciseId));

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final chosen = await showRestLengthPicker(
            context,
            current: effective,
            title: l10n.workoutRestBetweenSets,
            clearLabel: override == null ? null : l10n.workoutRestUseDefault,
          );
          if (chosen == null) return;

          final repository = ref.read(restTimerRepositoryProvider);
          if (chosen == clearRestLength) {
            await repository.clearForExercise(exerciseId);
          } else {
            await repository.setForExercise(exerciseId, chosen);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(LucideIcons.timer, size: 20, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.workoutRestBetweenSets,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      override == null
                          ? l10n.workoutRestFollowingDefault(
                              formatRest(effective),
                            )
                          : l10n.workoutRestOwn(formatRest(effective)),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
