import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/week_start.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/models/body_measurement.dart';
import '../../../shared/models/goal.dart';
import '../../../shared/utils/dates.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/utils/weekday.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_picker.dart';
import '../../../shared/widgets/app_segmented.dart';
import '../../../shared/widgets/glass_sheet.dart';
import '../../../shared/widgets/weight_wheel.dart';
import '../../calculator/data/tested_one_rm_repository.dart';
import '../../progress/data/measurements_repository.dart';
import '../../progress/data/progress_repository.dart';
import '../../workout/screens/widgets/exercise_picker.dart';
import '../data/goal_labels.dart';
import '../data/goal_progress.dart';
import '../data/goal_repository.dart';
import 'goal_progress_row.dart';

/// Opens the form for a new goal, or for changing [editing].
Future<void> showGoalForm(BuildContext context, {Goal? editing}) {
  return showGlassSheet<void>(
    context: context,
    title: editing == null ? 'New goal' : 'Edit goal',
    child: GoalForm(editing: editing),
  );
}

/// The deadlines offered, as weeks from today. Null is "no deadline"; a
/// "Pick a date" row after them opens a calendar instead.
const _deadlineWeeks = [null, 4, 8, 12, 26];

/// Where the wheels open when there is no weigh-in to start from.
const _defaultBodyweightKg = 75.0;

/// Where a new lift goal's wheel opens, in [unit]: a loadable step above the
/// best so far, or an empty Olympic bar's worth plus plates for a lift never
/// logged.
double _suggestedLiftTarget(double? bestKg, WeightUnit unit) => bestKg == null
    ? weightIn(roundToLoadable(60, unit), unit)
    : weightIn(roundToLoadable(bestKg + 5, unit), unit);

/// What the user is setting up. One form for the three kinds, switched by the
/// control at the top — which is locked once the goal exists, since changing
/// a lift goal into a bodyweight one is really a new goal.
class GoalForm extends ConsumerStatefulWidget {
  const GoalForm({super.key, this.editing});

  final Goal? editing;

