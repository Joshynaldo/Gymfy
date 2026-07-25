// Material exports an animation curve also named `Split`; hide it so `Split`
// here unambiguously means our Drift row class.
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/widgets/name_prompt_dialog.dart';
import '../data/workout_repository.dart';

/// The Workout tab. For now it's the home of your training *plans*: a list of
/// splits with a button to create a new one. Tapping a split will open its
/// overview (days + exercises) once that screen is built later in Phase 3.
class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitsAsync = ref.watch(splitListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Splits')),
      body: splitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load your splits.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (splits) {
          if (splits.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            itemCount: splits.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _SplitTile(split: splits[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSplitDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New split'),
      ),
    );
  }
}

/// Prompts for a split name and creates it. Does nothing if the name is blank.
Future<void> _showCreateSplitDialog(BuildContext context, WidgetRef ref) async {
  final name = await showNamePromptDialog(
    context,
    title: 'New split',
    label: 'Split name',
    hint: 'e.g. Push / Pull / Legs',
  );
  if (name == null) return;

  await ref.read(workoutRepositoryProvider).createSplit(name);
}

class _SplitTile extends ConsumerWidget {
  const _SplitTile({required this.split});

  final Split split;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: accent.withValues(alpha: 0.15),
        child: Icon(Icons.calendar_view_week, color: accent),
      ),
      title: Text(split.name),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Delete split',
        onPressed: () => _confirmDelete(context, ref, split),
      ),
      onTap: () => context.go('/workout/split/${split.id}'),
    );
  }
}

/// Confirms then deletes a split (cascading to its days/exercises).
Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  Split split,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Delete "${split.name}"?'),
        content: const Text(
          'This removes the split and everything inside it. This cannot be '
          'undone.',
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
      );
    },
  );

  if (confirmed != true) return;

  await ref.read(workoutRepositoryProvider).deleteSplit(split.id);
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
              Icons.calendar_view_week,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('No splits yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Create your first split to start planning your training.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
