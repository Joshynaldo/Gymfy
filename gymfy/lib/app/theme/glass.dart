import 'dart:ui' show ColorFilter, ImageFilter, PathOperation;

import 'package:flutter/material.dart';

/// Which of the four surfaces in the material a pane is.
///
/// Not a style knob — a position in the hierarchy. The design draws exactly
/// four, and a screen that needs a fifth is usually a screen that has picked
/// the wrong one of these.
enum GlassTier {
  /// Cards and panels: the things you read. The brightest fill, the lit lip,
  /// and a shadow to lift them off the field.
  raised,

  /// Rows and secondary surfaces — a library entry, a More item. Deliberately
  /// dimmer and flatter than [raised]: a list of forty equals is a list with no
  /// hierarchy, and a row is a target rather than a thing to read.
  quiet,

  /// The navigation pill and the app bar. Sits over moving content, so it has
  /// an opaque floor under the tint and is one of the few panes that blurs.
  bar,

  /// Bottom sheets and dialogs. The heaviest fill in the app — text sits on it
  /// directly, over content that is still there underneath.
  sheet,
}

/// One surface of the material.
///
/// A three-stop vertical gradient rather than a flat tint. That is the single
/// biggest difference between a pane that reads as glass and one that reads as
/// a translucent rectangle: real glass is brighter where it catches the light
/// at the top, dips through the middle, and picks up a little bounce at the
/// bottom. A flat fill has none of that, and no amount of blur rescues it.
@immutable
class GlassPane {
  const GlassPane({
    required this.fill,
    required this.stops,
    required this.edge,
    required this.topEdge,
    this.base,
    this.blur = 0,
    this.shadow = const [],
  });

  const GlassPane.none()
    : fill = const [Color(0x00000000), Color(0x00000000)],
      stops = const [0, 1],
      edge = const Color(0x00000000),
      topEdge = const Color(0x00000000),
      base = null,
      blur = 0,
      shadow = const [];

  /// The gradient, top to bottom.
  final List<Color> fill;
  final List<double> stops;

  /// The hairline around the pane, holding its shape against a busy backdrop.
  final Color edge;

  /// The same hairline where it runs along the top lip, which is where light
  /// actually catches a raised edge. Drawn as one stroke with a gradient rather
  /// than as a separate overlaid highlight: a real edge is lit, not painted on.
  final Color topEdge;

  /// An opaque floor under the gradient, for panes that cover moving content.
  /// Without it the blur alone lets text read through from below.
  final Color? base;

  /// Gaussian sigma behind the pane. Zero for the panes with nothing behind
  /// them but the backdrop — see [GlassSurface.blurs].
  final double blur;

  final List<BoxShadow> shadow;

