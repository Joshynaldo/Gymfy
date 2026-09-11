// The card look shared by the browsing screens — Exercises, Progress, More.
//
// One widget rather than a copy per screen: three lists that are visually
// almost-but-not-quite the same is the state this was built to get out of, and
// it comes back the moment each screen owns its own borders and paddings.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/accent_color.dart';
import '../../app/theme/glass.dart';
import '../../app/theme/motion.dart';
import 'pressable.dart';

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
    this.tier = GlassTier.raised,
    this.outlined = false,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 8, 12),
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Which surface of the material this card is — see [GlassTier].
  ///
  /// [GlassTier.raised] for something you read, [GlassTier.quiet] for a row in
  /// a list. Ignored on the flat themes, which have one card and always have.
  final GlassTier tier;

  /// Escalates the border to solid accent and tints the surface.
  final bool selected;

  /// Draws a visible hairline right round — for a card that is one of several
  /// you choose between, where the edge is what says it can be picked.
  final bool outlined;

  final EdgeInsetsGeometry padding;

  /// Space *outside* the card. Overridable for screens whose list already
  /// carries its own horizontal padding — the default would double up there
  /// and leave the card visibly narrower than the ones on the browsing tabs.
  ///
  /// Defaults per tier, because the two are different objects: cards breathe,
  /// rows queue. Twenty-two pixels between cards is what the design uses to
  /// separate one thought from the next without a divider; ten between rows is
  /// what keeps a list reading as one list.
  final EdgeInsetsGeometry? margin;

  /// The default is Hyper's spacing only. The flat themes keep the margin they
  /// have always had — the promise on those six is that they come out of this
  /// redesign unchanged, and spacing is as visible a change as colour.
  EdgeInsetsGeometry _marginFor(bool glass) {
    if (margin != null) return margin!;
    if (!glass) return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    return tier == GlassTier.quiet
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 5)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 11);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final cardTheme = theme.cardTheme;

    // Whatever the theme says a card is. Falls back only if a future theme
    // forgets to define one.
    final shapeBorder = cardTheme.shape as RoundedRectangleBorder?;
    final shape =
        shapeBorder?.borderRadius as BorderRadius? ?? BorderRadius.circular(16);
    final themeSide = shapeBorder?.side ?? BorderSide.none;

    final glass = glassOf(context);

    // On a glass theme the card *is* a pane: the fill, the edge and the
    // highlight all come from the material rather than from the palette, and
    // the blur behind it is the point. Handing that to GlassSurface keeps the
    // decision in one place — a card does not need to know which theme is on,
    // only how a surface looks here.
    if (glass.enabled) {
      // A row is a smaller object than a card and takes a smaller corner. Same
      // radius on both makes a list of rows look like a stack of cards that
      // happen to be short.
      final paneShape = tier == GlassTier.quiet
          ? BorderRadius.circular(20)
          : shape;

      return Padding(
        padding: _marginFor(true),
        child: Pressable(
          borderRadius: paneShape,
          onTap: onTap,
          onLongPress: onLongPress,
          // No ripple anywhere on a card: the press scale has replaced it. A
          // ripple is light spreading *across* a surface and says nothing
          // about the surface having been pushed — and here the ink is painted
          // by a Material behind the pane, so on glass it would surface as a
          // smudge under the tint and on the flat themes the opaque card
          // covers it entirely. Painting ink nobody can see is pure cost.
          splash: false,
          child: GlassSurface(
            borderRadius: paneShape,
            tier: tier,
            selected: selected,
            outlined: outlined,
            // Nothing sits behind a card but the backdrop's colour field, and
            // blurring a smooth field gives back the same smooth field. See
            // GlassSurface.blurs — this is forty offscreen passes saved on a
            // scrolling list, for no visible difference.
            blurs: false,
            child: DecoratedBox(
              decoration: BoxDecoration(
                // The one thing the material does not supply: which card you
                // picked. Kept as an accent wash over the glass, so it reads
                // the same as on every other theme.
                color: selected
                    ? accent.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: paneShape,
              ),
              child: _InkHost(padding: padding, child: child),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: _marginFor(false),
      child: Pressable(
        borderRadius: shape,
        onTap: onTap,
        onLongPress: onLongPress,
        splash: false,
        child: AnimatedContainer(
          duration: AppDurations.quick,
          curve: AppCurves.settle,
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
              width: selected
                  ? 1.6
                  : (themeSide.width == 0 ? 1 : themeSide.width),
            ),
          ),
          // A hairline of light along the top edge, fading out by the middle.
          // This is the whole trick behind a surface looking like a pane of
          // something rather than a grey rectangle: real light catches the top
          // lip of a raised edge and nothing else. One gradient, no images.
          foregroundDecoration: BoxDecoration(
            borderRadius: shape,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: selected ? 0.10 : 0.055),
                Colors.white.withValues(alpha: 0),
              ],
              stops: const [0, 0.55],
            ),
          ),
          child: _InkHost(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A transparent [Material] between the card's decoration and its contents.
///
/// Needed because [ListTile] — and anything else that paints a selection tint
/// or an ink splash — draws onto the nearest Material *ancestor*. [Pressable]
/// provides one, but it sits outside the card's own decorated box, so without
/// this there is a painted surface in between and Flutter asserts that the
/// tile's background "may be invisible". It is right: it would be.
///
/// The card had one of these before the press animation moved the Material
/// outwards. This puts it back where the contents can find it.
class _InkHost extends StatelessWidget {
  const _InkHost({required this.padding, required this.child});

  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Padding(padding: padding, child: child),
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
    this.leading,
  });

  final IconData icon;

  /// Replaces the [AppGlyph] built from [icon].
  ///
  /// For rows that have something better to show than a symbol — the exercise
  /// library puts a still of the movement here. It is expected to be the same
  /// 42px square, so the column down the left edge stays straight, and to
  /// handle [selected] itself.
  final Widget? leading;

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
      // A tile is a row in a list, not a card: dimmer fill, no shadow, tighter
      // corner. It is the difference between a library of seventy-eight entries
      // reading as a list and reading as seventy-eight competing surfaces.
      tier: GlassTier.quiet,
      // Even padding on a row, unlike a card's: the chevron on the right is
      // optical weight of its own, and the card default trims the right side to
      // compensate for a trailing control that is usually a button. Here it
      // just leaves the row looking as though it had slipped.
      padding: glassOf(context).enabled
          ? const EdgeInsets.fromLTRB(18, 16, 18, 16)
          : const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: Row(
        children: [
          leading ?? AppGlyph(icon: icon, selected: selected),
          const SizedBox(width: 15),
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
                        // A row's name, not a heading. On Hyper that is 15 at
                        // medium weight: a list of seventy-eight of these at
                        // heading size is a list with no hierarchy in it, and
                        // the section headers above them stop meaning anything.
                        style: glassOf(context).enabled
                            ? theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              )
                            : theme.textTheme.titleSmall?.copyWith(
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
                    style:
                        (glassOf(context).enabled
                                ? theme.textTheme.labelMedium
                                : theme.textTheme.bodySmall)
                            ?.copyWith(
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
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final glass = glassOf(context);

    // On glass the resting glyph is neutral, not accent.
    //
    // The rule is one accent per screen, on the thing that matters — and a
    // column of nine accent squares down the side of the More tab breaks it
    // nine times over. Worse, it spends the accent on the least important part
    // of each row: you pick these by their label. Picked is still accent,
    // because that genuinely is the thing that matters at that moment.
    final restingFill = glass.enabled
        ? Colors.white.withValues(alpha: 0.08)
        : accent.withValues(alpha: 0.13);
    final restingInk = glass.enabled
        ? theme.colorScheme.onSurfaceVariant
        : accent;

    return AnimatedContainer(
      duration: AppDurations.quick,
      curve: AppCurves.settle,
      width: glass.enabled ? 40 : 42,
      height: glass.enabled ? 40 : 42,
      decoration: BoxDecoration(
        color: selected ? accent : restingFill,
        // A rounded square rather than a circle: it echoes the card corners and
        // stacks into a tidier column down the left edge.
        borderRadius: BorderRadius.circular(13),
        border: glass.enabled && !selected
            ? Border.all(color: Colors.white.withValues(alpha: 0.10))
            : null,
      ),
      child: Icon(
        selected ? Icons.check : icon,
        size: 21,
        color: selected ? Colors.white : restingInk,
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
  const AppSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.countLabel,
  });

  final String title;

  /// Shown after the title when there is one — it answers "is it worth
  /// scrolling into this?" before you do.
  final int? count;

  /// The same slot, in words: "4 workouts" rather than a bare "4". For headings
  /// where the number needs a noun to mean anything.
  final String? countLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = glassOf(context);

    return Padding(
      // Thirty-four above, fourteen below — the numbers the design separates
      // sections by, less the card margin that follows it. Air above a heading
      // is what makes it read as the start of something rather than a label
      // stuck on the card beneath it.
      padding: glass.enabled
          ? const EdgeInsets.fromLTRB(20, 23, 20, 3)
          : const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Row(
        children: [
          // Expanded rather than a bare Text plus a Spacer. Two unconstrained
          // labels in one Row is a horizontal overflow waiting for a long
          // heading, a wide count, a narrow phone or larger text — and with
          // all four it does not need to be close. The title is the half that
          // gives, because the count beside it is short and fixed.
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                // Slightly tracked out on the flat themes: at that size it is
                // the difference between a heading and just another bold line.
                // Hyper gets its separation from the scale instead — 17 against
                // 15 — and tracking on top of that reads as shouting.
                letterSpacing: glass.enabled ? null : 0.6,
              ),
            ),
          ),
          if (count != null || countLabel != null) ...[
            const SizedBox(width: 12),
            Text(
              countLabel ?? '$count',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A card that holds content rather than a row — a chart, a form, a result.
///
/// The counterpart to [AppTile]. Several screens had grown their own version of
/// this: a `Container` with `surfaceContainerHighest` and a radius picked by
/// hand, which is a card that ignores the theme. On AMOLED it kept a grey
/// surface the rest of the app had dropped, and on High Contrast it skipped the
/// outline every other card draws. Routing it through [AppCard] means there is
/// one answer to "what does a surface look like here".
class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.icon,
    this.title,
    this.subtitle,
    this.trailing,
    this.margin = const EdgeInsets.symmetric(vertical: 6),
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;

  /// Optional heading. Omit all three for a bare surface.
  final IconData? icon;
  final String? title;
  final String? subtitle;

  /// Sits at the right of the heading row — a value, a badge, a small action.
  final Widget? trailing;

  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasHeading = title != null || icon != null;

    return AppCard(
      margin: margin,
      padding: padding,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHeading) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                ],
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                ?trailing,
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}
