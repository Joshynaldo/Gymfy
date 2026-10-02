import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The icons drawn for the Gymfy Hyper design, where the app shows them
/// most: the four tabs and the tools on the More tab.
///
/// Kept as the design's own SVG paths rather than swapped for the nearest
/// font icon. Everything else in the app uses Lucide (`LucideIcons`), which is
/// drawn in the same style: a round-capped line about two pixels wide on a
/// 24px grid, which these match at 1.6–1.7 on a 20px one. The two sit side by
/// side without the seam the old filled Material icons left.
///
/// [weekly] and [import] aren't in the design; they are drawn to match it.
enum MockupGlyph {
  home(
    '<path d="M2.6 8.4L10 2.6l7.4 5.8v8.2a.8.8 0 01-.8.8h-4V12h-5v5.4h-4a.8.8 0 01-.8-.8z" stroke-width="1.7"/>',
  ),
  workout(
    '<path d="M4.4 7v6M2.2 8.4v3.2M15.6 7v6M17.8 8.4v3.2M4.4 10h11.2" stroke-width="1.7"/>',
  ),
  progress(
    '<path d="M2.4 14.2l4.4-4.6 3.4 2.8 7.4-7.6" stroke-width="1.7"/><path d="M13.4 4.8h4.2V9" stroke-width="1.7"/>',
  ),
  more(
    '<circle cx="4" cy="10" r="1.7" fill="#000" stroke="none"/><circle cx="10" cy="10" r="1.7" fill="#000" stroke="none"/><circle cx="16" cy="10" r="1.7" fill="#000" stroke="none"/>',
  ),
  library(
    '<path d="M10 5.4C8.6 4 6.6 3.6 3.4 3.6v10.6c3.2 0 5.2.4 6.6 1.8 1.4-1.4 3.4-1.8 6.6-1.8V3.6c-3.2 0-5.2.4-6.6 1.8z"/><path d="M10 5.4v10.6"/>',
  ),
  calories(
    '<path d="M5.4 2.6v5.2a1.8 1.8 0 003.6 0V2.6M7.2 8v9.4M13.4 2.6c-1.2 1.4-1.6 3-1.6 4.6 0 1.2.6 2 1.6 2.2v8M13.4 2.6c1.2 1.4 1.6 3 1.6 4.6 0 1.2-.6 2-1.6 2.2"/>',
  ),
  weekly(
    '<path d="M4.6 16.4v-5M8.2 16.4V7.2M11.8 16.4v-7.4M15.4 16.4V4.6M3 16.4h14"/>',
  ),
  oneRm(
    '<rect x="3.6" y="2.4" width="12.8" height="15.2" rx="2.2"/><path d="M6.4 6h7.2M6.6 10h.02M10 10h.02M13.4 10h.02M6.6 13.6h.02M10 13.6h.02M13.4 13.6h.02"/>',
  ),
  rank(
    '<circle cx="10" cy="12.6" r="4.6"/><path d="M7.4 8.2L5.2 2.6h9.6l-2.2 5.6M10 10.4v4.4"/>',
  ),
  share(
    '<path d="M10 2.6v8.8M6.8 5.8L10 2.6l3.2 3.2"/><path d="M4.6 11v4.6a1.8 1.8 0 001.8 1.8h7.2a1.8 1.8 0 001.8-1.8V11"/>',
  ),
  import(
    '<path d="M10 2.6v8.8M6.8 8.2L10 11.4l3.2-3.2"/><path d="M4.6 11v4.6a1.8 1.8 0 001.8 1.8h7.2a1.8 1.8 0 001.8-1.8V11"/>',
  ),
  settings(
    '<circle cx="10" cy="10" r="2.6"/><path d="M10 2.4v2M10 15.6v2M3.6 10h2M14.4 10h2M5.5 5.5l1.4 1.4M13.1 13.1l1.4 1.4M14.5 5.5l-1.4 1.4M6.9 13.1l-1.4 1.4"/>',
  ),
  help(
    '<circle cx="10" cy="10" r="7.2"/><path d="M7.9 7.6a2.1 2.1 0 114.1.7c-.2.9-1.2 1.3-1.7 1.9-.3.4-.3.8-.3 1.2"/><path d="M10 14.3h.02"/>',
  );

  const MockupGlyph(this.paths);

  /// The shapes inside a 20 × 20 viewBox, stroked unless they say otherwise.
  final String paths;

  /// The whole document, in black: [GlyphIcon] recolours it as it paints.
  String get svg =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="none" '
      'stroke="#000" stroke-width="1.6" stroke-linecap="round" '
      'stroke-linejoin="round">$paths</svg>';
}

/// Draws a [MockupGlyph] the way an [Icon] draws a font glyph: at the
/// ambient [IconTheme]'s size and colour unless told otherwise, so it drops
/// into anything that styles its icons through the theme — the navigation
/// bar's selected and unselected states, for one.
class GlyphIcon extends StatelessWidget {
  const GlyphIcon(
    this.glyph, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final MockupGlyph glyph;
  final double? size;
  final Color? color;

  /// Read out by screen readers. Null for a decorative icon, which is most of
  /// them: the label next to it already says what it is.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? 24;
    final ink = color ?? theme.color ?? Colors.white;
    final opacity = theme.opacity ?? 1;
    return SizedBox.square(
      dimension: side,
      child: SvgPicture.string(
        glyph.svg,
        width: side,
        height: side,
        colorFilter: ColorFilter.mode(
          ink.withValues(alpha: ink.a * opacity),
          BlendMode.srcIn,
        ),
        semanticsLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
      ),
    );
  }
}
