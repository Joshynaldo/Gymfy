import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_picker.dart';
import '../../../shared/widgets/glass_sheet.dart';
import '../data/session_repository.dart';
import '../data/workout_repository.dart';
import '../screens/widgets/exercise_picker.dart';
import '../../../shared/widgets/lucide_icons.dart';

// The edits a running workout's exercise list allows: add, swap, superset,
// reorder and remove. Kept out of active_workout_screen.dart, which is busy
// enough with logging; the screen only decides *when* to call these.
//
// All of them edit the session's own running order (session_exercises) and
// leave the plan alone, except a swap or superset the user explicitly saves to
// the plan.

/// Asks which exercises to add and appends them to the session. Exercises
/// already in the workout aren't offered. Returns the ids actually added,
/// in order (empty if the picker was dismissed).
Future<List<String>> addExercisesToSession(
  BuildContext context,
  WidgetRef ref, {
  required int sessionId,
  required List<SessionExerciseEntry> entries,
}) async {
  final present = {for (final e in entries) e.exercise.id};
  final ids = await showExercisePicker(context, exclude: present);
  if (ids == null) return const [];

  await ref.read(sessionRepositoryProvider).addExercises(sessionId, ids);
  return [
    for (final id in ids)
      if (!present.contains(id)) id,
  ];
}

/// Whether a swap or a superset change applies to today only, or to the plan
/// as well.
enum SwapScope { session, plan }

/// Asks whether an edit should be saved to the plan too. Returns null if the
/// sheet was dismissed.
Future<SwapScope?> _askScope(BuildContext context, {required String title}) {
  final l10n = context.l10n;
  return showOptionPicker<SwapScope>(
    context: context,
    title: title,
    options: [
      (
        value: SwapScope.session,
        label: l10n.workoutSwapScopeSession,
        subtitle: l10n.workoutPlanUnchanged,
      ),
      (
        value: SwapScope.plan,
        label: l10n.workoutSwapScopePlan,
        subtitle: l10n.workoutSwapScopePlanSubtitle,
      ),
    ],
    selected: null,
  );
}

/// Swaps [entry] for an exercise the user picks, and returns the new
/// exercise's id — or null if nothing changed.
///
/// An entry that came from the plan asks whether the swap should be saved back
/// to it. The question is skipped for an exercise added during the workout,
/// which has no plan slot to save to.
Future<String?> swapSessionExercise(
  BuildContext context,
  WidgetRef ref, {
  required SessionExerciseEntry entry,
  required List<SessionExerciseEntry> entries,
}) async {
  // Taken before any await, which the context may not outlive.
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l10n = context.l10n;
  final exerciseId = await showSingleExercisePicker(
    context,
    title: l10n.workoutSwapTitle(entry.exercise.name),
    exclude: {for (final e in entries) e.exercise.id},
  );
  if (exerciseId == null || !context.mounted) return null;

  final planned = entry.planned;
  var scope = SwapScope.session;
  if (planned != null) {
    final picked = await _askScope(context, title: l10n.workoutSwapScopeTitle);
    if (picked == null) return null;
    scope = picked;
  }

  final swapped = await ref
      .read(sessionRepositoryProvider)
      .swapExercise(sessionExerciseId: entry.row.id, exerciseId: exerciseId);
  if (!swapped) return null;

  if (scope == SwapScope.plan && planned != null) {
    final saved = await ref
        .read(workoutRepositoryProvider)
        .replacePlannedExercise(planned.id, exerciseId);
    // The plan already has it elsewhere — saving would plan it twice. Today's
    // swap stands; say why the plan didn't change rather than let it look
    // saved.
    if (!saved) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.workoutSwapPlanClash)),
      );
    }
  }
  return exerciseId;
}

enum _SupersetEdit { withPrevious, withNext, leave }

