import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/utils/exercise_display.dart';
import '../data/exercise_repository.dart';

/// Full-screen details for a single exercise: an animated GIF preview (when
/// one has been added to assets), the movement category, and the muscles it
/// works.
///
/// The exercise is looked up live by id, so if the underlying row changes the
/// screen updates itself. An unknown id (e.g. a stale deep link) shows a
/// friendly "not found" state rather than crashing.
class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseProvider(exerciseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise')),
      body: exerciseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load this exercise.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (exercise) {
          if (exercise == null) {
            return const Center(child: Text('Exercise not found.'));
          }
          return _ExerciseDetailBody(exercise: exercise);
        },
      ),
    );
  }
}

class _ExerciseDetailBody extends ConsumerWidget {
  const _ExerciseDetailBody({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _GifPreview(gifPath: exercise.gifPath, accent: accent),
        const SizedBox(height: 20),
        Text(exercise.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(categoryIcon(exercise.category), size: 18, color: accent),
            const SizedBox(width: 6),
            Text(
              exercise.category.label,
              style: theme.textTheme.titleMedium?.copyWith(color: accent),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Muscles worked', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final muscleId in exercise.muscleIds)
              Chip(label: Text(muscleLabel(muscleId))),
          ],
        ),
      ],
    );
  }
}

/// Shows the exercise's GIF if the asset exists, otherwise a neutral
/// placeholder. GIF files are added to `assets/exercises/` over time, so a
/// missing file is expected and must not look like an error.
class _GifPreview extends StatelessWidget {
  const _GifPreview({required this.gifPath, required this.accent});

  final String? gifPath;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: gifPath == null
              ? _Placeholder(accent: accent)
              : _AssetGifOrPlaceholder(path: gifPath!, accent: accent),
        ),
      ),
    );
  }
}

/// Loads a GIF asset, falling back to the placeholder if it isn't bundled yet.
///
/// We check the asset manifest first because `Image.asset` throws for a
/// missing asset in a way that can't be caught inline; probing the manifest
/// lets us decide up front.
class _AssetGifOrPlaceholder extends StatelessWidget {
  const _AssetGifOrPlaceholder({required this.path, required this.accent});

  final String path;
  final Color accent;

  Future<bool> _assetExists() async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _assetExists(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        if (snapshot.data != true) {
          return _Placeholder(accent: accent);
        }
        return Image.asset(path, fit: BoxFit.contain);
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 56,
            color: accent.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'Preview coming soon',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
