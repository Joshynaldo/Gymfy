import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../app/theme/glass.dart';

/// A dialog in whatever the current theme calls a surface.
///
/// On the flat themes this *is* an [AlertDialog] — same object, same layout,
/// nothing changed. On Hyper it becomes a pane floating over a blurred copy of
/// the screen behind it.
///
/// A dialog is one of the few surfaces where the blur is not a flourish but the
/// point. It genuinely covers content, so blurring is doing real work: it holds
/// on to the sense that the screen is still there underneath while making sure
/// none of it competes with the question being asked. This and the picker sheet
/// are where the material is at its most literal.
///
/// The fill is much heavier than a card's — the palette's own surface at 82%
/// rather than a few percent of white. Text sits directly on this, over moving
/// content, and a card's tint would leave it unreadable. Glass you can read a
/// paragraph through is a window.
class GlassDialog extends StatelessWidget {
  const GlassDialog({super.key, this.title, this.content, this.actions});

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = glassOf(context);

    if (!glass.enabled) {
      return AlertDialog(title: title, content: content, actions: actions);
    }

    return Dialog(
      // The pane below draws the surface; leaving Material's own here would
      // paint an opaque rectangle over the blur it is meant to sit on.
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: glass.blur, sigmaY: glass.blur),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: glass.edge),
            ),
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null) ...[
                  DefaultTextStyle(
                    style: theme.textTheme.titleLarge!,
                    child: title!,
                  ),
                  const SizedBox(height: 16),
                ],
                if (content != null)
                  // Flexible, not Expanded: the dialog is only as tall as it
                  // needs to be, but a long form still scrolls inside itself
                  // rather than overflowing off the screen.
                  Flexible(
                    child: SingleChildScrollView(
                      child: DefaultTextStyle(
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        child: content!,
                      ),
                    ),
                  ),
                if (actions != null) ...[
                  const SizedBox(height: 8),
                  // The same widget AlertDialog uses, so buttons that do not
                  // fit side by side stack instead of being clipped.
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    spacing: 8,
                    overflowAlignment: OverflowBarAlignment.end,
                    children: actions!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
