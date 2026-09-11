import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/accent_color.dart';
import '../../app/theme/motion.dart';
import 'pressable.dart';

/// How loud a button is.
enum AppButtonKind {
  /// The one thing this screen is for: starting the workout, saving the set.
  /// Accent-filled, and there should be at most one on screen — the rule the
  /// whole design runs on is a single accent, on the thing that matters.
  primary,

  /// Everything else. A pane-coloured surface with a hairline, so it reads as
  /// an object without competing with the accent one.
  secondary,
}

/// A full-width action, in the shape the design draws.
///
/// Taller than Material's default on purpose: 54px for the primary, 50 for a
/// secondary. This app is used one-handed with a bar chalked on your palms, and
/// Material's 40px button is sized for a mouse-adjacent world.
///
/// The primary is not just a coloured rectangle. It carries a light gradient
/// over the fill — bright at the top lip, a little shade at the foot — and a
/// coloured glow beneath it. That is what makes it read as lit rather than
/// painted, and it is the same treatment as the glass panes it sits among.
class AppButton extends ConsumerWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconAfter = false,
    this.kind = AppButtonKind.primary,
    this.height,
    this.expand = true,
  });

  final String label;

  /// Null disables the button: it dims and stops taking taps, rather than
  /// disappearing. A control that vanishes takes the explanation with it.
  final VoidCallback? onPressed;

  final IconData? icon;

  /// Puts the glyph after the label instead of before it.
  ///
  /// Which side it sits on is not decoration: a glyph before the label
  /// describes the action ("play" — start this), one after it points at what
  /// happens next ("Next: reps ›"). A chevron on the left would be telling you
  /// to go back.
  final bool iconAfter;

  final AppButtonKind kind;

  /// Overridable for the few places the design draws a shorter one.
  final double? height;

  /// Whether the button fills the width it is given.
  ///
  /// True for the action a screen is *for* — it sits in the flow, spans the
  /// content, and there is only one. False for one that floats over the
  /// content, where filling the width would make it a bar rather than a
  /// button, and would cover what is underneath it into the bargain.
  final bool expand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final primary = kind == AppButtonKind.primary;
    final radius = BorderRadius.circular(primary ? 18 : 16);
    final enabled = onPressed != null;

    final ink = primary ? Colors.white : theme.colorScheme.onSurface;

    return Pressable(
      borderRadius: radius,
      onTap: onPressed,
      // The press scale is the feedback; a ripple on top of it is two answers
      // to one tap.
      splash: false,
      child: AnimatedOpacity(
        duration: motionOf(context, AppDurations.quick),
        opacity: enabled ? 1 : 0.45,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: primary && enabled
                ? [
                    // The glow. Tight and offset downward, in the accent itself
                    // — this is the button appearing to sit above the field
                    // rather than in it.
                    BoxShadow(
                      color: accent.withValues(alpha: 0.45),
                      blurRadius: 26,
                      spreadRadius: -10,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Container(
            height: height ?? (primary ? 54 : 50),
            // A floating button pads its own sides; one that spans the content
            // gets its width from the layout instead.
            padding: expand ? null : const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: primary
                  ? accent
                  : theme.colorScheme.onSurface.withValues(alpha: 0.10),
              borderRadius: radius,
              border: primary
                  ? null
                  : Border.all(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.16,
                      ),
                    ),
            ),
            // Light across the fill rather than a flat block of colour. Drawn
            // over the label, like the specular edge on a glass pane: it is on
            // the surface, and the text is under it.
            foregroundDecoration: primary
                ? BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.26),
                        Colors.white.withValues(alpha: 0.04),
                        Colors.black.withValues(alpha: 0.10),
                      ],
                      stops: const [0, 0.42, 1],
                    ),
                  )
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (icon != null && !iconAfter) ...[
                  Icon(icon, size: 17, color: ink),
                  const SizedBox(width: 9),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style:
                          (primary
                                  ? theme.textTheme.titleSmall
                                  : theme.textTheme.labelLarge)
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: ink,
                              ),
                    ),
                  ),
                ),
                if (icon != null && iconAfter) ...[
                  const SizedBox(width: 7),
                  Icon(icon, size: 17, color: ink),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
