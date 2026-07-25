import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/utils/dates.dart';
import '../../../shared/widgets/name_prompt_dialog.dart';
import '../data/habit_repository.dart';

/// The habit tracker: a daily checklist of habits, each with a streak counter.
/// Checking a habit records it as done today; unchecking removes it.
class HabitTrackerScreen extends ConsumerWidget {
  const HabitTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusesAsync = ref.watch(habitTodayStatusesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      body: statusesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load your habits.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (statuses) {
          if (statuses.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            itemCount: statuses.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _HabitTile(status: statuses[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addHabit(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New habit'),
      ),
    );
  }

  Future<void> _addHabit(BuildContext context, WidgetRef ref) async {
    final name = await showNamePromptDialog(
      context,
      title: 'New habit',
      label: 'Habit',
      hint: 'e.g. Drink 3L water',
    );
    if (name == null) return;
    await ref.read(habitRepositoryProvider).createHabit(name);
  }
}

class _HabitTile extends ConsumerWidget {
  const _HabitTile({required this.status});

  final HabitStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);

    return ListTile(
      leading: Checkbox(
        value: status.doneToday,
        activeColor: accent,
        onChanged: (checked) => ref.read(habitRepositoryProvider).setDone(
          status.habit.id,
          dateOnly(DateTime.now()),
          checked ?? false,
        ),
      ),
      title: Text(status.habit.name),
      subtitle: Text(
        status.streak > 0
            ? '🔥 ${status.streak} day streak'
            : 'No streak yet',
        style: theme.textTheme.bodySmall?.copyWith(
          color: status.streak > 0 ? accent : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Delete habit',
        onPressed: () => _confirmDelete(context, ref),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${status.habit.name}"?'),
        content: const Text(
          'This removes the habit and its history. This cannot be undone.',
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

    if (confirmed != true) return;
    await ref.read(habitRepositoryProvider).deleteHabit(status.habit.id);
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
              Icons.checklist,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('No habits yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Add a daily habit to start building streaks.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
