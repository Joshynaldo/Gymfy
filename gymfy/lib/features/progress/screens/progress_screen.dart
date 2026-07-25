import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/models/exercise_category.dart';
import '../../../shared/utils/exercise_display.dart';
import '../data/progress_repository.dart';

/// The Progress tab: the exercises you've logged, each opening a progress
/// chart. Only exercises with logged history appear here.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesWithHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
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
          return ListView.separated(
            itemCount: exercises.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return _ExerciseTile(
                name: exercise.name,
                category: exercise.category,
                onTap: () => context.go('/progress/exercise/${exercise.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _ExerciseTile extends ConsumerWidget {
  const _ExerciseTile({
    required this.name,
    required this.category,
    required this.onTap,
  });

  final String name;
  final ExerciseCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: accent.withValues(alpha: 0.15),
        child: Icon(categoryIcon(category), color: accent),
      ),
      title: Text(name),
      trailing: const Icon(Icons.show_chart),
      onTap: onTap,
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
