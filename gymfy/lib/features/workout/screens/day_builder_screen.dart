import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/utils/exercise_display.dart';
import '../../../shared/utils/format.dart';
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
        onPressed: () => _addExercises(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add exercises'),
      ),
    );
  }

  Future<void> _addExercises(BuildContext context, WidgetRef ref) async {
    final ids = await showExercisePicker(context);
    if (ids == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final added = await ref
        .read(workoutRepositoryProvider)
        .addExercisesToDay(dayId, ids);

    // Exercises already in the day are skipped, so a flat "4 added" would
    // sometimes be a lie.
    messenger.showSnackBar(
      SnackBar(content: Text(addedToDayMessage(added: added, asked: ids.length))),
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
        child: Icon(exerciseIcon, color: accent),
      ),
      title: Text(exercise.name),
      subtitle: Text(
        [
          '${entry.defaultSets} sets × '
              '${formatRepTarget(entry.defaultReps, entry.defaultRepsMax)} reps',
          // Only mentioned when there are some — "0 warm-ups" on every cable
          // curl would be noise on the row it least belongs to.
          if (entry.warmupSets > 0)
            entry.warmupSets == 1
                ? '1 warm-up'
                : '${entry.warmupSets} warm-ups',
        ].join(' • '),
      ),
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
    final result =
        await showDialog<({int sets, int reps, int? repsMax, int warmups})>(
          context: context,
          builder: (context) => _SetsRepsDialog(
            initialSets: planned.entry.defaultSets,
            initialReps: planned.entry.defaultReps,
            initialRepsMax: planned.entry.defaultRepsMax,
            initialWarmups: planned.entry.warmupSets,
          ),
        );
    if (result == null) return;

    await ref.read(workoutRepositoryProvider).updatePlannedExercise(
      planned.entry.id,
      sets: result.sets,
      reps: result.reps,
      repsMax: result.repsMax,
      warmupSets: result.warmups,
    );
  }
}

// Allowed ranges for the sets/reps wheels (both start at 1).
const _maxSets = 15;
const _maxReps = 50;

/// Highest planned warm-up count offered. Five is already a long ramp-up; the
/// session lets you log more than planned anyway, so this caps the *plan*, not
/// what you can actually do.
const _maxWarmups = 5;

/// Edits the default sets and reps for a planned exercise using two scroll
/// wheels. Owns its scroll controllers via a [StatefulWidget] so they're
/// disposed at the right time.
class _SetsRepsDialog extends StatefulWidget {
  const _SetsRepsDialog({
    required this.initialSets,
    required this.initialReps,
    required this.initialRepsMax,
    required this.initialWarmups,
  });

  final int initialSets;
  final int initialReps;

  /// Null when the exercise currently has a fixed target rather than a range.
  final int? initialRepsMax;

  /// How many ramp-up sets are planned. Zero for most exercises.
  final int initialWarmups;

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
  // Opens on a sensible range rather than at 1 when the switch is first turned
  // on: a couple of reps above the minimum is what people mean by "8–12".
  late final _repsMaxController = FixedExtentScrollController(
    initialItem:
        (widget.initialRepsMax ?? widget.initialReps + 4).clamp(1, _maxReps) - 1,
  );

  late bool _useRange = widget.initialRepsMax != null;

  late int _warmups = widget.initialWarmups.clamp(0, _maxWarmups);

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _repsMaxController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop((
      sets: _setsController.selectedItem + 1,
      reps: _repsController.selectedItem + 1,
      // The repository drops a max that isn't above the minimum, so scrolling
      // the top below the bottom quietly means "no range" rather than saving
      // something backwards.
      repsMax: _useRange ? _repsMaxController.selectedItem + 1 : null,
      warmups: _warmups,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sets & reps'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _NumberWheel(
                  label: 'Sets',
                  controller: _setsController,
                  maxValue: _maxSets,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberWheel(
                  // The label changes with the mode, so the left wheel never
                  // silently means two different things.
                  label: _useRange ? 'From' : 'Reps',
                  controller: _repsController,
                  maxValue: _maxReps,
                ),
              ),
              if (_useRange) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberWheel(
                    label: 'To',
                    controller: _repsMaxController,
                    maxValue: _maxReps,
                  ),
                ),
              ],
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Rep range'),
            value: _useRange,
            onChanged: (value) => setState(() => _useRange = value),
          ),
          // Chips rather than a fourth wheel: nobody plans nine warm-ups, and
          // three cramped wheels plus a fourth would be unreadable on a phone.
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Warm-up sets',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (var n = 0; n <= _maxWarmups; n++)
                ChoiceChip(
                  label: Text('$n'),
                  selected: _warmups == n,
                  onSelected: (_) => setState(() => _warmups = n),
                ),
            ],
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
