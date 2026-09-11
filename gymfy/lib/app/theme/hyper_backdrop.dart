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

    // Two of the three take the accent, so the backdrop follows the colour the
    // user picked instead of being a fixed purple wash under every palette.
    _orb(canvas, size, phase: 0, colour: accent, scale: 0.85);
    _orb(canvas, size, phase: 0.37, colour: accent, scale: 0.6);
    // The third is a fixed cool tone, so there is a second hue in the field
    // even when the accent is a single flat colour. Without it the orbs blend
    // into one soft blob and the depth goes.
    _orb(
      canvas,
      size,
      phase: 0.68,
      colour: const Color(0xFF2B6CFF),
      scale: 0.7,
    );
  }

  void _orb(
    Canvas canvas,
    Size size, {
    required double phase,
    required Color colour,
    required double scale,
  }) {
    // Each orb travels its own slow ellipse. Different periods per axis so the
    // paths never repeat exactly and the field never looks like it is looping.
    final angle = (t + phase) * 2 * math.pi;
    final centre = Offset(
      size.width * (0.5 + 0.42 * math.cos(angle)),
      size.height * (0.35 + 0.30 * math.sin(angle * 0.8 + phase)),
    );
    final radius = size.shortestSide * scale;

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            // Low alpha on purpose. This is a field to sense, not a picture to
            // look at, and anything stronger turns text on top of it into hard
            // work.
            colour.withValues(alpha: 0.20),
            colour.withValues(alpha: 0.06),
            colour.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.t != t || old.accent != accent;
}
