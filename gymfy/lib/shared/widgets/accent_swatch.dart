import 'package:flutter/material.dart';

/// One tappable accent colour.
///
/// Shared by onboarding and the settings screen so the two pickers can't drift
/// apart. Selection shows as a ring plus a tick rather than a size change, so
/// the swatches stay on a steady grid as the choice moves.
class AccentSwatch extends StatelessWidget {
  const AccentSwatch({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? theme.colorScheme.onSurface
                  : Colors.transparent,
              width: 3,
            ),
          ),
          child: selected
              ? Icon(Icons.check, color: theme.colorScheme.surface)
              : null,
        ),
      ),
    );
  }
}
