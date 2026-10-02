import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/glass.dart';
import '../../app/theme/motion.dart';

/// The navigation bar, in whatever the current theme calls a surface.
///
/// Flat themes get the [NavigationBar] they have always had, spanning the full
/// width. Hyper lifts it off the bottom edge into a floating pill, which is the
/// change that most makes the app read as layered: a bar welded to the bottom
/// of the screen is part of the chrome, a bar hovering above it is an object in
/// front of the content.
///
/// Inside the pill the tabs are the Gymfy Hyper design's own rather than
/// Material's: the selected tab gets a pane of glass the full size of the tab
/// (icon and all, not Material's small capsule behind the icon), its icon goes
/// from muted to full ink, and switching tabs fades one pane out as the next
/// fades in. No ripple — the glass appearing *is* the response. Each tab is
/// still a real button: focusable, announced with its name and whether it's
/// selected, and long-pressable for a tooltip, which is what the Material bar
/// gave for free and the reason it was kept so long.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  /// The tabs, in order. Only each one's [NavigationDestination.icon] and
  /// [NavigationDestination.label] are used inside the glass pill.
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final glass = glassOf(context);

    // Colours (active tint, indicator) come from navigationBarTheme, which is
    // driven by the accent — see app_theme.dart.
    if (!glass.enabled) {
      return NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
      );
    }

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
        child: SizedBox(
          height: 62,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                for (final (index, destination) in destinations.indexed) ...[
                  if (index > 0) const SizedBox(width: 2),
                  Expanded(
                    child: GlassNavTab(
                      icon: destination.icon,
                      label: destination.label,
                      selected: index == selectedIndex,
                      onTap: () => onDestinationSelected(index),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One tab of the glass pill.
///
/// Icon only. The label is not shown — four labels across a pill inset from
/// both edges is four lines of tiny type competing with the screen above
/// them, and these are the four places you learn on the first day — but it is
/// not removed either: it is the tab's name for screen readers and its
/// tooltip. Hiding a label is a visual decision; removing it would be an
/// accessibility one.
class GlassNavTab extends StatelessWidget {
  const GlassNavTab({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _radius = BorderRadius.all(Radius.circular(20));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // The design's timings: the pane fades a touch slower than the icon
    // brightens, so the icon leads and the glass settles in behind it.
    final fade = motionOf(context, const Duration(milliseconds: 190));
    final tint = motionOf(context, AppDurations.quick);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: _radius,
            // No ripple and no grey press tint: the pane of glass arriving is
            // the feedback, and a ripple running over it reads as two
            // responses to one tap.
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            hoverColor: Colors.white.withValues(alpha: 0.04),
            focusColor: Colors.white.withValues(alpha: 0.10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: fade,
                  curve: Curves.easeOut,
                  child: const _TabPane(radius: _radius),
                ),
                Center(
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(
                      end: selected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                    duration: tint,
                    curve: Curves.easeOut,
                    builder: (context, color, child) => IconTheme.merge(
                      data: IconThemeData(color: color, size: 21),
                      child: child!,
                    ),
                    child: icon,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The selected tab's pane: a brighter fill than the pill around it, as the
/// design draws it — a three-stop gradient that dips through the middle, and
/// a lit edge along the top.
class _TabPane extends StatelessWidget {
  const _TabPane({required this.radius});

  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: GlassEdgePainter(
        borderRadius: radius,
        edge: Colors.white.withValues(alpha: 0.07),
        topEdge: Colors.white.withValues(alpha: 0.26),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.165),
              Colors.white.withValues(alpha: 0.06),
              Colors.white.withValues(alpha: 0.095),
            ],
            stops: const [0, 0.58, 1],
          ),
        ),
      ),
    );
  }
}
