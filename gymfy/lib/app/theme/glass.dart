import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// How glassy a theme's surfaces are.
///
/// Carried on [ThemeData] as an extension rather than checked against a theme
/// enum in every widget. A card should not have to know which theme is on — it
/// asks the theme how a surface looks here and draws that. Adding a second
/// glass theme later is then a palette, not a hunt through thirty screens for
/// `if (theme == hyper)`.
///
/// [enabled] is false for every flat theme, and [GlassSurface] falls straight
/// through to an ordinary opaque box. That is the whole compatibility story:
/// existing themes are untouched.
@immutable
class GlassStyle extends ThemeExtension<GlassStyle> {
  const GlassStyle({
    required this.enabled,
    required this.blur,
    required this.tint,
    required this.highlight,
    required this.edge,
  });

  /// The flat themes. Nothing blurs, nothing is translucent.
  const GlassStyle.off()
    : enabled = false,
      blur = 0,
      tint = const Color(0x00000000),
      highlight = const Color(0x00000000),
      edge = const Color(0x00000000);

  final bool enabled;

  /// Gaussian sigma behind the surface. Large enough that what shows through is
  /// colour and movement rather than legible content — a surface you can read
  /// the screen through is a window, not a material.
  final double blur;

  /// The translucent fill laid over the blur. Without it the blur alone is a
  /// smear; the tint is what gives the pane a body.
  final Color tint;

  /// The specular line along the top edge. This is the single detail that most
  /// makes a surface read as glass rather than as a grey rectangle: real light
  /// catches the top lip of a raised edge and almost nothing else.
  final Color highlight;

  /// The hairline around the whole pane, holding its shape against a busy
  /// backdrop.
  final Color edge;

  @override
  GlassStyle copyWith({
    bool? enabled,
    double? blur,
    Color? tint,
    Color? highlight,
    Color? edge,
  }) {
    return GlassStyle(
      enabled: enabled ?? this.enabled,
      blur: blur ?? this.blur,
      tint: tint ?? this.tint,
      highlight: highlight ?? this.highlight,
      edge: edge ?? this.edge,
    );
  }

  @override
  GlassStyle lerp(GlassStyle? other, double t) {
    if (other == null) return this;
    return GlassStyle(
      // Not interpolated: half-enabled glass is a surface that is neither, and
      // the theme switch is instant anyway.
      enabled: t < 0.5 ? enabled : other.enabled,
      blur: blur + (other.blur - blur) * t,
      tint: Color.lerp(tint, other.tint, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      edge: Color.lerp(edge, other.edge, t)!,
    );
  }
}

/// The glass style in force, or [GlassStyle.off] on a flat theme.
GlassStyle glassOf(BuildContext context) =>
    Theme.of(context).extension<GlassStyle>() ?? const GlassStyle.off();

/// How much of a screen the floating bars cover, top and bottom.
///
/// On a glass theme the body is laid out *behind* the app bar and the
/// navigation pill rather than between them, so a list runs the full height of
/// the screen and slides under both. That is the whole point — it is what gives
/// the bars something to blur, and a translucent bar with nothing passing under
/// it is just a tinted rectangle. It also means a list with no padding would
/// begin underneath the title and end underneath the pill.
///
/// Scaffold already works the numbers out and hands them to the body as
/// `MediaQuery.padding`; this reads them back so a scrollable can add them to
/// whatever padding it wanted anyway:
///
/// ```dart
/// padding: const EdgeInsets.only(top: 6, bottom: 24) + barInsets(context),
/// ```
///
/// Returns nothing at all on the flat themes, where the bars are opaque, the
/// body is laid out between them as it always was, and there is nothing to
/// clear. That is deliberate: those six themes should come out of this
/// byte-for-byte unchanged.
EdgeInsets barInsets(BuildContext context) =>
    glassOf(context).enabled ? MediaQuery.paddingOf(context) : EdgeInsets.zero;

/// The top half of [barInsets], for the screen itself to hold a fixed header
/// clear of the app bar.
///
/// Several screens put something unscrollable at the top — a day stepper, a
/// search field — and those must *not* slide under the bar: a header pinned
/// half-legible behind a translucent title is worse than no effect at all. The
/// screen pads itself down by this, and only the list below it scrolls under.
EdgeInsets topBarInset(BuildContext context) =>
    EdgeInsets.only(top: barInsets(context).top);

/// The bottom half of [barInsets], for the scrollable under such a header —
/// its top is already taken care of by the screen.
EdgeInsets bottomBarInset(BuildContext context) =>
    EdgeInsets.only(bottom: barInsets(context).bottom);

/// A pane of the current theme's material.
///
/// On a glass theme: a translucent tint, a hairline edge, a specular highlight
/// along the top, and — for the panes that overlap content — a blur of whatever
/// is behind them. On every other theme it is an ordinary opaque box in
/// [fallbackColor], which is what those themes have always drawn.
///
/// The blur is the expensive half and the optional one; see [blurs]. It is an
/// offscreen pass per pane, so it belongs on surfaces that cover something,
/// never on every row. On the older Android hardware this app targets, a list
/// of forty blurring rows is where it would fall over; a list of forty rows
/// inside one blurring panel is fine.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    required this.borderRadius,
    this.fallbackColor,
    this.selected = false,
    this.clip = true,
    this.blurs = true,
  });

  final Widget child;
  final BorderRadius borderRadius;

  /// What to paint on a flat theme. Defaults to the theme's card colour.
  final Color? fallbackColor;

  /// Lifts the tint and the edge — the pane catches more light when picked.
  final bool selected;

  /// Off for panes whose child must draw outside them (a popup, a shadow).
  final bool clip;

  /// Whether there is anything behind this pane worth blurring.
  ///
  /// Not a style choice — a factual one, and the difference between a cheap
  /// screen and an expensive one. A card laid directly on the backdrop has
  /// nothing behind it but a smooth colour field, and blurring a smooth field
  /// returns the same smooth field: an offscreen render pass per card that
  /// changes not one pixel. A list of forty of those is forty wasted passes on
  /// hardware that can least afford them.
  ///
  /// Turn it on for the panes that genuinely overlap content — sheets and
  /// dialogs over a screen, the navigation bar with a list running underneath
  /// it. That is where the blur is the whole effect.
  final bool blurs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = glassOf(context);
    final surface =
        fallbackColor ?? theme.cardTheme.color ?? theme.colorScheme.surface;

    if (!glass.enabled) {
      return DecoratedBox(
        decoration: BoxDecoration(color: surface, borderRadius: borderRadius),
        child: child,
      );
    }

    final pane = Container(
      decoration: BoxDecoration(
        color: selected ? Color.alphaBlend(glass.tint, glass.tint) : glass.tint,
        borderRadius: borderRadius,
        border: Border.all(
          color: selected ? glass.edge.withValues(alpha: 0.9) : glass.edge,
        ),
      ),
      // The highlight is drawn over the child, not under it: it is light on the
      // surface of the pane, and anything inside sits beneath that surface.
      foregroundDecoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [glass.highlight, glass.highlight.withValues(alpha: 0)],
          stops: const [0, 0.45],
        ),
      ),
      child: child,
    );

    if (!clip) return pane;
    if (!blurs) return ClipRRect(borderRadius: borderRadius, child: pane);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: glass.blur, sigmaY: glass.blur),
        child: pane,
      ),
    );
  }
}