  @override
  ConsumerState<GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<GoalForm> {
  late GoalKind _kind = GoalKind.parse(widget.editing?.kind) ?? GoalKind.lift;
  late String? _exerciseId = widget.editing?.exerciseId;
  late int _perWeek = widget.editing?.kind == GoalKind.frequency.name
      ? widget.editing!.target.round()
      : 3;
  late DateTime? _deadline = widget.editing?.deadline;

  /// The target as the wheel shows it, in the display unit. Null until the
  /// user turns the wheel, so the starting value can follow the exercise or
  /// the latest weigh-in rather than being fixed when the form opened.
  double? _targetShown;

  /// The current bodyweight, for a bodyweight goal when none has ever been
  /// logged. In the display unit.
  double? _nowShown;

  String? _problem;
  bool _saving = false;

  bool get _editing => widget.editing != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_editing) ...[
            AppSegmented<GoalKind>(
              selected: _kind,
              onChanged: (kind) => setState(() {
                _kind = kind;
                _targetShown = null;
                _problem = null;
              }),
              segments: [
                for (final kind in GoalKind.values)
                  (value: kind, label: kind.label, leading: null),
              ],
            ),
            const SizedBox(height: 18),
          ],
          ...switch (_kind) {
            GoalKind.lift => _liftFields(unit),
            GoalKind.frequency => _frequencyFields(),
            GoalKind.bodyweight => _bodyweightFields(unit),
          },
          if (_kind != GoalKind.frequency) ...[
            const SizedBox(height: 14),
            AppPickerField(
              label: 'By',
              icon: Icons.event_outlined,
              value: _deadline == null ? 'No deadline' : formatDate(_deadline!),
              onTap: _pickDeadline,
            ),
          ],
          if (_problem != null) ...[
            const SizedBox(height: 12),
            Text(
              _problem!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 18),
          AppButton(
            label: _editing ? 'Save changes' : 'Save goal',
            onPressed: _saving ? null : () => _save(unit),
          ),
        ],
      ),
    );
  }

  // --- Lift -----------------------------------------------------------------

  /// The best the chosen exercise already has, in kilograms. Watched while
  /// building, so the hint fills in when the history arrives; read on save.
  double? _bestLift({bool watch = false}) {
    final id = _exerciseId;
    if (id == null) return null;
    final history = exerciseHistoryProvider(id);
    final tested = testedOneRmProvider(id);
    return bestLiftKg(
      (watch ? ref.watch(history) : ref.read(history)).value ?? const [],
      (watch ? ref.watch(tested) : ref.read(tested)).value,
    );
  }

  List<Widget> _liftFields(WeightUnit unit) {
    final theme = Theme.of(context);
    final name = exerciseNameFor(ref, _exerciseId);
    final best = _bestLift(watch: true);

    return [
      AppPickerField(
        label: 'Exercise',
        icon: Icons.fitness_center,
        value: name ?? 'Choose an exercise',
        onTap: _pickExercise,
        // Fixed once set: the goal's starting point was that lift's best, so
        // a goal on a different lift is a new goal, not an edit.
        enabled: !_editing,
      ),
      const SizedBox(height: 8),
      Text(
        best == null
            ? 'Counts your heaviest working set — warm-ups and drop sets '
                  'never do — or a tested max.'
            : 'Your best so far: ${formatWeightUnit(best, unit)}. Counts your '
                  'heaviest working set, or a tested max.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 14),
      WeightWheel(
        // Rebuilt when the exercise changes, and again when its history
        // arrives, so it opens on that lift's suggestion rather than keeping
        // the last one's.
        key: ValueKey('lift-target-$_exerciseId-${best != null}'),
        label: 'Target',
        unit: unit,
        initialWeight:
            _targetShown ??
            (_editing
                ? weightIn(widget.editing!.target, unit)
                : _suggestedLiftTarget(best, unit)),
        onChanged: (value) => _targetShown = value,
      ),
    ];
  }

  Future<void> _pickExercise() async {
    final picked = await showSingleExercisePicker(
      context,
      title: 'Goal for which lift?',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _exerciseId = picked;
      _targetShown = null;
      _problem = null;
    });
  }

  // --- Workouts a week ------------------------------------------------------

  List<Widget> _frequencyFields() {
    final theme = Theme.of(context);
    final first = ref.watch(firstWeekdayProvider);

    return [
      AppPickerField(
        label: 'How often',
        icon: Icons.event_repeat,
        value: workoutsPerWeekLabel(_perWeek),
        onTap: () async {
          final picked = await showNumberPicker(
            context: context,
            title: 'Workouts a week',
            min: 1,
            max: maxWorkoutsPerWeek,
            initial: _perWeek,
          );
          if (picked != null && mounted) setState(() => _perWeek = picked);
        },
      ),
      const SizedBox(height: 8),
      Text(
        'Counts finished workouts, free ones included. Weeks start on '
        '${weekdayName(first)}.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ];
  }

  // --- Bodyweight -----------------------------------------------------------

  List<Widget> _bodyweightFields(WeightUnit unit) {
    final theme = Theme.of(context);
    final latest = ref.watch(latestBodyweightProvider);
    final start = _editing ? widget.editing!.startValue : latest?.value;

    return [
      if (start != null)
        Text(
          _editing
              ? 'Started from ${formatWeightUnit(start, unit)}.'
              : 'Starting from ${formatWeightUnit(start, unit)}, logged '
                    '${formatDayLabel(latest!.day)}.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        )
      else ...[
        Text(
          'No weigh-in yet. What do you weigh today? It is saved to your '
          'measurements too.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        WeightWheel(
          label: 'Now',
          unit: unit,
          initialWeight: _nowShown ?? weightIn(_defaultBodyweightKg, unit),
          onChanged: (value) => _nowShown = value,
        ),
      ],
      const SizedBox(height: 14),
      WeightWheel(
        key: ValueKey('bodyweight-target-${start != null}'),
        label: 'Target',
        unit: unit,
        initialWeight:
            _targetShown ??
            (_editing
                ? weightIn(widget.editing!.target, unit)
                : weightIn(start ?? _defaultBodyweightKg, unit)),
        onChanged: (value) => _targetShown = value,
      ),
    ];
  }

  // --- Deadline and save ----------------------------------------------------

  Future<void> _pickDeadline() async {
    final today = dateOnly(clock.now());
    const custom = -1;
    final picked = await showOptionPicker<int>(
      context: context,
      title: 'Reach it by',
      selected: null,
      options: [
        for (final weeks in _deadlineWeeks)
          (
            value: weeks ?? 0,
            label: weeks == null
                ? 'No deadline'
                : weeks < 26
                ? 'In $weeks weeks'
                : 'In 6 months',
            subtitle: weeks == null
                ? null
                : formatDate(
                    DateTime(today.year, today.month, today.day + weeks * 7),
                  ),
          ),
        (value: custom, label: 'Pick a date', subtitle: null),
      ],
    );
    if (picked == null || !mounted) return;
    if (picked == 0) {
      setState(() => _deadline = null);
      return;
    }
    if (picked != custom) {
      setState(
        () => _deadline = DateTime(
          today.year,
          today.month,
          today.day + picked * 7,
        ),
      );
      return;
    }
    final date = await showDatePicker(
      context: context,
      initialDate:
          _deadline ?? DateTime(today.year, today.month + 3, today.day),
      firstDate: today,
      lastDate: DateTime(today.year + 5, today.month, today.day),
      helpText: 'Reach it by',
    );
    if (date != null && mounted) setState(() => _deadline = dateOnly(date));
  }

  /// The draft as it stands, everything in kilograms.
  GoalDraft _draft(WeightUnit unit) {
    final editing = widget.editing;
    switch (_kind) {
      case GoalKind.lift:
        final best = _bestLift();
        final shown =
            _targetShown ??
            (editing != null
                ? weightIn(editing.target, unit)
                : _suggestedLiftTarget(best, unit));
        return GoalDraft(
          kind: GoalKind.lift,
          exerciseId: _exerciseId,
          target: weightToKilograms(shown, unit),
          startValue: editing?.startValue ?? best,
          deadline: _deadline,
        );
      case GoalKind.frequency:
        return GoalDraft(kind: GoalKind.frequency, target: _perWeek.toDouble());
      case GoalKind.bodyweight:
        final latest = ref.read(latestBodyweightProvider)?.value;
        final start =
            editing?.startValue ??
            latest ??
            weightToKilograms(
              _nowShown ?? weightIn(_defaultBodyweightKg, unit),
              unit,
            );
        final shown =
            _targetShown ??
            (editing != null
                ? weightIn(editing.target, unit)
                : weightIn(start, unit));
        return GoalDraft(
          kind: GoalKind.bodyweight,
          target: weightToKilograms(shown, unit),
          startValue: start,
          deadline: _deadline,
        );
    }
  }

  Future<void> _save(WeightUnit unit) async {
    final draft = _draft(unit);
    final editing = widget.editing;
    final problem = goalDraftProblem(
      draft,
      today: clock.now(),
      // Only a new lift goal has to beat your best. An existing one keeps
      // the target it was set with even after you have passed it.
      bestLiftKg: editing == null && draft.kind == GoalKind.lift
          ? _bestLift()
          : null,
    );
    if (problem != null) {
      setState(() => _problem = problem);
      return;
    }

    setState(() => _saving = true);
    final goals = ref.read(goalRepositoryProvider);
    try {
      if (editing != null) {
        await goals.update(editing.id, draft);
      } else {
        // A first weigh-in typed into the form goes into the log as well, so
        // the goal and the measurements screen start from the same number.
        if (draft.kind == GoalKind.bodyweight &&
            ref.read(latestBodyweightProvider) == null) {
          await ref
              .read(measurementsRepositoryProvider)
              .setField(
                day: clock.now(),
                field: MeasurementField.weight,
                value: draft.startValue,
              );
        }
        await goals.add(draft);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _problem = 'Could not save that goal.\n$error';
        });
      }
    }
  }
}