  static GlassPane lerp(GlassPane a, GlassPane b, double t) {
    return GlassPane(
      fill: [
        for (var i = 0; i < a.fill.length && i < b.fill.length; i++)
          Color.lerp(a.fill[i], b.fill[i], t)!,
      ],
      stops: t < 0.5 ? a.stops : b.stops,
      edge: Color.lerp(a.edge, b.edge, t)!,
      topEdge: Color.lerp(a.topEdge, b.topEdge, t)!,
      base: Color.lerp(a.base, b.base, t),
      blur: a.blur + (b.blur - a.blur) * t,
      shadow: BoxShadow.lerpList(a.shadow, b.shadow, t) ?? const [],
    );
  }
}

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
    required this.raised,
    required this.quiet,
    required this.bar,
    required this.sheet,
    required this.scrim,
    this.saturation = 1,
    this.brightness = 1,
  });

  /// The flat themes. Nothing blurs, nothing is translucent.
  const GlassStyle.off()
    : enabled = false,
      raised = const GlassPane.none(),
      quiet = const GlassPane.none(),
      bar = const GlassPane.none(),
      sheet = const GlassPane.none(),
      scrim = const Color(0x00000000),
      saturation = 1,
      brightness = 1;

  final bool enabled;

  final GlassPane raised;
  final GlassPane quiet;
  final GlassPane bar;
  final GlassPane sheet;

  /// The ground colour the app bar darkens towards once content is under it.
  final Color scrim;

  /// Colour lift applied to whatever shows *through* a blurring pane.
  ///
  /// Blur averages colour, and averaging always moves towards grey — a heavily
  /// blurred backdrop comes out flatter and duller than the field it was taken
  /// from, which is most of why naive glass looks like frosted plastic. Pushing
  /// saturation and brightness back up on the sampled image is what restores
  /// the sense that there is something colourful behind the pane.
  ///
  /// Costs no extra pass: it composes into the same [ImageFilter] as the blur,
  /// so it is matrix arithmetic over a buffer that was being produced anyway.
  final double saturation;
  final double brightness;

  /// The pane for a given tier.
  GlassPane pane(GlassTier tier) => switch (tier) {
    GlassTier.raised => raised,
    GlassTier.quiet => quiet,
    GlassTier.bar => bar,
    GlassTier.sheet => sheet,
  };

  /// The blur used by the panes that cover content, for the surfaces that build
  /// their own filter rather than going through [GlassSurface].
  double get blur => bar.blur;

  /// The mid-gradient tint of a card, for surfaces that want the material's
  /// colour without its whole treatment.
  Color get tint => raised.fill.length > 1 ? raised.fill[1] : raised.fill.first;

  /// The lit lip of a card.
  Color get highlight => raised.topEdge;

  /// The hairline of a card.
  Color get edge => raised.edge;

  /// Blur plus the colour lift, as one filter.
  ImageFilter backdropFilter(double sigma) {
    final blur = ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
    if (saturation == 1 && brightness == 1) return blur;
    return ImageFilter.compose(
      outer: _boost(saturation, brightness),
      inner: blur,
    );
  }

  @override
  GlassStyle copyWith({
    bool? enabled,
    GlassPane? raised,
    GlassPane? quiet,
    GlassPane? bar,
    GlassPane? sheet,
    Color? scrim,
    double? saturation,
    double? brightness,
  }) {
    return GlassStyle(
      enabled: enabled ?? this.enabled,
      raised: raised ?? this.raised,
      quiet: quiet ?? this.quiet,
      bar: bar ?? this.bar,
      sheet: sheet ?? this.sheet,
      scrim: scrim ?? this.scrim,
      saturation: saturation ?? this.saturation,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  GlassStyle lerp(GlassStyle? other, double t) {
    if (other == null) return this;
    return GlassStyle(
      // Not interpolated: half-enabled glass is a surface that is neither, and
      // the theme switch is instant anyway.
      enabled: t < 0.5 ? enabled : other.enabled,
      raised: GlassPane.lerp(raised, other.raised, t),
      quiet: GlassPane.lerp(quiet, other.quiet, t),
      bar: GlassPane.lerp(bar, other.bar, t),
      sheet: GlassPane.lerp(sheet, other.sheet, t),
      scrim: Color.lerp(scrim, other.scrim, t)!,
      saturation: saturation + (other.saturation - saturation) * t,
      brightness: brightness + (other.brightness - brightness) * t,
    );
  }
}

/// Saturation and brightness as a single colour matrix.
///
/// The luminance weights are the sRGB ones, so pulling saturation towards zero
/// leaves a grey of the same perceived lightness rather than of the same
/// arithmetic mean.
ColorFilter _boost(double s, double b) {
  const lr = 0.213, lg = 0.715, lb = 0.072;
  double v(double x) => x * b;
  return ColorFilter.matrix(<double>[
    v(lr * (1 - s) + s), v(lg * (1 - s)), v(lb * (1 - s)), 0, 0, //
    v(lr * (1 - s)), v(lg * (1 - s) + s), v(lb * (1 - s)), 0, 0, //
    v(lr * (1 - s)), v(lg * (1 - s)), v(lb * (1 - s) + s), 0, 0, //
    0, 0, 0, 1, 0,
  ]);
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
/// On a glass theme: the tier's gradient, a hairline that lights up along the
/// top lip, and — for the panes that overlap content — a blur of whatever is
/// behind them. On every other theme it is an ordinary opaque box in
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
    this.tier = GlassTier.raised,
    this.fallbackColor,
    this.selected = false,
    this.outlined = false,
    this.clip = true,
    this.blurs = true,
  });

  final Widget child;
  final BorderRadius borderRadius;

  /// Which surface of the material this is. See [GlassTier].
  final GlassTier tier;

  /// What to paint on a flat theme. Defaults to the theme's card colour.
  final Color? fallbackColor;

  /// Lifts the tint and the edge — the pane catches more light when picked.
  final bool selected;

  /// Draws the hairline right round, and brighter.
  ///
  /// For panes that are a *choice* rather than a report: a training day you
  /// tap to open, where the edge is what says "this is one of several, and you
  /// can pick it". The fill is left alone — a brighter fill would make it look
  /// selected instead of selectable.
  final bool outlined;

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

    final pane = glass.pane(tier);
    final lift = selected ? 1.35 : 1.0;
    final edgeLift = outlined ? 2.4 : lift;

    Widget content = CustomPaint(
      // The edge is painted over the child, not under it: it is the lip of the
      // pane, and anything inside sits beneath that surface.
      foregroundPainter: _EdgePainter(
        borderRadius: borderRadius,
        edge: _lift(pane.edge, edgeLift),
        topEdge: _lift(pane.topEdge, outlined ? 1.15 : lift),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: pane.base,
          gradient: LinearGradient(
            // 176 degrees: barely off vertical. The tilt is what stops the
            // gradient reading as a painted band and starts it reading as
            // light arriving from somewhere.
            begin: const Alignment(-0.07, -1),
            end: const Alignment(0.07, 1),
            colors: [for (final colour in pane.fill) _lift(colour, lift)],
            stops: pane.stops,
          ),
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    );

    if (!clip) return content;

    if (blurs && pane.blur > 0) {
      content = BackdropFilter(
        filter: glass.backdropFilter(pane.blur),
        child: content,
      );
    }

    content = ClipRRect(borderRadius: borderRadius, child: content);

    if (pane.shadow.isEmpty) return content;
    return CustomPaint(
      painter: _ShadowPainter(borderRadius: borderRadius, shadows: pane.shadow),
      child: content,
    );
  }
}

