import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/utils/format.dart';
import '../../exercises/data/exercise_repository.dart';
import '../data/progress_repository.dart';
import '../widgets/exercise_progress_chart.dart';

/// Shows one exercise's progress over time: a chart of top-set weight per
/// session. (Personal records are added in the next task.)
class ExerciseProgressScreen extends ConsumerWidget {
  const ExerciseProgressScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exerciseAsync = ref.watch(exerciseProvider(exerciseId));
    final historyAsync = ref.watch(exerciseHistoryProvider(exerciseId));
    final title = exerciseAsync.value?.name ?? 'Progress';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load progress.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (points) {
          if (points.isEmpty) {
            return const Center(
              child: Text('No logged sessions for this exercise yet.'),
            );
          }
          final records = personalRecordsFrom(points);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (records != null) ...[
                Text('Personal records', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                _RecordsRow(records: records),
                const SizedBox(height: 24),
              ],
              Text('Top-set weight', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'The heaviest set you did each session.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 260,
                child: ExerciseProgressChart(points: points),
              ),
              if (points.length == 1) ...[
                const SizedBox(height: 16),
                Text(
                  'Log this exercise in more sessions to see a trend line.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RecordsRow extends StatelessWidget {
  const _RecordsRow({required this.records});

  final PersonalRecords records;

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight gives the Row a finite height so the tiles can stretch to
    // match each other; without it, `stretch` inside a scrolling list forces an
    // infinite height and the screen fails to lay out.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _RecordTile(
              icon: Icons.fitness_center,
              label: 'Heaviest',
              value: '${formatWeight(records.heaviestWeight)} kg',
              detail: '× ${records.repsAtHeaviest} '
                  '• ${formatShortDate(records.heaviestDate)}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _RecordTile(
              icon: Icons.bar_chart,
              label: 'Best volume',
              value: '${formatWeight(records.bestVolume)} kg',
              detail: 'in a session '
                  '• ${formatShortDate(records.bestVolumeDate)}',
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordTile extends ConsumerWidget {
  const _RecordTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(
            detail,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
