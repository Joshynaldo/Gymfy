import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/accent_color.dart';
import '../../app/theme/motion.dart';

/// A single bloom of light behind [child], played once when it appears.
///
/// For the two or three moments in the app that are actually an achievement —
/// finishing a workout, reaching a new rank. Not confetti: a gym app that
/// throws paper at you for logging three sets cheapens the moment it is trying
/// to mark, and you would see it several times a week.
///
/// Two rings expanding out of a soft glow, in the accent, over in about a
/// second. Then the painter is taken out of the tree entirely — a celebration
/// that leaves a repainting layer behind is a celebration you pay for all the
/// way to the end of the session.
class Celebration extends ConsumerStatefulWidget {
  const Celebration({super.key, required this.child, this.enabled = true});

  final Widget child;

  /// Lets a screen decide there is nothing to celebrate — an empty workout, a
  /// summary opened again from history a week later.
  final bool enabled;

  @override
  ConsumerState<Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends ConsumerState<Celebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.celebrate,
  );

  /// Drops the painter once the bloom is over.
  bool _done = true;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _done = true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Started here rather than in initState because whether to play at all
    // depends on the platform's reduced-motion setting, which is an inherited
    // lookup and not available yet when initState runs.
    if (!widget.enabled) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    if (_controller.isAnimating || _controller.isCompleted) return;
    _done = false;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;

    final accent = ref.watch(accentColorProvider);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Behind the content and not hit-testable: the bloom is scenery, and a
        // full-width invisible layer over a button is a bug waiting to be
        // reported as "the Done button does nothing".
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _BloomPainter(t: _controller.value, colour: accent),
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

/// A glow and two rings, expanding and fading together.
class _BloomPainter extends CustomPainter {
  _BloomPainter({required this.t, required this.colour});

  /// 0..1, played once.
  final double t;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final reach = size.shortestSide;

    // The glow leads and is gone by halfway — it reads as the flash of the
    // thing happening, with the rings as the consequence.
    final glow = Curves.easeOut.transform(t);
    if (glow < 1) {
      canvas.drawCircle(
        centre,
        reach * (0.3 + 0.7 * glow),
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  colour.withValues(alpha: 0.28 * (1 - glow)),
                  colour.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(
                  center: centre,
                  radius: reach * (0.3 + 0.7 * glow),
                ),
              ),
      );
    }

    // The second ring starts a third of the way through, so they read as one
    // pulse rather than two events.
    _ring(canvas, centre, reach, t);
    _ring(canvas, centre, reach, (t - 0.33) / 0.67);
  }

  void _ring(Canvas canvas, Offset centre, double reach, double progress) {
    if (progress <= 0 || progress >= 1) return;
    final eased = Curves.easeOutCubic.transform(progress);

    canvas.drawCircle(
      centre,
      reach * (0.15 + 0.85 * eased),
      Paint()
        ..style = PaintingStyle.stroke
        // Thins as it grows, like the front of a wave losing energy.
        ..strokeWidth = 3 * (1 - eased)
        ..color = colour.withValues(alpha: 0.5 * (1 - eased)),
    );
  }

  @override
  bool shouldRepaint(_BloomPainter old) => old.t != t || old.colour != colour;
}
