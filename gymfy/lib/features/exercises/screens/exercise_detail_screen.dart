import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/models/exercise.dart' show isBundledAsset;
import '../../../shared/utils/exercise_display.dart';
import '../../calculator/widgets/exercise_rank_badge.dart';
import '../../workout/widgets/exercise_rest_tile.dart';
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
    // Read off the AsyncValue rather than nesting the Scaffold inside `.when`,
    // so the app bar doesn't flicker in and out while the row loads.
    final exercise = exerciseAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise'),
        actions: [
          // Built-in exercises are re-seeded from code on every launch, so an
          // edit to one would silently vanish on the next start. Offering the
          // menu only for custom rows is the honest version of that.
          if (exercise != null && exercise.isCustom)
            _CustomExerciseMenu(exercise: exercise),
        ],
      ),
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

/// Edit / delete for a user-created exercise.
class _CustomExerciseMenu extends ConsumerWidget {
  const _CustomExerciseMenu({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (value) => value == 'edit'
          ? context.go('/exercises/${exercise.id}/edit')
          : _confirmDelete(context, ref),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(exerciseRepositoryProvider);
    // Asked up front so the dialog can say what will actually happen, rather
    // than warning about history that may not exist.
    final hasHistory = await repository.hasHistory(exercise.id);
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${exercise.name}?'),
        content: Text(
          hasHistory
              ? 'It will be removed from your library and from every picker. '
                    'Workouts you already logged with it keep their sets.'
              : 'It has never been logged, so it will be removed completely.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final archived = await repository.deleteCustom(exercise);
    router.go('/exercises');
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          archived
              ? '${exercise.name} removed — past workouts kept it'
              : '${exercise.name} deleted',
        ),
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
        const SizedBox(height: 24),
        // Renders nothing at all for the many exercises with no published
        // standards, and carries its own bottom spacing so it leaves no gap
        // behind when it does.
        ExerciseRankBadge(exerciseId: exercise.id),
        ExerciseRestTile(exerciseId: exercise.id),
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
          child: switch (gifPath) {
            null => _Placeholder(accent: accent),
            // A custom exercise's image is a file the user picked, not
            // something bundled at build time.
            final path when !isBundledAsset(path) => Image.file(
              File(path),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => _Placeholder(accent: accent),
            ),
            final path => _AssetGifOrPlaceholder(path: path, accent: accent),
          },
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
