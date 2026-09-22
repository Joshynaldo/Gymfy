import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/session_length.dart';
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

    // A finished session with nothing in it is not a workout you did — it is a
    // session you started and walked out of, and the card for it reads "Today ·
    // 0 min / 0 sets · 0 kg" beside a body with no muscle lit. That is four
    // zeros and a grey figure telling you nothing, on the most valuable card
    // space in the app.
    if (sets.isEmpty) return const SizedBox.shrink();

    final volume = sets.fold<double>(0, (sum, s) => sum + s.weight * s.reps);
    final completedAt = session.completedAt ?? session.startedAt;
    final length = sessionLength(session.startedAt, session.completedAt);

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
                  // How long it took, beside when it was. The date alone
                  // answers "did I train" and leaves out the half of the
                  // question that is "how much of a session was it" — a
                  // twenty-minute Tuesday and a ninety-minute one are not the
                  // same entry in your week.
                  // An imported session whose file never recorded a length
                  // falls out here rather than reading "16 Sep · 0 min" beside
                  // eighteen sets, which states something false about a
                  // workout that plainly happened.
                  [
                    formatDayLabel(completedAt),
                    if (length != null) formatDuration(length),
                  ].join(' · '),
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
