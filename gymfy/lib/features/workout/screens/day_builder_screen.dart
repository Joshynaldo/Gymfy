import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/utils/exercise_display.dart';
import '../data/session_repository.dart';
import '../data/workout_repository.dart';
import 'widgets/exercise_picker.dart';

/// The day builder: the exercises planned for one day, each with default
/// sets × reps. You can add exercises from the library, edit their targets,
/// and remove them.
class DayBuilderScreen extends ConsumerWidget {
  const DayBuilderScreen({super.key, required this.dayId});

  final int dayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayAsync = ref.watch(dayProvider(dayId));
    final exercisesAsync = ref.watch(dayExercisesProvider(dayId));

    final title = dayAsync.value?.name ?? 'Day';
    final hasExercises = (exercisesAsync.value?.isNotEmpty) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // Starting a workout only makes sense once the day has exercises.
          if (hasExercises)
            TextButton.icon(
              onPressed: () => _startWorkout(context, ref, title),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start'),
            ),
        ],
      ),
      body: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load this day.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (planned) {
          if (planned.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            itemCount: planned.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _PlannedExerciseTile(planned: planned[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addExercise(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add exercise'),
      ),
    );
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final exercise = await showExercisePicker(context);
    if (exercise == null) return;

    await ref.read(workoutRepositoryProvider).addExerciseToDay(
      dayId,
      exercise.id,
    );
  }

  Future<void> _startWorkout(
    BuildContext context,
    WidgetRef ref,
    String dayName,
  ) async {
    final sessionId = await ref
        .read(sessionRepositoryProvider)
        .startSession(dayId: dayId, name: dayName);
    if (!context.mounted) return;
    context.go('/workout/session/$sessionId');
  }
}

class _PlannedExerciseTile extends ConsumerWidget {
  const _PlannedExerciseTile({required this.planned});

  final PlannedExercise planned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    final entry = planned.entry;
    final exercise = planned.exercise;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: accent.withValues(alpha: 0.15),
        child: Icon(categoryIcon(exercise.category), color: accent),
      ),
      title: Text(exercise.name),
      subtitle: Text('${entry.defaultSets} sets × ${entry.defaultReps} reps'),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Remove exercise',
        onPressed: () =>
            ref.read(workoutRepositoryProvider).removePlannedExercise(entry.id),
      ),
      onTap: () => _editSetsReps(context, ref),
    );
  }

  Future<void> _editSetsReps(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({int sets, int reps})>(
      context: context,
      builder: (context) => _SetsRepsDialog(
        initialSets: planned.entry.defaultSets,
        initialReps: planned.entry.defaultReps,
      ),
    );
    if (result == null) return;

    await ref.read(workoutRepositoryProvider).updatePlannedExercise(
      planned.entry.id,
      sets: result.sets,
      reps: result.reps,
    );
  }
}

// Allowed ranges for the sets/reps wheels (both start at 1).
const _maxSets = 15;
const _maxReps = 50;

/// Edits the default sets and reps for a planned exercise using two scroll
/// wheels. Owns its scroll controllers via a [StatefulWidget] so they're
/// disposed at the right time.
class _SetsRepsDialog extends StatefulWidget {
  const _SetsRepsDialog({required this.initialSets, required this.initialReps});

  final int initialSets;
  final int initialReps;

  @override
  State<_SetsRepsDialog> createState() => _SetsRepsDialogState();
}

class _SetsRepsDialogState extends State<_SetsRepsDialog> {
  // Wheel index 0 == value 1, so the initial index is (value - 1), clamped in
  // case stored data ever falls outside the wheel's range.
  late final _setsController = FixedExtentScrollController(
    initialItem: widget.initialSets.clamp(1, _maxSets) - 1,
  );
  late final _repsController = FixedExtentScrollController(
    initialItem: widget.initialReps.clamp(1, _maxReps) - 1,
  );

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop((
      sets: _setsController.selectedItem + 1,
      reps: _repsController.selectedItem + 1,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sets & reps'),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _NumberWheel(
              label: 'Sets',
              controller: _setsController,
              maxValue: _maxSets,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _NumberWheel(
              label: 'Reps',
              controller: _repsController,
              maxValue: _maxReps,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

/// A vertical scroll wheel of numbers from 1..[maxValue], with a label above
/// and the centred (selected) value highlighted in the accent colour.
class _NumberWheel extends ConsumerWidget {
  const _NumberWheel({
    required this.label,
    required this.controller,
    required this.maxValue,
  });

  final String label;
  final FixedExtentScrollController controller;
  final int maxValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Highlight band behind the centred item.
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 40,
                physics: const FixedExtentScrollPhysics(),
                overAndUnderCenterOpacity: 0.35,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: maxValue,
                  builder: (context, index) => Center(
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
              Icons.fitness_center,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('No exercises yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Add exercises from the library and set their sets and reps.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
