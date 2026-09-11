import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../app/theme/app_theme.dart';

/// Picks the app theme from a dropdown, with a preview of each option.
///
/// A dropdown rather than seven stacked rows: the list was the tallest thing in
/// Settings by a distance, and it was showing six options you aren't using to
/// tell you about the one you are. Collapsed, the current theme and its swatch
/// stay visible, which is the part worth keeping on screen.
///
/// Each entry still shows that theme's actual background, card and text colours
/// next to the current accent. Selecting applies immediately app-wide — this
/// screen re-themes under your finger, which is the most honest preview there
/// is.
class ThemePicker extends ConsumerWidget {
  const ThemePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final current = ref.watch(appThemeProvider);
    final accent = ref.watch(accentColorProvider);

    // Offered only when the theme has a matching accent and you aren't already
    // on it. Applying it silently would overrule a colour you chose on purpose.
    final suggested = current.suggestedAccent;
    final offerAccent = suggested != null && suggested != accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: DropdownButtonFormField<AppTheme>(
            initialValue: current,
            isExpanded: true,
            // Two lines of text plus the swatch don't fit the 48px default, and
            // the overflow shows as a yellow-striped bar rather than clipping
            // quietly.
            itemHeight: 60,
            borderRadius: BorderRadius.circular(14),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHigh,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            // The closed field shows only the swatch and the name; the
            // description would be clipped to one line and read as noise.
            selectedItemBuilder: (context) => [
              for (final option in AppTheme.values)
                _ClosedRow(theme: option, accent: accent),
            ],
            items: [
              for (final option in AppTheme.values)
                DropdownMenuItem(
                  value: option,
                  child: _OpenRow(theme: option, accent: accent),
                ),
            ],
            onChanged: (chosen) {
              if (chosen != null) setAppTheme(ref, chosen);
            },
          ),
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
                  onPressed: () => ref
                      .read(accentColorProvider.notifier)
                      .setAccent(suggested),
                  child: const Text('Use it'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// What the dropdown shows while closed: swatch and name only.
class _ClosedRow extends StatelessWidget {
  const _ClosedRow({required this.theme, required this.accent});

  final AppTheme theme;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Swatch(palette: theme.palette, accent: accent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            theme.label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

/// One option in the open menu: swatch, name, and what the theme is for.
class _OpenRow extends StatelessWidget {
  const _OpenRow({required this.theme, required this.accent});

  final AppTheme theme;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        _Swatch(palette: theme.palette, accent: accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(theme.label, style: textTheme.bodyLarge),
              Text(
                theme.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
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

  /// How much room the swatch takes. Smaller inside the dropdown than it was
  /// as a list tile, so a row of it plus two lines of text fits a menu item.
  static const size = 38.0;

  /// The size the miniature is actually drawn at before scaling. Fixed so the
  /// bars keep their proportions however small [size] gets.
  static const _drawn = 44.0;

  @override
  Widget build(BuildContext context) {
    // Scaled rather than laid out at [size] directly: the bars inside are a
    // few pixels tall each, and squeezing the box even slightly overflows them
    // into a yellow-striped error bar. A dropdown gives its rows whatever
    // height it likes, so the swatch has to survive being handed less than it
    // asked for.
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(fit: BoxFit.contain, child: _miniature()),
    );
  }

  Widget _miniature() {
    return Container(
      width: _drawn,
      height: _drawn,
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
