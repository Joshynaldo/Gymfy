import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/glass.dart';

/// The navigation bar, in whatever the current theme calls a surface.
///
/// Flat themes get the [NavigationBar] they have always had, spanning the full
/// width. Hyper lifts it off the bottom edge into a floating pill, which is the
/// change that most makes the app read as layered: a bar welded to the bottom
/// of the screen is part of the chrome, a bar hovering above it is an object in
/// front of the content.
///
/// The real [NavigationBar] is kept inside the pill rather than hand-rolled.
/// Its selection indicator, ripples, label behaviour, semantics and
/// accessibility affordances are a lot to reimplement in exchange for a shape —
/// and keeping it means the widget tests that look for a `NavigationBar` still
/// describe the app.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final glass = glassOf(context);

    final bar = NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      // Colours (active tint, indicator) come from navigationBarTheme,
      // which is driven by the accent — see app_theme.dart.
      backgroundColor: glass.enabled ? Colors.transparent : null,
      // Material's 80 is sized for a bar that runs to the screen edge. Inside a
      // pill with air around it, the same height reads as a slab.
      height: glass.enabled ? 62 : null,
      // Icons only inside the pill. Four labels across a bar inset from both
      // edges is four lines of 10px type competing with the screen above them,
      // and these four destinations are the ones you learn in a day.
      //
      // The labels are not deleted, only unshown: each destination still
      // carries its name, so a screen reader announces "Progress" and a long
      // press still says it. Hiding a label is a visual decision; removing it
      // would be an accessibility one.
      labelBehavior: glass.enabled
          ? NavigationDestinationLabelBehavior.alwaysHide
          : null,
      destinations: destinations,
    );

    if (!glass.enabled) return bar;

    // The gesture bar's inset, which the pill floats above rather than sits
    // under. Floored so the bar is still lifted off the edge on a phone with
    // hardware buttons and no inset at all.
    final inset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, math.max(10, inset)),
      child: GlassSurface(
        // Near-capsule. A pill this tall with a 16-radius card corner looks
        // like a card that ended up in the wrong place.
        borderRadius: BorderRadius.circular(26),
        // The bar tier: an opaque floor under the tint, a brighter lip, and the
        // long soft shadow that separates the pill from whatever is sliding
        // past beneath it.
        tier: GlassTier.bar,
        // Here the blur is the whole effect, and one of only two places in the
        // app that earns it: the shell lays its body out behind the pill, so
        // what is being filtered is the list actually scrolling underneath.
        // Cheap despite that — the offscreen buffer is one pill, not one
        // screen.
        blurs: true,
        // NavigationBar adds the system inset itself. Inside a floating pill
        // that would pad the bar away from its own bottom edge, on top of the
        // margin already holding it clear of the screen.
        child: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: bar,
        ),
      ),
    );
  }
}
