import 'package:flutter/material.dart';

import '../../app/theme/glass.dart';
import 'pressable.dart';

/// A filter pill.
///
/// Not a [FilterChip] on the glass themes, and not for want of trying to style
/// one: Material's chip wraps its own background in a [Material] of the default
/// `MaterialType.canvas`, which paints an *opaque* `canvasColor` underneath.
/// On a solid theme you never see it, because the canvas is the same colour as
/// everything else. Here it comes out as a solid black pill with the glass
/// sitting uselessly on top of it — which is exactly what the Exercises tab was
/// showing. So this draws the pane itself.
///
/// Falls through to a real [FilterChip] on the flat themes, where Material's
/// own look is the right one and the canvas is genuinely the background.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;

  /// Null for a pill that already shows what it would select — "All" while
  /// nothing is filtered. It still reads as on; it just doesn't answer.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!glassOf(context).enabled) {
      // A pill that neither answers nor claims to be picked isn't a filter at
      // all — it's a label, and Material has one of those. Sending it through
      // FilterChip would grey it out as "disabled", which says the wrong thing
      // about a list of muscles an exercise simply works.
      if (onTap == null && !selected) {
        return Chip(label: Text(label), visualDensity: VisualDensity.compact);
      }
      return FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: onTap == null ? null : (_) => onTap!(),
      );
    }

    final radius = BorderRadius.circular(13);

    return Pressable(
      borderRadius: radius,
      onTap: onTap,
      splash: false,
      child: GlassSurface(
        borderRadius: radius,
        tier: GlassTier.quiet,
        selected: selected,
        child: Padding(
          // Vertical 10 against the bar's 44 leaves the pill 40 tall, the same
          // height Material's chip lands at — the row keeps its rhythm.
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 13,
              // A picked filter is stated, not shouted: the pane is already
              // brighter, so the weight only has to confirm it.
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
