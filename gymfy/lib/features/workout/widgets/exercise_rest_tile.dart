import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
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
            title: 'Rest between sets',
            clearLabel: override == null ? null : 'Use the default instead',
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
              Icon(Icons.timer_outlined, size: 20, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rest between sets', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      override == null
                          ? '${formatRest(effective)} — following the default'
                          : '${formatRest(effective)} — set for this exercise',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
