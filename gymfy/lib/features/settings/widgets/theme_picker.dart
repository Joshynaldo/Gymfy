import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../app/theme/app_theme.dart';

/// Picks the app theme, with a preview of each option.
///
/// Each row shows that theme's actual background, card and text colours next to
/// the current accent, so you can see what you're choosing before you choose it.
/// Selecting applies immediately app-wide — this screen re-themes under your
/// finger, which is the most honest preview there is.
class ThemePicker extends ConsumerWidget {
  const ThemePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appThemeProvider);
    final accent = ref.watch(accentColorProvider);

    // Offered only when the theme has a matching accent and you aren't already
    // on it. Applying it silently would overrule a colour you chose on purpose.
    final suggested = current.suggestedAccent;
    final offerAccent = suggested != null && suggested != accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final theme in AppTheme.values)
          _ThemeRow(
            theme: theme,
            accent: accent,
            selected: theme == current,
            onTap: () => setAppTheme(ref, theme),
          ),
        if (offerAccent)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${current.label} was designed around its own accent.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () =>
                      ref.read(accentColorProvider.notifier).setAccent(suggested),
                  child: const Text('Use it'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({
    required this.theme,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final AppTheme theme;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // A plain tile with a check rather than a RadioListTile: the swatch is
      // already the visual anchor, and a radio dot next to it is two controls
      // saying the same thing.
      onTap: onTap,
      selected: selected,
      leading: _Swatch(palette: theme.palette, accent: accent),
      title: Text(theme.label),
      subtitle: Text(theme.description),
      trailing: selected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
    );
  }
}

/// A miniature of the theme: its background, a card on top, a line of text, and
/// the accent. Drawn in the theme's own colours rather than the active ones —
/// the point is to show what you'd be switching *to*.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.palette, required this.accent});

  final AppPalette palette;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.outline),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: palette.outline, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            _Bar(color: palette.textPrimary, width: 18),
            const SizedBox(height: 3),
            _Bar(color: palette.textMuted, width: 12),
            const SizedBox(height: 4),
            _Bar(color: accent, width: 14),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Container(
        width: width,
        height: 2.5,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
