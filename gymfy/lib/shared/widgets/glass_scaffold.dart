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
  });

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      extendBodyBehindAppBar: glassOf(context).enabled,
    );
  }
}
