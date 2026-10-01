import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../app/theme/motion.dart';
import '../../../shared/models/goal.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/app_card.dart';
import '../data/goal_labels.dart';
import '../data/goal_progress.dart';
import '../data/goal_repository.dart';
import 'goal_progress_row.dart';

/// The moment a goal is reached.
///
/// Small on purpose: a pane that springs in with a trophy, a light buzz, and
/// one button to say you have seen it. It waits for that tap rather than
/// fading on a timer — a goal you worked a month for should not disappear
/// while you were looking at something else — and once seen it is gone for
/// good (for a weekly goal, until next week's).
///
/// Springs in on the emphasis curve, like a personal record does mid-workout;
/// with reduced motion it simply appears, because the news matters and the
/// movement does not.
class GoalCelebration extends ConsumerStatefulWidget {
  const GoalCelebration({super.key, required this.status});

  final GoalStatus status;

  @override
  ConsumerState<GoalCelebration> createState() => _GoalCelebrationState();
}

class _GoalCelebrationState extends ConsumerState<GoalCelebration> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final unit = ref.watch(weightUnitProvider);
    final status = widget.status;
    final weekly = status.kind == GoalKind.frequency;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: motionOf(context, AppDurations.slow),
      curve: AppCurves.emphasis,
      builder: (context, t, child) => Opacity(
        // The spring overshoots past 1, which an opacity cannot.
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
      ),
      child: Semantics(
        liveRegion: true,
        child: AppCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.emoji_events, color: accent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      weekly ? 'Week done' : 'Goal reached',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      goalTitle(
                        status,
                        exerciseName: exerciseNameFor(
                          ref,
                          status.goal.exerciseId,
                        ),
                        unit: unit,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      goalCaption(status),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => ref
                            .read(goalRepositoryProvider)
                            .markCelebrated(status.goal.id),
                        child: const Text('Nice'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
