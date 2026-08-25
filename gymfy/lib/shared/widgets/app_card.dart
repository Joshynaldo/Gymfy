// The card look shared by the browsing screens — Exercises, Progress, More.
//
// One widget rather than a copy per screen: three lists that are visually
// almost-but-not-quite the same is the state this was built to get out of, and
// it comes back the moment each screen owns its own borders and paddings.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/accent_color.dart';

/// A tappable card, styled like the ones on the Home tab.
///
/// Colour, radius and border all come from the theme's [CardThemeData], so this
/// is the same object the Home tab draws — including the rule that only flat
/// surfaces (AMOLED) and high contrast get an outline at all. Rebuilt as an
/// [AnimatedContainer] rather than a literal [Card] purely so selection can
/// fade in; a Card snaps.
class AppCard extends ConsumerWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 8, 12),
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Escalates the border to solid accent and tints the surface.
  final bool selected;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final cardTheme = theme.cardTheme;

    // Whatever the theme says a card is. Falls back only if a future theme
    // forgets to define one.
    final shapeBorder = cardTheme.shape as RoundedRectangleBorder?;
    final shape = shapeBorder?.borderRadius as BorderRadius? ??
        BorderRadius.circular(16);
    final themeSide = shapeBorder?.side ?? BorderSide.none;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? Color.alphaBlend(
                  accent.withValues(alpha: 0.12),
                  cardTheme.color ?? theme.colorScheme.surface,
                )
              : cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: shape,
          // The accent outline is the *only* border most themes draw, and only
          // while selected — so when it appears it means "this is the one you
          // picked" rather than being decoration every card wears.
          border: Border.all(
            color: selected
                ? accent
                : (themeSide.style == BorderStyle.none
                      ? Colors.transparent
                      : themeSide.color),
            width: selected ? 1.6 : (themeSide.width == 0 ? 1 : themeSide.width),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: shape,
          child: InkWell(
            borderRadius: shape,
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// The usual contents of an [AppCard]: a glyph, a title, an optional line under
/// it, and something on the right.
class AppTile extends ConsumerWidget {
  const AppTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleTrailing,
    this.trailing = const Icon(Icons.chevron_right, size: 20),
    this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  final IconData icon;
  final String title;

  /// The muted line under the title. Omit for a one-line tile.
  final String? subtitle;

  /// Sits immediately after the title — for badges that belong to the name
  /// rather than to the row.
  final Widget? titleTrailing;

  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      onLongPress: onLongPress,
      selected: selected,
      child: Row(
        children: [
          AppGlyph(icon: icon, selected: selected),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        // The title is what you're scanning for, so it gets the
                        // weight.
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (titleTrailing != null) ...[
                      const SizedBox(width: 8),
                      titleTrailing!,
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            IconTheme.merge(
              data: IconThemeData(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
              child: trailing!,
            ),
        ],
      ),
    );
  }
}

/// The leading square of an [AppTile]: an icon, or a tick once it's picked.
class AppGlyph extends ConsumerWidget {
  const AppGlyph({super.key, required this.icon, this.selected = false});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: selected ? accent : accent.withValues(alpha: 0.13),
        // A rounded square rather than a circle: it echoes the card corners and
        // stacks into a tidier column down the left edge.
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        selected ? Icons.check : icon,
        size: 21,
        color: selected ? Colors.white : accent,
      ),
    );
  }
}

/// A plain section heading above a run of cards.
///
/// Deliberately *not* pinned to the top while scrolling: a heading that follows
/// you down the screen reads as a collapsible summary bar and invites taps that
/// do nothing.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({super.key, required this.title, this.count});

  final String title;

  /// Shown after the title when there is one — it answers "is it worth
  /// scrolling into this?" before you do.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              // Slightly tracked out: at this size it's the difference between
              // a heading and just another bold line.
              letterSpacing: 0.6,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Text(
              '$count',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
