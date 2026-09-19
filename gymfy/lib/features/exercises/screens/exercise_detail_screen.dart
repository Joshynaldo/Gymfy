import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/models/exercise.dart' show isBundledAsset;
import '../../../shared/utils/exercise_display.dart';
import '../../../shared/widgets/app_card.dart';
import '../../calculator/widgets/exercise_rank_badge.dart';
import '../../workout/widgets/exercise_rest_tile.dart';
import '../../../shared/utils/exercise_preview.dart';
import '../data/exercise_repository.dart';
import '../widgets/exercise_note.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../../../shared/widgets/exercise_thumbnail.dart';

/// Opens the exercise detail screen over the current screen.
///
/// A push rather than a route change, so it comes back to wherever it was
/// opened from. That matters during a workout: `go('/exercises/<id>')` would
/// switch to the Exercises tab, and getting back to the session you are
/// halfway through would be the user's problem. Same reasoning as
/// [showPlateCalculator].
Future<void> showExerciseDetail(BuildContext context, String exerciseId) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (context) => ExerciseDetailScreen(exerciseId: exerciseId),
    ),
  );
}

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

    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text('Exercise'),
        actions: [
          // Built-in exercises are re-seeded from code on every launch, so an
          // edit to one would silently vanish on the next start. Offering the
          // menu only for custom rows is the honest version of that.
          if (exercise != null && exercise.isCustom)
            _CustomExerciseMenu(exercise: exercise),
        ],
      ),
      body: (context) => exerciseAsync.when(
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
      builder: (context) => GlassDialog(
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
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 32) + barInsets(context),
      children: [
        // The preview sits in a panel like everything else, so the screen
        // reads as one stack of surfaces rather than a picture with loose
        // text underneath it.
        AppPanel(
          // Fourteen of glass all the way round a square still. The frame is
          // what makes the animation part of the surface rather than a
          // picture that happens to be on the screen — and square, because
          // the stills are square and letterboxing one inside a wide panel
          // leaves two dead strips doing nothing.
          padding: const EdgeInsets.all(14),
          child: AspectRatio(
            aspectRatio: 1,
            child: _GifPreview(
              gifPath: exercise.gifPath,
              accent: accent,
              exerciseId: exercise.id,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
          child: Text(
            exercise.name,
            // The subject of the screen, at the size the scale reserves for
            // exactly that. Not the 28px of a headline number: this is a
            // name, and names read badly when they are set as figures.
            style: theme.textTheme.titleLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
          child: Text(
            exercise.muscleIds.map(muscleLabel).join(' · '),
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 10),
        // Above the rank and the rest timer: the note is the one thing here
        // you wrote yourself, and on a machine lift it is the reason you
        // opened this screen at all.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: ExerciseNoteTile(exercise: exercise),
        ),
        // Renders nothing at all for the many exercises with no published
        // standards, and carries its own bottom spacing so it leaves no gap
        // behind when it does.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ExerciseRankBadge(exerciseId: exercise.id),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ExerciseRestTile(exerciseId: exercise.id),
        ),
        AppPanel(
          icon: Icons.accessibility_new,
          title: 'Muscles worked',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final muscleId in exercise.muscleIds)
                AppChip(
                  label: muscleLabel(muscleId),
                  selected: false,
                  onTap: null,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shows the exercise's GIF if the asset exists, otherwise a neutral
/// placeholder. GIF files are added to `assets/exercises/` over time, so a
/// missing file is expected and must not look like an error.
class _GifPreview extends StatelessWidget {
  const _GifPreview({
    required this.gifPath,
    required this.accent,
    required this.exerciseId,
  });

  final String? gifPath;
  final Color accent;

  /// Matches the still in the library list, so the image the row showed is the
  /// image that lands here.
  final String exerciseId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 1,
      // Square at both ends, so the flight up from the library row is a clean
      // scale rather than a stretch. The Hero sits inside the AspectRatio so
      // the box it flies to is the one the layout has already settled on.
      child: Hero(
        tag: exerciseHeroTag(exerciseId),
        child: DecoratedBox(
          // A faint tint rather than `surfaceContainerHighest`: this now sits
          // inside a card, and the old fill made it a second, slightly different
          // surface stacked on the first.
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }
}

/// Loads the bundled animation, falling back to the placeholder if this
/// exercise doesn't have one yet.
///
/// We check the asset manifest first because `Image.asset` throws for a
/// missing asset in a way that can't be caught inline; probing the manifest
/// lets us decide up front. Both the WebP and the GIF spelling are tried —
/// see [previewCandidates].
class _AssetGifOrPlaceholder extends StatelessWidget {
  const _AssetGifOrPlaceholder({required this.path, required this.accent});

  final String path;
  final Color accent;

  /// The first candidate that is actually bundled, or null for none.
  Future<String?> _bundled() async {
    for (final candidate in previewCandidates(path)) {
      try {
        await rootBundle.load(candidate);
        return candidate;
      } catch (_) {
        // Not bundled. Expected — most projects ship one format, not both.
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _bundled(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final asset = snapshot.data;
        if (asset == null) return _Placeholder(accent: accent);
        return Image.asset(
          asset,
          fit: BoxFit.contain,
          // The bundled animations are small — 128px for the WebP set — and
          // are drawn into a box several times that. Without this the upscale
          // is done with nearest-neighbour and the limbs come out visibly
          // stepped.
          filterQuality: FilterQuality.medium,
        );
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
