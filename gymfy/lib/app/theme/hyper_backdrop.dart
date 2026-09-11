import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'glass.dart';

/// The field of colour the Hyper theme's glass sits on.
///
/// Not decoration. Blur only reads as glass when there is something behind it
/// worth blurring — over a flat black background a translucent pane is just a
/// slightly different grey, which is exactly what the first attempt at this
/// looked like. The backdrop is the other half of the material.
///
/// Three soft orbs on a dark ground, drifting slowly. Slowly is the point: fast
/// movement behind content you are trying to read is a distraction, and this
/// has to survive being on screen for a whole workout. A full cycle is a couple
/// of minutes, so it never appears to move while you look at it and never looks
/// static when you come back.
///
/// Renders nothing at all on the flat themes.
class HyperBackdrop extends StatefulWidget {
  const HyperBackdrop({super.key, required this.child});

  final Widget child;

  @override
  State<HyperBackdrop> createState() => _HyperBackdropState();
}

class _HyperBackdropState extends State<HyperBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 120),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Started from the theme rather than from initState. Starting it eagerly
    // left a ticker running for the life of the app on every flat theme —
    // nothing to see, a wake-up every frame, and a widget tree that never
    // settles. It cost a phone battery all day and hung every widget test that
    // waited for the app to come to rest.
    final wanted = glassOf(context).enabled;
    if (wanted && !_drift.isAnimating) {
      _drift.repeat();
    } else if (!wanted && _drift.isAnimating) {
      _drift.stop();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!glassOf(context).enabled) return widget.child;

    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _drift,
              builder: (context, _) => CustomPaint(
                painter: _BackdropPainter(
                  t: _drift.value,
                  accent: theme.colorScheme.primary,
                  ground: const Color(0xFF07070F),
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

/// Three drifting orbs, painted as radial gradients.
///
/// A painter rather than stacked blurred `Container`s: this sits behind every
/// screen for the length of a session, and three gradient circles in one paint
/// pass is a great deal cheaper than three offscreen blur layers on the older
/// Android hardware this app targets.
class _BackdropPainter extends CustomPainter {
  _BackdropPainter({
    required this.t,
    required this.accent,
    required this.ground,
  });

  /// 0..1, wrapping. One full turn of the drift.
  final double t;
  final Color accent;
  final Color ground;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = ground);

    // A wash of the accent over the whole ground before the orbs go on.
    //
    // The orbs alone left most of the screen at the ground colour, which is
    // near-black — and that is what made the glass read as smoked rather than
    // milky. A pane is only as pale as what is behind it, so the cards were
    // dark for a reason that had nothing to do with the cards. This lifts the
    // whole field into the accent's family first; the orbs are then bright
    // spots *in* a coloured ground rather than three lamps in a dark room.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _shift(accent, 6, 0.42).withValues(alpha: 0.55),
            _shift(accent, -10, 0.24).withValues(alpha: 0.42),
          ],
        ).createShader(rect),
    );

    // Three anchors, not three orbits. Each orb belongs to a corner of the
    // screen and only breathes around it: the composition is the same every
    // time you open the app, and what changes is too slow to catch.
    //
    // The hues are the accent and two neighbours of it. Keeping the whole field
    // inside one family is what stops the ground picking up a colour the
    // interface has no use for — a green wash under a purple accent reads as a
    // second, competing accent.
    _orb(
      canvas,
      size,
      anchor: const Offset(0.24, 0.06),
      radius: 0.78,
      colour: _shift(accent, 4, 1.06),
      phase: 0,
      travel: const Offset(0.15, 0.10),
    );
    _orb(
      canvas,
      size,
      anchor: const Offset(0.95, 0.52),
      radius: 0.70,
      colour: _shift(accent, -6, 0.94),
      phase: 0.41,
      travel: const Offset(-0.18, -0.07),
    );
    _orb(
      canvas,
      size,
      anchor: const Offset(0.5, 0.97),
      radius: 0.72,
      colour: _shift(accent, 12, 0.98),
      phase: 0.72,
      travel: const Offset(0.10, -0.09),
    );
  }

  /// The accent, moved a little round the wheel and pushed towards its purest
  /// version of itself.
  ///
  /// Two orbs of exactly the accent and one of something else blend into a
  /// single soft blob and the depth goes with it; three near-neighbours keep
  /// the field reading as one light with several sources.
  ///
  /// The saturation lift is what stops the field going muddy. These are painted
  /// at low alpha over a near-black ground, and low alpha *is* a blend towards
  /// the ground — so an orb painted in the accent's own saturation arrives
  /// greyer than the accent, every time. Pushing it up first is how the colour
  /// survives the dilution.
  Color _shift(Color colour, double degrees, double lightness) {
    final hsl = HSLColor.fromColor(colour);
    return hsl
        .withHue((hsl.hue + degrees) % 360)
        .withSaturation((hsl.saturation * 1.45).clamp(0.0, 1.0))
        .withLightness((hsl.lightness * lightness).clamp(0.0, 1.0))
        .toColor();
  }

  void _orb(
    Canvas canvas,
    Size size, {
    required Offset anchor,
    required double radius,
    required Color colour,
    required double phase,
    required Offset travel,
  }) {
    // A slow figure of eight around the anchor — different periods per axis, so
    // the path never repeats exactly and the field never looks like it loops.
    final angle = (t + phase) * 2 * math.pi;
    final centre = Offset(
      size.width * (anchor.dx + travel.dx * math.cos(angle)),
      size.height * (anchor.dy + travel.dy * math.sin(angle * 0.8 + phase)),
    );
    final r = size.shortestSide * radius;

    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            // Bright enough to read as colour rather than as a stain.
            //
            // The ceiling is legibility rather than taste: text sits on these
            // panes, the panes are translucent, and the field shows through
            // them. At 0.62 an orb passing behind a card is visible *in* the
            // card — which is the effect — without the numbers on it losing
            // their edge. Past about three quarters it starts to.
            colour.withValues(alpha: 0.62),
            colour.withValues(alpha: 0.46),
            colour.withValues(alpha: 0),
          ],
          // Held flat to a quarter of the radius before it falls away, which is
          // what gives an orb a body instead of a hotspot in the middle.
          stops: const [0, 0.26, 0.72],
        ).createShader(Rect.fromCircle(center: centre, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.t != t || old.accent != accent;
}
