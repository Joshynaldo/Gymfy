import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/glass_nav_bar.dart';
import '../theme/glass.dart';
import '../theme/motion.dart';

/// The five main tabs, in bar order.
///
/// Public so the design harness can show the real bar rather than a copy of it.
/// The last time a preview drew its own version of a control it quietly showed
/// a combination the app could not produce, and the design was judged on it.
const mainDestinations = [
  NavigationDestination(
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
    label: 'Home',
  ),
  NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Workout'),
  NavigationDestination(icon: Icon(Icons.insights), label: 'Progress'),
  NavigationDestination(icon: Icon(Icons.apps), label: 'More'),
];

/// The persistent shell that wraps the four main tabs.
///
/// Four, not five, and not the six this started with. The bar is the one
/// control you hit without looking, and each tab you add takes width from every
/// other one: at six the labels had to shrink to fit, at five the targets were
/// still narrower than a thumb.
///
/// What went: the exercise library, which is a reference you consult from
/// somewhere else rather than a place you go; and the stats screen, which
/// answers the same question as the charts and belongs inside Progress. What
/// came back: Progress itself, which is the reason anybody logs anything.
///
/// [navigationShell] is supplied by [StatefulShellRoute.indexedStack] in
/// `app_router.dart`. Switching tabs is done through
/// [StatefulNavigationShell.goBranch].
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    // The bar is the one control you hit without looking, mid-set, and a tap
    // that lands on the tab you are already on otherwise gives no sign it
    // registered at all.
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      // Tapping the tab you're already on pops it back to its first screen.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Content runs the full height of the screen and passes *under* the
      // floating pill rather than stopping above it. That is what gives the
      // bar something to blur; a translucent bar with nothing behind it is a
      // tinted rectangle. Screens clear the pill themselves through
      // `barInsets`.
      extendBody: glassOf(context).enabled,
      // The shell renders whichever branch (tab) is currently active.
      body: TabTransition(
        index: navigationShell.currentIndex,
        child: navigationShell,
      ),
      bottomNavigationBar: GlassNavBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: mainDestinations,
      ),
    );
  }
}

/// Settles the incoming tab into place instead of cutting to it.
///
/// An `IndexedStack` swaps its visible child between two frames, which is
/// instant and reads as a flicker — there is no sense of one screen replacing
/// another, just different pixels. A short rise and fade gives the switch a
/// direction.
///
/// Kept to a fade *from* partial opacity rather than from nothing: fading up
/// from zero blinks the screen dark on every tab press, which is worse than the
/// cut it replaces.
class TabTransition extends StatefulWidget {
  const TabTransition({super.key, required this.index, required this.child});

  /// Which tab is showing. A change is what triggers the transition; the value
  /// itself is not used for anything.
  final int index;

  final Widget child;

  @override
  State<TabTransition> createState() => _TabTransitionState();
}

class _TabTransitionState extends State<TabTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.standard,
    // Starts finished: the first tab is already there and should not animate
    // itself in as the app opens.
    value: 1,
  );

  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: AppCurves.settle,
  );

  @override
  void didUpdateWidget(TabTransition old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      // The whole tab stack, built once per tab change rather than per frame.
      child: RepaintBoundary(child: widget.child),
      builder: (context, child) => Opacity(
        opacity: 0.4 + 0.6 * _curve.value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - _curve.value)),
          child: child,
        ),
      ),
    );
  }
}
