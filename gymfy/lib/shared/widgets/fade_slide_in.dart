import 'package:flutter/material.dart';

/// Fades a widget in and lifts it a few pixels as it arrives.
///
/// For content arriving *into* a screen that is already on display — a list
/// row, a section that just loaded, a panel swapped in behind a segmented
/// control. Deliberately small and quick: at 200ms and eight pixels it
/// registers as the list settling, not as an animation you have to wait
/// through. Anything longer turns scrolling into a slideshow.
///
/// **Not for a whole screen body.** A pushed route already has an entrance —
/// it slides in from the right and fades up as it comes — and adding this on
/// top puts two fades on the same pixels. They multiply, so the content stays
/// nearly invisible through the first half of the transition and then catches
/// up in a rush, moving right-to-left and bottom-to-top at once. It reads as
/// the content lagging behind its own screen. `one_entrance_test.dart` holds
/// that line; the exception is a *keyed* wrapper, which replays on a content
/// swap rather than on arrival.
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

  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  /// Whether the arrival has already been decided, one way or the other.
  ///
  /// [didChangeDependencies] runs again whenever anything inherited changes —
  /// a theme switch, a rotation — and replaying the arrival then would make
  /// every row on screen flutter for no reason.
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // Asked here rather than in initState: whether to move at all depends on
    // the platform's reduced-motion setting, and that is an inherited lookup
    // which is not available yet when initState runs.
    //
    // This widget wraps whole screen bodies on sixteen screens as well as
    // individual list rows, and it used to be the one animated thing in the
    // app that never asked. Somebody who turns the setting on because movement
    // makes them ill still had every screen slide and fade at them.
    //
    // Jumped to the end, not shortened: a quick animation is still an
    // animation. Same rule `motionOf` applies everywhere else.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }

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
    // A CurvedAnimation holds a listener on its parent and has to be let go of
    // explicitly. Every other one in the app is disposed; this was the one
    // that was not, on the widget that exists in the greatest numbers.
    _curve.dispose();
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
