import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_picker.dart';
import '../../../shared/widgets/glass_sheet.dart';
import '../data/session_repository.dart';
import '../data/workout_repository.dart';
import '../screens/widgets/exercise_picker.dart';

// The edits a running workout's exercise list allows: add, swap, reorder and
// remove. Kept out of active_workout_screen.dart, which is busy enough with
// logging; the screen only decides *when* to call these.
//
// All of them edit the session's own running order (session_exercises) and
// leave the plan alone, except a swap the user explicitly saves to the plan.

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

/// Whether a swap applies to today only, or to the plan as well.
enum SwapScope { session, plan }

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
    final picked = await showOptionPicker<SwapScope>(
      context: context,
      title: l10n.workoutSwapScopeTitle,
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
                      Icons.drag_handle,
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
