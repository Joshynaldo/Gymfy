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
///
/// Drawn as a floating rounded card rather than a full-bleed strip: it is a
/// temporary thing sitting on top of the session, and a square-edged band
/// welded to the app bar read as permanent chrome.
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
    final progress = timer.totalSeconds == 0
        ? 0.0
        : (timer.remainingSeconds / timer.totalSeconds).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: AnimatedContainer(
        // Lights up when the rest is over, so it reads across the gym at a
        // glance rather than needing the number to be read. Animated so the
        // change registers even if you look up a second late.
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: done
              ? Color.alphaBlend(
                  accent.withValues(alpha: 0.20),
                  theme.colorScheme.surface,
                )
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: done ? accent : accent.withValues(alpha: 0.22),
            width: done ? 1.6 : 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            _CountdownRing(progress: progress, done: done, accent: accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    done ? 'Rest over' : formatRest(timer.remainingSeconds),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: done ? accent : null,
                      // Digits shouldn't shuffle sideways as they count down,
                      // so the glyphs are held to one width.
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
              // A pill rather than a bare text button: it is the one thing here
              // you reach for mid-set, often without looking properly.
              _RoundAction(
                accent: accent,
                onPressed: () => controller.adjust(30),
                tooltip: 'Add 30 seconds',
                child: Text(
                  '+30s',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: done ? 'Dismiss' : 'Skip rest',
              onPressed: controller.stop,
            ),
          ],
        ),
      ),
    );
  }
}

/// The countdown as a ring around its own icon.
///
/// Replaces the hairline progress bar that used to sit under the row. A 4px
/// line pinned to the bottom edge was easy to miss entirely; a ring next to the
/// number is in the same glance as the number.
class _CountdownRing extends StatelessWidget {
  const _CountdownRing({
    required this.progress,
    required this.done,
    required this.accent,
  });

  /// 1.0 at the start of the rest, 0.0 when it runs out.
  final double progress;
  final bool done;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox.square(
      dimension: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: 46,
            child: CircularProgressIndicator(
              // Full when done rather than empty: the ring closing is the
              // finish line, and an empty ring reads as "nothing running".
              value: done ? 1 : progress,
              strokeWidth: 3.5,
              strokeCap: StrokeCap.round,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          Icon(
            done ? Icons.check_rounded : Icons.timer_outlined,
            size: 20,
            color: accent,
          ),
        ],
      ),
    );
  }
}

/// A rounded, accent-tinted tap target.
class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.child,
    required this.accent,
    required this.onPressed,
    required this.tooltip,
  });

  final Widget child;
  final Color accent;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: child,
          ),
        ),
      ),
    );
  }
}
