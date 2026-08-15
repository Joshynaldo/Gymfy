import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../data/rest_timer_controller.dart';
import '../data/rest_timer_repository.dart';

/// The rest countdown, shown above the workout while a timer is running.
///
/// Its own widget watching its own provider so the once-a-second rebuild is
/// confined to this bar — rebuilding the whole workout screen every second
/// would be wasteful on the older hardware this app targets.
class RestTimerBar extends ConsumerWidget {
  const RestTimerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(restTimerProvider);
    if (timer == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final done = timer.remainingSeconds <= 0;
    final controller = ref.read(restTimerProvider.notifier);

    return Material(
      // Green-lit when the rest is over, so it reads across the gym at a glance
      // rather than needing the number to be read.
      color: done
          ? accent.withValues(alpha: 0.22)
          : theme.colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Icon(
                  done ? Icons.check_circle_outline : Icons.timer_outlined,
                  color: accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        done
                            ? 'Rest over'
                            : formatRest(timer.remainingSeconds),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          // Digits shouldn't shuffle sideways as they count
                          // down, so the glyphs are held to one width.
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        timer.exerciseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!done)
                  TextButton(
                    onPressed: () => controller.adjust(30),
                    child: const Text('+30s'),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: done ? 'Dismiss' : 'Skip rest',
                  onPressed: controller.stop,
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            // Counts down, so the bar drains rather than fills.
            value: timer.totalSeconds == 0
                ? 0
                : timer.remainingSeconds / timer.totalSeconds,
            minHeight: 4,
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
            color: accent,
          ),
        ],
      ),
    );
  }
}
