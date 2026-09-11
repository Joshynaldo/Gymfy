import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../../muscle_map/data/muscle_volume_repository.dart';
import '../../muscle_map/widgets/muscle_map.dart';
import '../../workout/data/session_repository.dart';
import '../../../shared/widgets/app_card.dart';

/// The last workout you finished: when, how much, and which muscles it hit.
///
/// Hidden entirely before the first completed session — a card reading "no
/// workouts yet" on a brand new install adds nothing the empty app doesn't
/// already say.
class LastWorkoutCard extends ConsumerWidget {
  const LastWorkoutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(lastCompletedSessionProvider).value;
    if (session == null) return const SizedBox.shrink();

    return _Body(session: session);
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);
    final sets = ref.watch(sessionSetsProvider(session.id)).value ?? const [];
    final intensities =
        ref.watch(sessionMuscleIntensitiesProvider(session.id)).value ??
        const <String, double>{};

    final volume = sets.fold<double>(0, (sum, s) => sum + s.weight * s.reps);
    final completedAt = session.completedAt ?? session.startedAt;

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.go('/workout/summary/${session.id}'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LAST WORKOUT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(session.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  formatDayLabel(completedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${sets.length} ${sets.length == 1 ? 'set' : 'sets'} • '
                  '${formatWeightUnit(volume, unit)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Front only. The back would double the width for a thumbnail
          // this size, and the point here is recognition — "that was a
          // chest day" — not study.
          SizedBox(
            width: 64,
            child: MuscleMap(side: BodySide.front, intensities: intensities),
          ),
        ],
      ),
    );
  }
}
