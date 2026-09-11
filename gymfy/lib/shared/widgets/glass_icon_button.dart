import 'package:flutter/material.dart';

import '../../app/theme/glass.dart';
import 'pressable.dart';

/// An app-bar action as a small pane of the material.
///
/// A bare [IconButton] on a glass theme is a glyph floating on the backdrop
/// with nothing under it — fine on a solid bar, but this app's bar paints
/// nothing at rest, so the icon ends up sitting directly on the drifting field
/// and reads as decoration rather than a control. A pane under it gives it an
/// edge, which is what makes it look like something you can press.
///
/// Falls through to an ordinary [IconButton] on the flat themes, where the bar
/// is opaque and the glyph already has a surface behind it.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!glassOf(context).enabled) {
      return IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      );
    }

    final radius = BorderRadius.circular(13);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: Pressable(
          borderRadius: radius,
          onTap: onPressed,
          splash: false,
          child: GlassSurface(
            borderRadius: radius,
            tier: GlassTier.quiet,
            child: SizedBox(
              // 36 rather than Material's 48: the pane is the visible target
              // and a 48px one would crowd the title beside it. The press area
              // stays comfortable because there is nothing else up there to
              // hit by mistake.
              width: 36,
              height: 36,
              child: Icon(icon, size: 18, color: theme.colorScheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
