import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/exercise_thumbnail.dart';
import '../../../shared/utils/exercise_display.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../data/progress_repository.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';

/// The Progress tab: the exercises you've logged, each opening a progress
/// chart. Only exercises with logged history appear here.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesWithHistoryProvider);

    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text('Progress'),
        actions: [
          // An action rather than a list entry, so it's reachable even when
          // there's no logged history yet and the list shows its empty state.
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Progress photos',
            onPressed: () => context.go('/more/progress/photos'),
          ),
          IconButton(
            icon: const Icon(Icons.straighten),
            tooltip: 'Measurements',
            onPressed: () => context.go('/more/progress/measurements'),
          ),
        ],
      ),
      body: exercisesAsync.when(
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
        data: (exercises) {
          if (exercises.isEmpty) {
            return const _EmptyState();
          }
          return ListView.builder(
            padding:
                const EdgeInsets.only(top: 8, bottom: 24) + barInsets(context),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return FadeSlideIn(
                child: AppTile(
                  icon: exerciseIcon,
                  leading: ExerciseThumbnail(gifPath: exercise.gifPath),
                  title: exercise.name,
                  // A chart icon rather than a chevron: it says what opening
                  // this gets you, which "›" doesn't.
                  trailing: const Icon(Icons.show_chart, size: 20),
                  onTap: () =>
                      context.go('/more/progress/exercise/${exercise.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('No progress yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Log a few workouts and your exercises will show up here with '
              'charts of your progress.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
