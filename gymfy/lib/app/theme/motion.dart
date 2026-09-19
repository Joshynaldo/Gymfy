import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The app's motion vocabulary: how long things take, and how they move.
///
/// One file rather than a duration picked by hand at each call site. Motion is
/// the part of an interface you feel rather than see, and it only reads as
/// deliberate if everything moves the same way — a card that springs, a sheet
/// that eases and a number that snaps look like three different apps.
///
/// Everything here is available on every theme. The glass material is Hyper's
/// alone, but how quickly a thing settles is not a palette decision.

/// A damped spring, expressed as a [Curve].
///
/// Flutter ships spring *simulations* (physics driving an unbounded animation)
/// but no spring *curve*, and a curve is what the animated widgets take. This
/// solves the same second-order system analytically over a fixed one-second
/// span, so it can be dropped anywhere a `Curves.easeOut` would go.
///
/// The reason to bother: eased curves decelerate into their target and stop
/// dead. A spring carries a little momentum past it and comes back, which is
/// what makes a control feel like an object rather than a value being
/// interpolated. The overshoot is small enough here to register as weight, not
/// as bounce.
class SpringCurve extends Curve {
  const SpringCurve({
    required this.stiffness,
    required this.damping,
    this.mass = 1,
  });

  /// How hard the spring pulls toward the target. Higher is snappier.
  final double stiffness;

  /// How much the motion is resisted. This is the dial that sets overshoot:
  /// below critical damping the curve passes its target and returns, at or
  /// above it the curve never overshoots at all.
  final double damping;

  final double mass;

  /// The curve's t (0..1) is stretched over this many seconds of spring time.
  ///
  /// The constants below are tuned so the spring has settled to within a
  /// rounding error by the end of it — otherwise the curve would arrive at its
  /// target by being cut off, which is exactly the snap it exists to avoid.
  static const _span = 1.0;

  @override
  double transformInternal(double t) {
    final omega = math.sqrt(stiffness / mass);
    final zeta = damping / (2 * math.sqrt(stiffness * mass));
    final x = t * _span;

    if (zeta < 1) {
      // Underdamped: oscillates toward the target inside a decaying envelope.
      final damped = omega * math.sqrt(1 - zeta * zeta);
      return 1 -
          math.exp(-zeta * omega * x) *
              (math.cos(damped * x) +
                  (zeta * omega / damped) * math.sin(damped * x));
    }
    // Critically damped: the fastest approach that never overshoots.
    return 1 - math.exp(-omega * x) * (1 + omega * x);
  }
}

/// The four ways anything in Gymfy is allowed to move.
abstract final class AppCurves {
  /// Arrivals and releases — a card springing back, a value landing.
  ///
  /// About 9% overshoot: visible as weight, not as a bounce you wait through.
  static const spring = SpringCurve(stiffness: 180, damping: 16);

  /// Anything whose *size* or position in a layout changes.
  ///
  /// Critically damped, so it never overshoots. Overshoot on a size change
  /// means a frame where the content is larger than the box holding it, which
  /// shows up as clipping or a scrollbar flicking in and out.
  static const settle = SpringCurve(stiffness: 200, damping: 28.3);

  /// Reserved for the few moments worth emphasising — a finished workout, a new
  /// rank. Loose enough to read as a flourish.
  static const emphasis = SpringCurve(stiffness: 150, damping: 11);

  /// Leaving. Quick and unremarkable: a thing on its way out should not ask for
  /// attention on the way.
  static const exit = Curves.easeInCubic;
}

/// How long things take.
///
/// Four steps, because a scale with more than that stops being a decision and
/// becomes a search for the number that looks right.
abstract final class AppDurations {
  /// Direct response to a finger. Anything slower feels like lag rather than
  /// feedback.
  static const press = Duration(milliseconds: 90);

  /// Small state changes — a tick appearing, a colour shifting.
  static const quick = Duration(milliseconds: 170);

  /// The default. Most things that appear, move or resize.
  static const standard = Duration(milliseconds: 260);

  /// Whole screens and sheets, where the distance travelled is larger.
  static const slow = Duration(milliseconds: 380);
}

/// [duration], or nothing at all when the system asks for reduced motion.
///
/// "Reduce motion" is an accessibility setting people turn on because movement
/// makes them ill, so it is not a preference to style around — the animation
/// simply does not happen and the widget jumps to its end state. Routing every
/// duration through here means honouring it is one call rather than a policy
/// each widget has to remember.
Duration motionOf(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

/// Gymfy's screen-to-screen transition.
///
/// The incoming screen slides a short way in from the right and fades; the one
/// underneath drifts the other way, dims and shrinks a little. That second half
/// is the part that matters — moving both layers at different rates is what
/// reads as depth, and it is why the outgoing screen looks like it is being
/// covered rather than simply replaced.
///
/// Deliberately shorter travel than Material's default. A full-width slide is a
/// long way to watch on every tap; a tenth of the screen plus a fade says the
/// same thing in less time.
class GymfyPageTransitionsBuilder extends PageTransitionsBuilder {
  const GymfyPageTransitionsBuilder();

  static final _incomingSlide = Tween<Offset>(
    begin: const Offset(0.10, 0),
    end: Offset.zero,
  ).chain(CurveTween(curve: AppCurves.settle));

  static final _incomingFade = Tween<double>(
    begin: 0,
    end: 1,
  ).chain(CurveTween(curve: const Interval(0, 0.55, curve: Curves.easeOut)));

  static final _outgoingSlide = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-0.05, 0),
  ).chain(CurveTween(curve: AppCurves.settle));

  // Never to zero: a page that fades out completely leaves a hole showing the
  // backdrop through the gap between the two screens.
  static final _outgoingFade = Tween<double>(
    begin: 1,
    end: 0.55,
  ).chain(CurveTween(curve: Curves.easeOut));

  static final _outgoingScale = Tween<double>(
    begin: 1,
    end: 0.97,
  ).chain(CurveTween(curve: AppCurves.settle));

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return SlideTransition(
      position: _outgoingSlide.animate(secondaryAnimation),
      child: FadeTransition(
        opacity: _outgoingFade.animate(secondaryAnimation),
        child: ScaleTransition(
          scale: _outgoingScale.animate(secondaryAnimation),
          child: SlideTransition(
            position: _incomingSlide.animate(animation),
            child: FadeTransition(
              opacity: _incomingFade.animate(animation),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
