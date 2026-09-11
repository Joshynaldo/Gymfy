import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/utils/format.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/exercise_thumbnail.dart';
import '../../../shared/widgets/number_wheel.dart';
import '../data/session_repository.dart';
import '../data/workout_repository.dart';
import 'widgets/exercise_picker.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';
import '../../../shared/widgets/glass_dialog.dart';

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

    return GlassScaffold(
      appBar: GlassAppBar(title: Text(title)),
      body: (context) => exercisesAsync.when(
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
            // It had no padding at all: on a glass theme the list now runs the
            // full height of the screen, so it has to clear the bars itself.
            // The extra at the foot is room for the floating Add button.
            padding: const EdgeInsets.only(bottom: 80) + barInsets(context),
            // One extra row at the top for the Start button.
            itemCount: planned.length + 1,
            // No rule under the Start button: it is not one of the rows.
            separatorBuilder: (_, index) =>
                index == 0 ? const SizedBox.shrink() : const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                // At the top, full width, in the accent — the shape the design
                // gives the one thing a screen is for. It was a text button in
                // the app bar, which is where you put an action you are not
                // sure anyone wants; this is the whole point of the screen.
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: AppButton(
                    label: 'Start workout',
                    icon: Icons.play_arrow,
                    onPressed: () => _startWorkout(context, ref, title),
                  ),
                );
              }
              return _PlannedExerciseTile(
                planned: planned[index - 1],
                dayExercises: planned.length,
              );
            },
          );
        },
      ),
      // Centred rather than tucked into the right-hand corner: it is the only
      // floating control on the screen, and a corner is where you put one of
      // several. The pill below it is centred too, so an off-centre button
      // between them read as a mistake.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AppButton(
        label: 'Add exercises',
        icon: Icons.add,
        expand: false,
        onPressed: () => _addExercises(context, ref),
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
      SnackBar(
        content: Text(addedToDayMessage(added: added, asked: ids.length)),
      ),
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
  const _PlannedExerciseTile({
    required this.planned,
    required this.dayExercises,
  });

  final PlannedExercise planned;

  /// How many exercises the day holds, for the "apply to every exercise"
  /// option. Passed down rather than re-watched here: the list already has it,
  /// and a per-row watch would be the same query once per row.
  final int dayExercises;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = planned.entry;
    final exercise = planned.exercise;

    return ListTile(
      leading: ExerciseThumbnail(gifPath: exercise.gifPath),
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
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<_SetsRepsResult>(
      context: context,
      builder: (context) => _SetsRepsDialog(
        initialSets: planned.entry.defaultSets,
        initialReps: planned.entry.defaultReps,
        initialRepsMax: planned.entry.defaultRepsMax,
        initialWarmups: planned.entry.warmupSets,
        otherExercises: dayExercises - 1,
      ),
    );
    if (result == null) return;

    final repository = ref.read(workoutRepositoryProvider);
    if (!result.applyToAll) {
      await repository.updatePlannedExercise(
        planned.entry.id,
        sets: result.sets,
        reps: result.reps,
        repsMax: result.repsMax,
        warmupSets: result.warmups,
      );
      return;
    }

    final changed = await repository.updateAllPlannedExercises(
      planned.entry.dayId,
      sets: result.sets,
      reps: result.reps,
      repsMax: result.repsMax,
      warmupSets: result.warmups,
    );
    // Said out loud because it is the one edit here that changes rows you
    // weren't looking at — several of them may be scrolled off screen.
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          changed == 1
              ? 'Updated 1 exercise'
              : 'Updated all $changed exercises',
        ),
      ),
    );
  }
}

/// What the sets/reps dialog hands back.
typedef _SetsRepsResult = ({
  int sets,
  int reps,
  int? repsMax,
  int warmups,
  bool applyToAll,
});

/// Wheel index 0 is the value 1: these wheels count from one, because zero
/// sets of zero reps is not a plan.
String _oneBased(int index) => '${index + 1}';

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
    required this.otherExercises,
  });

  final int initialSets;
  final int initialReps;

  /// Null when the exercise currently has a fixed target rather than a range.
  final int? initialRepsMax;

  /// How many ramp-up sets are planned. Zero for most exercises.
  final int initialWarmups;

  /// How many *other* exercises the day holds.
  ///
  /// Zero hides the "apply to every exercise" option entirely: on a one-exercise
  /// day it would be a checkbox that changes nothing, which is worse than an
  /// absent one.
  final int otherExercises;

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
        (widget.initialRepsMax ?? widget.initialReps + 4).clamp(1, _maxReps) -
        1,
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

  void _submit({bool applyToAll = false}) {
    Navigator.of(context).pop((
      sets: _setsController.selectedItem + 1,
      reps: _repsController.selectedItem + 1,
      // The repository drops a max that isn't above the minimum, so scrolling
      // the top below the bottom quietly means "no range" rather than saving
      // something backwards.
      repsMax: _useRange ? _repsMaxController.selectedItem + 1 : null,
      warmups: _warmups,
      applyToAll: applyToAll,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      title: const Text('Sets & reps'),
      // Scrollable because the content genuinely can exceed the space: three
      // wheels, a switch, six warm-up chips and the apply-to-all row already
      // overflow a short dialog, and a large system font size makes that worse
      // rather than better. An AlertDialog does not scroll its content on its
      // own — it clips it and paints the overflow stripe.
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: NumberWheel(
                    label: 'Sets',
                    controller: _setsController,
                    itemCount: _maxSets,
                    labelAt: _oneBased,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NumberWheel(
                    // The label changes with the mode, so the left wheel never
                    // silently means two different things.
                    label: _useRange ? 'From' : 'Reps',
                    controller: _repsController,
                    itemCount: _maxReps,
                    labelAt: _oneBased,
                  ),
                ),
                if (_useRange) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: NumberWheel(
                      label: 'To',
                      controller: _repsMaxController,
                      itemCount: _maxReps,
                      labelAt: _oneBased,
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
                  AppChip(
                    label: '$n',
                    selected: _warmups == n,
                    onTap: () => setState(() => _warmups = n),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        // Hidden on a one-exercise day, where it would do exactly what Save
        // does and only raise a moment's doubt about the difference.
        if (widget.otherExercises > 0)
          TextButton(
            onPressed: () => _submit(applyToAll: true),
            // Carries the count, because this is the one action here that
            // changes rows you cannot see — several may be scrolled off the
            // screen. "Save to all" on its own hides how much is about to
            // change.
            //
            // Deliberately a TextButton beside the filled Save. Both are one
            // tap now, so the only thing keeping the wider action from being
            // hit by accident is that it looks secondary and says what it does.
            child: Text('Save to all ${widget.otherExercises + 1}'),
          ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
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
