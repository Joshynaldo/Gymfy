import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/utils/units.dart';
import '../../exercises/data/exercise_names.dart';
import '../data/goal_labels.dart';
import '../data/goal_progress.dart';

/// One goal as a line of text, a bar and a caption.
///
/// [muted] draws the bar in white rather than the accent — for Home, whose one
/// accent belongs to the button that starts the workout. On the Goals screen
/// the bar is the point, and takes the accent.
class GoalProgressRow extends ConsumerWidget {
  const GoalProgressRow({super.key, required this.status, this.muted = false});

  final GoalStatus status;
  final bool muted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final unit = ref.watch(weightUnitProvider);
    final title = goalTitle(
      status,
      exerciseName: exerciseNameFor(ref, status.goal.exerciseId),
      unit: unit,
    );
    final muteColour = theme.colorScheme.onSurfaceVariant;

    return Semantics(
      label: '$title, ${goalValue(status, unit: unit)}, ${goalCaption(status)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // The title gives way: the value beside it is short and is the
              // number the row exists to show.
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                goalValue(status, unit: unit),
                maxLines: 1,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: status.fraction,
              minHeight: 6,
              color: muted
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.55)
                  : accent,
              backgroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.10,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            goalCaption(status),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              // A missed deadline is said in the error colour, quietly: the
              // goal is still there to be finished, and the screen should not
              // shout about it.
              color: status.overdue ? theme.colorScheme.error : muteColour,
            ),
          ),
        ],
      ),
    );
  }
}

/// The name of exercise [id], or null when there is none or the library has
/// not loaded yet.
String? exerciseNameFor(WidgetRef ref, String? id) =>
    id == null ? null : ref.watch(exerciseNamesProvider)[id];
