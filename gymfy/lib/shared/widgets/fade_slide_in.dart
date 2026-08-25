import 'package:flutter/material.dart';

/// Fades a widget in and lifts it a few pixels as it arrives.
///
/// Used on list rows and settings sections so a screen assembles itself instead
/// of appearing fully formed. Deliberately small and quick: at 200ms and eight
/// pixels it registers as the list settling, not as an animation you have to
/// wait through. Anything longer turns scrolling into a slideshow.
///
/// Inside a `ListView.builder` this replays each time a row scrolls back into
/// view, which is the intended effect — rows arrive as you reach them.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 200),
  });

  final Widget child;

  /// Staggers a group of items. Keep it small — a long stagger on a long list
  /// leaves the bottom of the screen visibly empty while it catches up.
  final Duration delay;

  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        // The row can be scrolled off and disposed before its delay elapses.
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: AnimatedBuilder(
        animation: _curve,
        // The child is built once and reused across every frame — the only
        // thing changing is the offset it's drawn at.
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 8 * (1 - _curve.value)),
          child: child,
        ),
      ),
    );
  }
}
