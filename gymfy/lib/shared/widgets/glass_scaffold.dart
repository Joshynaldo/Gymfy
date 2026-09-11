import 'package:flutter/material.dart';

import '../../app/theme/glass.dart';

/// A [Scaffold] whose body runs the full height of the screen on a glass theme.
///
/// The one change: `extendBodyBehindAppBar`. Content is laid out *behind* the
/// bars rather than between them, so a list slides under the title as you
/// scroll it. That is not decoration — it is the only arrangement in which the
/// bars have anything to blur, and a translucent bar with nothing passing
/// beneath it is a tinted rectangle wearing the word "glass".
///
/// The cost is that every scrollable inside now has to clear the bars itself;
/// see [barInsets], which is the other half of this.
///
/// Off on every flat theme, where the bars are opaque and the old layout is
/// both correct and what those themes have always looked like.
///
/// Only the three Scaffold parameters Gymfy actually uses are exposed. Adding a
/// fourth the day a screen needs one is a two-line change; mirroring all thirty
/// would be a wrapper pretending to be a subclass.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  final PreferredSizeWidget? appBar;

  /// The screen, built with a context *inside* the Scaffold.
  ///
  /// A builder rather than a widget, and this is the whole reason:
  /// [barInsets] reads `MediaQuery.padding`, and the padding that accounts for
  /// the app bar only exists **below** the Scaffold. Scaffold hands it to the
  /// body; nothing above can see it.
  ///
  /// A screen that computed its padding in its own `build` therefore got the
  /// status bar alone — 44 where the answer was 100 — and the app bar's other
  /// fifty-six pixels landed on top of whatever the screen had pinned to its
  /// top. The exercise library's search field ended up half behind the bar and
  /// completely untappable, because a transparent app bar still takes the
  /// touches in its own band.
  ///
  /// Taking a builder is what makes that unrepeatable: the closure's `context`
  /// shadows the screen's, so the correct one is the one in scope, and the only
  /// way to get the old answer is to go out of your way for it.
  final Widget Function(BuildContext context)? body;

  final Widget? floatingActionButton;

  /// Where the floating button sits. Centred for the screens whose only
  /// floating control it is; a corner is where you put one of several.
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body == null ? null : Builder(builder: body!),
      // Lifted clear of the navigation pill.
      //
      // The pill belongs to the *shell's* Scaffold and the button to this one.
      // Neither knows the other exists, so this Scaffold placed its button
      // sixteen pixels off the bottom of the screen — which is underneath the
      // pill, entirely. "Add exercises" on the day builder was drawn and
      // covered, and every other floating button in the app sits in the same
      // spot.
      //
      // The number comes from the padding the shell hands down, which is how
      // much of the bottom edge its chrome occupies. Read inside the Scaffold,
      // for the same reason `body` is a builder.
      floatingActionButton: floatingActionButton == null
          ? null
          : Padding(
              padding: EdgeInsets.only(
                bottom: glassOf(context).enabled
                    ? MediaQuery.paddingOf(context).bottom
                    : 0,
              ),
              child: floatingActionButton,
            ),
      floatingActionButtonLocation: floatingActionButtonLocation,
      extendBodyBehindAppBar: glassOf(context).enabled,
    );
  }
}
