import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/motion.dart';

/// A tap target that gives way under the finger.
///
/// The whole idea is that the thing you touched acknowledges you before the
/// screen it opens has begun to appear. A ripple does that on Android, but a
/// ripple is light spreading *across* a surface — it says nothing about the
/// surface being pressed, and on a translucent pane it mostly reads as a smudge.
/// Scaling the whole card down a fraction and springing it back says the card
/// is an object you pushed.
///
/// The press is driven by [InkWell.onHighlightChanged] rather than by a
/// [GestureDetector] of its own, so it obeys the gesture arena: start scrolling
/// with a finger that landed on a card and the card releases instead of staying
/// stuck down.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.scale = 0.975,
    this.haptic = true,
    this.splash = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Keeps the ripple and the press inside the surface's own corners.
  final BorderRadius? borderRadius;

  /// How far down the surface travels. Small on purpose: at 0.95 a list of
  /// cards visibly jumps around as you scan it.
  final double scale;

  /// A single selection tick on tap. Off for rows where the tap opens a screen
  /// that will produce its own feedback anyway.
  final bool haptic;

  /// The Material ripple. Worth turning off on glass, where it muddies the
  /// tint and the scale is doing the work already.
  final bool splash;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  // Built in initState rather than lazily on first use. A `late final` here
  // looks like a saving — most cards never get pressed — but it means dispose()
  // can be the first thing to touch the field, and building an AnimationController
  // needs a TickerMode lookup up the tree, which is illegal once the element is
  // being torn down. An unstarted Ticker costs an object and no frames.
  late final AnimationController _controller;
  late final CurvedAnimation _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.press,
      // Longer coming back than going down. Pressing should feel instant;
      // releasing is where the spring is worth watching.
      reverseDuration: AppDurations.standard,
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      // Flipping the spring turns its overshoot into a scale that passes very
      // slightly above 1 on the way back — the surface rebounding rather than
      // stopping flat at its resting size.
      reverseCurve: const FlippedCurve(AppCurves.spring),
    );
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    pressed ? _controller.forward() : _controller.reverse();
  }

  void _handleTap() {
    if (widget.haptic) HapticFeedback.selectionClick();
    widget.onTap!.call();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius;

    final surface = Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: widget.onTap == null ? null : _handleTap,
        onLongPress: widget.onLongPress,
        onHighlightChanged: _setPressed,
        splashColor: widget.splash ? null : Colors.transparent,
        highlightColor: widget.splash ? null : Colors.transparent,
        child: widget.child,
      ),
    );

    // Nothing to press: no listener, no per-frame rebuild, no transform layer.
    // A great many cards on a screen are decoration rather than targets.
    if (widget.onTap == null && widget.onLongPress == null) return surface;

    return AnimatedBuilder(
      animation: _curve,
      // Built once. The only thing changing per frame is the transform.
      child: surface,
      builder: (context, child) => Transform.scale(
        scale: 1 - (1 - widget.scale) * _curve.value,
        child: child,
      ),
    );
  }
}
