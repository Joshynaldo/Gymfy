import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../app/theme/glass.dart';
import '../../app/theme/motion.dart';
import 'pressable.dart';

/// One choice in an [AppSegmented].
typedef Segment<T> = ({T value, String label, Widget? leading});

/// A row of mutually exclusive choices, in the shape the design draws.
///
/// A track holding equal-width segments, with the chosen one lifted out of it
/// in a lighter fill. The alternative — Material's `SegmentedButton` — draws an
/// outlined capsule with a tick inside the selected segment, which is a lot of
/// furniture for "which of these three am I looking at", and its outline reads
/// as a second card edge when it sits on a pane.
///
/// Deliberately not accent-coloured. These pick a *view*, and the accent is
/// reserved for the thing on the screen that matters; a highlighted segment
/// competing with the number it is filtering is the wrong way round.
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.height = 34,
  });

  final List<Segment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = glassOf(context);
    final ink = theme.colorScheme.onSurface;

    return GlassSurface(
      borderRadius: BorderRadius.circular(15),
      tier: GlassTier.quiet,
      fallbackColor: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            for (final segment in segments)
              Expanded(
                child: Pressable(
                  borderRadius: BorderRadius.circular(12),
                  splash: false,
                  onTap: () {
                    if (segment.value == selected) return;
                    // The one control on these screens you hit without looking
                    // at it, because you already know which of three you want.
                    HapticFeedback.selectionClick();
                    onChanged(segment.value);
                  },
                  child: AnimatedContainer(
                    duration: motionOf(context, AppDurations.quick),
                    curve: AppCurves.settle,
                    height: height,
                    decoration: BoxDecoration(
                      color: segment.value == selected
                          ? ink.withValues(alpha: glass.enabled ? 0.14 : 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (segment.leading != null) ...[
                          segment.leading!,
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              segment.label,
                              maxLines: 1,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 13.5,
                                // Weight carries the selection as well as
                                // colour: on a bright backdrop the fill alone
                                // can be hard to place.
                                fontWeight: segment.value == selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: segment.value == selected
                                    ? ink
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// An [AppSegmented] sized to sit under an app bar title.
///
/// In the bar rather than in the list, so it survives the scroll: these choose
/// what the whole screen is showing, and a control that scrolls away takes the
/// only way back with it.
class SegmentedBar<T> extends StatelessWidget implements PreferredSizeWidget {
  const SegmentedBar({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<Segment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: AppSegmented<T>(
        segments: segments,
        selected: selected,
        onChanged: onChanged,
      ),
    );
  }
}
