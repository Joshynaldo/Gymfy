import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../app/theme/glass.dart';
import '../../../app/theme/motion.dart';
import '../../../shared/widgets/pressable.dart';
import '../data/rest_timer_controller.dart';

/// The rest countdown, floating over the workout while a timer is running.
///
/// Its own widget watching its own provider so the once-a-second rebuild is
/// confined to this pane — rebuilding the whole workout screen every second
/// would be wasteful on the older hardware this app targets.
///
/// This is the one pane on the workout screen that blurs, and the one that
/// takes the accent. Both are earned: it genuinely covers a list that is still
/// scrolling underneath, and mid-workout the live countdown really is the thing
/// that matters. Everything else on the screen stays white-on-glass so this has
/// something to be louder than.
class RestTimerBar extends ConsumerWidget {
  const RestTimerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(restTimerProvider);
    if (timer == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final glass = glassOf(context);
    final accent = ref.watch(accentColorProvider);
    final done = timer.remainingSeconds <= 0;
    final controller = ref.read(restTimerProvider.notifier);
    final progress = timer.totalSeconds == 0
        ? 0.0
        : (timer.remainingSeconds / timer.totalSeconds).clamp(0.0, 1.0);

    final radius = BorderRadius.circular(24);

    return ClipRRect(
      borderRadius: radius,
      child: _Backdrop(
        blur: glass.enabled ? glass.backdropFilter(30) : null,
        child: AnimatedContainer(
          // Lights up when the rest is over, so it reads across a gym at a
          // glance rather than needing the number to be read. Animated so the
          // change registers even if you look up a second late.
          duration: motionOf(context, AppDurations.standard),
          curve: AppCurves.settle,
          decoration: BoxDecoration(
            borderRadius: radius,
            // Accent over a dark floor, not accent alone: this covers moving
            // content, and a tint with nothing behind it lets the list read
            // straight through the countdown.
            color: glass.enabled
                ? const Color(0xB30B0B15)
                : theme.colorScheme.surfaceContainerHighest,
            gradient: glass.enabled
                ? LinearGradient(
                    begin: const Alignment(-0.07, -1),
                    end: const Alignment(0.07, 1),
                    colors: [
                      accent.withValues(alpha: done ? 0.40 : 0.22),
                      accent.withValues(alpha: done ? 0.30 : 0.14),
                    ],
                  )
                : null,
            border: Border.all(
              color: done
                  ? accent.withValues(alpha: 0.46)
                  : accent.withValues(alpha: 0.24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            done ? 'REST OVER' : 'RESTING',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          _Countdown(
                            seconds: timer.remainingSeconds,
                            done: done,
                            accent: accent,
                          ),
                          const SizedBox(height: 2),
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
                    if (!done) ...[
                      // Drops out at zero. There is nothing left to add thirty
                      // seconds to, and a button that does nothing is worse
                      // than one that is not there.
                      _PaneButton(
                        onTap: () => controller.adjust(30),
                        tooltip: 'Add 30 seconds',
                        child: Text(
                          '+30s',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    _PaneButton(
                      onTap: controller.stop,
                      tooltip: done ? 'Dismiss' : 'Skip rest',
                      square: true,
                      child: Icon(
                        Icons.close,
                        size: 17,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _RestBar(progress: done ? 0 : progress, accent: accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// How much rest is left, as a bar that empties.
///
/// Along the foot rather than a ring beside the number. The number already says
/// how long is left; this says it without being read at all — from across a gym
/// you see a short bar, not "0:23".
///
/// Two details do the work. It runs on a *track*, so what is gone is as visible
/// as what remains: an unlit bar on a dark pane just looks like a shorter bar,
/// and you cannot tell a third left from a third used. And it slides rather
/// than stepping — the timer ticks once a second, so without this the bar jumps
/// in twelve visible steps and reads as something recalculating rather than
/// time passing.
class _RestBar extends StatelessWidget {
  const _RestBar({required this.progress, required this.accent});

  /// 1.0 at the start of the rest, 0.0 when it runs out.
  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            // A shade under the tick it is following, so each second's travel
            // finishes just before the next begins and the bar never stalls.
            duration: motionOf(context, const Duration(milliseconds: 900)),
            // Linear: this *is* elapsing time, and easing it would mean the bar
            // moving at a speed the clock is not.
            curve: Curves.linear,
            builder: (context, value, _) => FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: ColoredBox(color: accent),
            ),
          ),
        ),
      ),
    );
  }
}

/// The digits, at the size you can read with a bar on your back.
class _Countdown extends StatelessWidget {
  const _Countdown({
    required this.seconds,
    required this.done,
    required this.accent,
  });

  final int seconds;
  final bool done;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (done) {
      return Text(
        'Rest over',
        style: theme.textTheme.headlineMedium?.copyWith(
          fontSize: 34,
          height: 1.05,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.8,
          color: accent,
        ),
      );
    }

    final minutes = seconds ~/ 60;
    final rest = (seconds % 60).toString().padLeft(2, '0');
    final style = theme.textTheme.headlineMedium?.copyWith(
      fontSize: 38,
      height: 1.05,
      fontWeight: FontWeight.w600,
      letterSpacing: -1,
      color: accent,
    );

    // The digits are tabular so they do not shuffle as they count down — but
    // the colon is not. A tabular colon is padded to the width of a digit,
    // which leaves "1 : 07" floating in the middle of the number.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$minutes',
          style: style?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(':', style: style),
        Text(
          rest,
          style: style?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// A control on the pane: a pill, or a square when it holds an icon.
class _PaneButton extends StatelessWidget {
  const _PaneButton({
    required this.child,
    required this.onTap,
    required this.tooltip,
    this.square = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final String tooltip;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(13);

    return Tooltip(
      message: tooltip,
      child: Pressable(
        borderRadius: radius,
        onTap: onTap,
        splash: false,
        child: Container(
          width: square ? 36 : null,
          height: 36,
          alignment: Alignment.center,
          padding: square
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
            borderRadius: radius,
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.16),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Applies [blur] behind the pane, or nothing at all on a flat theme.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.blur, required this.child});

  final ImageFilter? blur;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (blur == null) return child;
    return BackdropFilter(filter: blur!, child: child);
  }
}