/// The pane's shadow, painted only *outside* the pane.
///
/// Not `BoxDecoration.boxShadow`, and the difference is the whole reason this
/// class exists. CSS clips an outer box-shadow to outside the box, so the
/// design's `0 2px 30px -16px rgba(0,0,0,0.9)` is a dark halo under the card's
/// edge and nothing else. Flutter's `BoxShadow` paints the entire blurred
/// rounded rectangle *behind* the box — and behind a translucent box means
/// through it.
///
/// So every card was a pane of glass with a near-opaque black card slipped
/// behind it. The interiors came out charcoal no matter how bright the field
/// got or how milky the fill was, which is exactly how it looked: lit at the
/// edges, black in the middle.
class _ShadowPainter extends CustomPainter {
  const _ShadowPainter({required this.borderRadius, required this.shadows});

  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final shape = borderRadius.toRRect(rect);

    canvas.save();
    // Everything the pane itself covers is cut out of the canvas first, so the
    // blur can only land beyond its edge. A combined path rather than a
    // difference clip: this Flutter's `clipRRect` takes no clip operation, and
    // subtracting the shape from a generous rectangle says the same thing.
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect.inflate(120)),
        Path()..addRRect(shape),
      ),
    );
    for (final shadow in shadows) {
      canvas.drawRRect(
        borderRadius.toRRect(
          rect.shift(shadow.offset).inflate(shadow.spreadRadius),
        ),
        shadow.toPaint(),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShadowPainter old) =>
      old.borderRadius != borderRadius || old.shadows != shadows;
}

Color _lift(Color colour, double factor) => factor == 1
    ? colour
    : colour.withValues(alpha: (colour.a * factor).clamp(0.0, 1.0));

/// The hairline around a pane, lit along its top lip.
///
/// One stroked round-rect with a vertical gradient shader, rather than a border
/// plus an overlaid highlight. Two reasons: a [BoxDecoration] border must be
/// uniform once it has a radius, so "bright on top, dim elsewhere" is not
/// expressible there at all; and a highlight painted as a *fill* washes down
/// over the pane's contents, where what is wanted is a lit edge one pixel wide
/// that follows the corners round.
class _EdgePainter extends CustomPainter {
  const _EdgePainter({
    required this.borderRadius,
    required this.edge,
    required this.topEdge,
  });

  final BorderRadius borderRadius;
  final Color edge;
  final Color topEdge;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // Inset by half the stroke so the line lands inside the pane rather than
    // straddling its edge, where the outer half would be clipped away.
    final rect = Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1);

    canvas.drawRRect(
      borderRadius.toRRect(rect),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topEdge, edge],
          // Short: the lift belongs to the lip, not to the sides. A third of
          // the way down the pane the edge is back to its own weight.
          stops: const [0, 0.32],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.edge != edge ||
      old.topEdge != topEdge ||
      old.borderRadius != borderRadius;
}
