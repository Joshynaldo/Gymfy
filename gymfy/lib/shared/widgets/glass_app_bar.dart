import 'package:flutter/material.dart';

import '../../app/theme/glass.dart';
import '../../app/theme/motion.dart';

/// The app bar, in whatever the current theme calls a surface.
///
/// On the flat themes this is an ordinary [AppBar] and nothing has changed. On
/// Hyper it becomes a pane: the opaque bar colour is dropped so the drifting
/// field shows through it, a translucent tint gives it a body, and a hairline
/// along the bottom edge is what separates it from the content rather than a
/// block of a different grey.
///
/// A [PreferredSizeWidget] wrapper rather than a change to `appBarTheme`
/// because the theme can set colours but cannot put a *layer* behind the bar,
/// and the tint has to be painted, not configured.
///
/// Only the parameters the app actually uses are exposed. Mirroring all forty
/// of [AppBar]'s would be a wrapper pretending to be a subclass; adding one the
/// day a screen needs it is a two-line change.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  /// A tab bar or search field beneath the title row.
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final glass = glassOf(context);

    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      bottom: bottom,
      // Transparent so the pane below is what you see. On a flat theme this
      // stays null and the bar keeps the palette's own background.
      backgroundColor: glass.enabled ? Colors.transparent : null,
      // Material 3 tints the bar a shade darker once content scrolls beneath
      // it. That is a sensible cue on an opaque bar and a mess on a
      // translucent one, where it fights the tint it is layered over.
      scrolledUnderElevation: 0,
      flexibleSpace: glass.enabled ? const _BarPane() : null,
    );
  }
}

/// The bar's material: nothing at all until something scrolls under it.
///
/// A permanently tinted bar is a hundred-pixel slab of brightness across the
/// top of every screen — a sixth of a phone, spent on a title. Worse, it is
/// spent whether or not the bar is doing anything: at the top of a list there
/// is nothing beneath the bar to separate the title from, so the scrim is
/// decoration and the weight is pure cost.
///
/// So it earns its presence. At rest the title floats over the drifting field
/// with no bar behind it at all. The moment content slides underneath, the
/// scrim, the hairline and the blur fade in together — the bar appears exactly
/// when there is something to hide behind it, which is also the moment it
/// starts being legible as glass.
///
/// This is the same cue Material 3 draws with `scrolledUnderElevation`, which
/// is switched off here because a surface tint on top of a translucent pane
/// fights the pane. Same idea, drawn in this app's material.
class _BarPane extends StatefulWidget {
  const _BarPane();

  @override
  State<_BarPane> createState() => _BarPaneState();
}

class _BarPaneState extends State<_BarPane>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.quick,
  );

  // Linear, unlike everything else in the app. A spring is for something that
  // has a place to arrive at; this is a cross-fade, and easing the opacity of a
  // scrim only makes the moment it commits harder to predict while scrolling.
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.linear,
  );

  ScrollNotificationObserverState? _observer;
  bool _under = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The same observer AppBar itself listens to. Scaffold installs it above
    // both the bar and the body, which is the only reason a widget in the app
    // bar can know anything about a list it is not an ancestor of.
    final observer = ScrollNotificationObserver.maybeOf(context);
    if (observer == _observer) return;
    _observer?.removeListener(_onScroll);
    _observer = observer?..addListener(_onScroll);
  }

  @override
  void dispose() {
    _observer?.removeListener(_onScroll);
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll(ScrollNotification notification) {
    // depth 0 only: a horizontal strip inside a card is not the page scrolling,
    // and letting it drive the bar makes the title flicker as you swipe a chart.
    if (notification is! ScrollUpdateNotification &&
        notification is! ScrollMetricsNotification) {
      return;
    }
    if (notification.depth != 0) return;

    final metrics = notification is ScrollUpdateNotification
        ? notification.metrics
        : (notification as ScrollMetricsNotification).metrics;
    if (metrics.axis != Axis.vertical) return;

    final under = metrics.extentBefore > 0;
    if (under == _under) return;

    _under = under;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = under ? 1 : 0;
    } else {
      under ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = glassOf(context);

    // SizedBox.expand is load-bearing. AppBar puts flexibleSpace in a Stack,
    // and a DecoratedBox with no child takes the smallest size it is offered —
    // which is nothing at all. The first version of this painted a perfectly
    // correct gradient into a zero-by-zero box and looked exactly like having
    // written no bar at all.
    return SizedBox.expand(
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, _) {
          final t = _curve.value;
          // Nothing under the bar, nothing to draw — and, more to the point,
          // nothing to blur. Skipping the filter entirely at rest keeps the
          // offscreen pass for the frames where it changes a pixel.
          if (t == 0) return const SizedBox.expand();

          final decoration = BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                // The ground colour, not a white tint. A bar over a list has to
                // subtract the content behind it rather than add light to it:
                // white over moving text leaves the text legible through the
                // scrim, which is worse than either a solid bar or none.
                glass.scrim.withValues(alpha: 0.78 * t),
                glass.scrim.withValues(alpha: 0.62 * t),
              ],
            ),
            // The line the content stops at. Without it the list appears to be
            // cut off in mid-air.
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.12 * t),
              ),
            ),
          );

          return ClipRect(
            child: BackdropFilter(
              // Slightly softer than the pill's: the bar is the taller pane and
              // the same sigma over that area reads as a smear.
              filter: glass.backdropFilter(28 * t),
              child: DecoratedBox(decoration: decoration),
            ),
          );
        },
      ),
    );
  }
}