/// Offers the superset edits that make sense for [entry] in today's running
/// order — pair it with the exercise before or after, or take it out of its
/// superset — and applies the one picked.
///
/// Like a swap, a change can be saved to the plan as well. That is asked only
/// when the plan has the exercises involved: a free workout, or an exercise
/// added mid-session, has no plan slot to save it to.
Future<void> editSessionSuperset(
  BuildContext context,
  WidgetRef ref, {
  required SessionExerciseEntry entry,
  required List<SessionExerciseEntry> entries,
}) async {
  // Taken before any await, which the context may not outlive.
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l10n = context.l10n;

  final index = entries.indexWhere((e) => e.row.id == entry.row.id);
  if (index == -1) return;
  final previous = index > 0 ? entries[index - 1] : null;
  final next = index < entries.length - 1 ? entries[index + 1] : null;
  bool linkedTo(SessionExerciseEntry? other) =>
      other != null &&
      entry.supersetGroup != null &&
      other.supersetGroup == entry.supersetGroup;

  final edit = await showOptionPicker<_SupersetEdit>(
    context: context,
    title: l10n.workoutSuperset,
    options: [
      if (previous != null && !linkedTo(previous))
        (
          value: _SupersetEdit.withPrevious,
          label: l10n.workoutSupersetWithExercise(previous.exercise.name),
          subtitle: l10n.workoutSupersetBackToBack,
        ),
      if (next != null && !linkedTo(next))
        (
          value: _SupersetEdit.withNext,
          label: l10n.workoutSupersetWithExercise(next.exercise.name),
          subtitle: l10n.workoutSupersetBackToBack,
        ),
      if (linkedTo(previous) || linkedTo(next))
        (
          value: _SupersetEdit.leave,
          label: l10n.workoutSupersetLeave,
          subtitle: null,
        ),
    ],
    selected: null,
  );
  if (edit == null || !context.mounted) return;

  final partner = switch (edit) {
    _SupersetEdit.withPrevious => previous,
    _SupersetEdit.withNext => next,
    _SupersetEdit.leave => null,
  };
  // Only asked when saving would change the plan: not for a superset the plan
  // already has, nor for leaving one the plan never had.
  final slot = entry.planned;
  final partnerSlot = partner?.planned;
  final canSaveToPlan = switch (edit) {
    _SupersetEdit.leave => slot?.supersetGroup != null,
    _ =>
      slot != null &&
          partnerSlot != null &&
          (slot.supersetGroup == null ||
              slot.supersetGroup != partnerSlot.supersetGroup),
  };
  var scope = SwapScope.session;
  if (canSaveToPlan) {
    final picked = await _askScope(
      context,
      title: l10n.workoutSupersetScopeTitle,
    );
    if (picked == null) return;
    scope = picked;
  }

  final sessions = ref.read(sessionRepositoryProvider);
  switch (edit) {
    case _SupersetEdit.withPrevious:
      await sessions.supersetWithPrevious(entry.row.id);
    case _SupersetEdit.withNext:
      await sessions.supersetWithNext(entry.row.id);
    case _SupersetEdit.leave:
      await sessions.leaveSuperset(entry.row.id);
  }
  if (scope != SwapScope.plan) return;

  final plan = ref.read(workoutRepositoryProvider);
  if (edit == _SupersetEdit.leave) {
    await plan.leaveSuperset(slot!.id);
    return;
  }
  final saved = await plan.supersetPlannedPair(slot!.id, partnerSlot!.id);
  // Neighbours today, but not in the plan: the workout was reordered. Today's
  // superset stands; say why the plan didn't change rather than let it look
  // saved.
  if (!saved) {
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.workoutSupersetPlanApart)),
    );
  }
}

/// Lets the user drag the session's exercises into a new order and saves it.
Future<void> reorderSessionExercises(
  BuildContext context,
  WidgetRef ref, {
  required int sessionId,
  required List<SessionExerciseEntry> entries,
}) async {
  final order = await showModalBottomSheet<List<int>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SessionOrderSheet(entries: entries),
  );
  if (order == null) return;
  await ref.read(sessionRepositoryProvider).reorderExercises(sessionId, order);
}

/// The reorder sheet: the running order as a draggable list, saved with Done.
///
/// Saved once at the end rather than on every drop, so a list being dragged
/// around is never written half-sorted, and dismissing the sheet is a real
/// cancel.
class SessionOrderSheet extends StatefulWidget {
  const SessionOrderSheet({super.key, required this.entries});

  final List<SessionExerciseEntry> entries;

  @override
  State<SessionOrderSheet> createState() => _SessionOrderSheetState();
}

class _SessionOrderSheetState extends State<SessionOrderSheet> {
  late final List<SessionExerciseEntry> _order = [...widget.entries];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassSheet(
      title: context.l10n.workoutReorderTitle,
      handle: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bounded so a long workout scrolls inside the sheet instead of
          // pushing Done off the bottom of the screen.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              buildDefaultDragHandles: false,
              itemCount: _order.length,
              onReorderItem: (from, to) =>
                  setState(() => _order.insert(to, _order.removeAt(from))),
              itemBuilder: (context, index) {
                final entry = _order[index];
                return ListTile(
                  key: ValueKey(entry.row.id),
                  title: Text(entry.exercise.name),
                  trailing: ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      LucideIcons.gripHorizontal,
                      semanticLabel: context.l10n.workoutDragToReorder,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppButton(
              label: context.l10n.commonDone,
              onPressed: () => Navigator.of(
                context,
              ).pop([for (final entry in _order) entry.row.id]),
            ),
          ),
        ],
      ),
    );
  }
}
