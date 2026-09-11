import 'package:flutter/material.dart';

import '../../app/theme/motion.dart';

/// A number that travels to its new value instead of jumping to it.
///
/// For the large readouts — total volume, a session's tonnage, a rank score.
/// Those numbers are the reason the screen exists, and a figure that simply
/// replaces itself is easy to miss; watching it climb tells you it changed and
/// roughly by how much, without a second element to say so.
///
/// Every digit is tabular, so the text does not reflow while it counts. Without
/// that a number passing through a "1" visibly narrows and everything beside it
/// twitches — the single detail that makes counting look cheap.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration = AppDurations.slow,
    this.textAlign,
    this.from,
  });

  final double value;

  /// Where to start counting the very first time the widget is built.
  ///
  /// Normally left null, so the number is simply there on arrival. Set it to
  /// zero on the handful of screens whose whole purpose is to present a result
  /// — the workout summary — where watching the total arrive *is* the content.
  final double? from;

  /// Turns the in-between values into text. Called every frame, so keep it to
  /// formatting — no lookups, no allocation-heavy work.
  final String Function(double value) format;

  final TextStyle? style;
  final Duration duration;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // begin == end, so the number is simply *there* the first time a screen
      // is built and only moves once it changes. Counting up from zero on
      // arrival is a nice flourish exactly once and an irritation every time
      // after that. On a later change the builder picks up from whatever is
      // currently on screen, so a figure updated twice in quick succession
      // carries on rather than snapping back to the old one.
      tween: Tween(begin: from ?? value, end: value),
      duration: motionOf(context, duration),
      // Never overshoots. A count that runs past its target and comes back
      // shows a number that was never true, which on a weight readout is worse
      // than a snap.
      curve: AppCurves.settle,
      builder: (context, animated, _) => Text(
        format(animated),
        textAlign: textAlign,
        style: (style ?? DefaultTextStyle.of(context).style).copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
