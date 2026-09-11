// The app's chrome on the glass theme: the bar at the top, the bar at the
// bottom, and the transition between tabs.
//
// These are the two widgets every screen wears, so a mistake in either is a
// mistake everywhere — which is also why they are worth the cost of a test each
// rather than being eyeballed once.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/router/scaffold_with_nav_bar.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/app/theme/glass.dart';
import 'package:gymfy/shared/widgets/glass_app_bar.dart';
import 'package:gymfy/shared/widgets/glass_nav_bar.dart';

import 'support/default_accent.dart';

Future<void> _pump(
  WidgetTester tester,
  AppTheme theme, {
  PreferredSizeWidget? appBar,
  Widget? bottom,
  Widget body = const SizedBox.shrink(),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [defaultAccentOverride],
      child: MaterialApp(
        theme: buildAppTheme(theme, AccentPalette.blue),
        home: Scaffold(appBar: appBar, body: body, bottomNavigationBar: bottom),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('the app bar', () {
    testWidgets('is an ordinary bar on a flat theme', (tester) async {
      await _pump(
        tester,
        AppTheme.darkDefault,
        appBar: const GlassAppBar(title: Text('Exercises')),
      );

      final bar = tester.widget<AppBar>(find.byType(AppBar));
      // No pane, and no colour override: the flat themes get exactly the bar
      // they had before any of this existed.
      expect(bar.flexibleSpace, isNull);
      expect(bar.backgroundColor, isNull);
      expect(find.text('Exercises'), findsOneWidget);
    });

    testWidgets('becomes a pane on the glass theme', (tester) async {
      await _pump(
        tester,
        AppTheme.hyper,
        appBar: const GlassAppBar(title: Text('Exercises')),
      );

      final bar = tester.widget<AppBar>(find.byType(AppBar));
      expect(bar.flexibleSpace, isNotNull);
      // Transparent, so what you see is the pane and the drifting field behind
      // it rather than a block of palette grey.
      expect(bar.backgroundColor, Colors.transparent);
    });

    testWidgets('and the pane is actually a size', (tester) async {
      // A regression test for a bug that produced no error and no warning: the
      // pane was a DecoratedBox with no child, which takes the smallest size it
      // is offered — nothing. It painted a perfectly correct gradient into a
      // zero-by-zero box, and looked exactly like having written no bar at all.
      await _pump(
        tester,
        AppTheme.hyper,
        appBar: const GlassAppBar(title: Text('Exercises')),
      );

      final pane = tester.widget<AppBar>(find.byType(AppBar)).flexibleSpace!;
      final size = tester.getSize(find.byWidget(pane));

      expect(size.height, greaterThan(0));
      expect(size.width, greaterThan(0));
    });

    testWidgets('does not darken itself when content scrolls under it', (
      tester,
    ) async {
      // Material 3's scrolled-under tint is a sensible cue on an opaque bar and
      // a mess on a translucent one, where it fights the tint it is layered
      // over.
      await _pump(
        tester,
        AppTheme.hyper,
        appBar: const GlassAppBar(title: Text('Exercises')),
      );

      expect(
        tester.widget<AppBar>(find.byType(AppBar)).scrolledUnderElevation,
        0,
      );
    });
  });

  group('the navigation bar', () {
    Widget navBar() => GlassNavBar(
      selectedIndex: 0,
      onDestinationSelected: (_) {},
      destinations: mainDestinations,
    );

    testWidgets('spans the screen on a flat theme', (tester) async {
      await _pump(tester, AppTheme.darkDefault, bottom: navBar());

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(GlassSurface), findsNothing);
      expect(
        tester.getSize(find.byType(NavigationBar)).width,
        tester.view.physicalSize.width / tester.view.devicePixelRatio,
      );
    });

    testWidgets('floats as a pill on the glass theme', (tester) async {
      await _pump(tester, AppTheme.hyper, bottom: navBar());

      expect(find.byType(GlassSurface), findsOneWidget);
      // Narrower than the screen is the whole point: a bar welded to the bottom
      // edge is chrome, a bar hovering above it is an object in front of the
      // content.
      final screenWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(
        tester.getSize(find.byType(NavigationBar)).width,
        lessThan(screenWidth),
      );
    });

    testWidgets('is still a real NavigationBar inside the pill', (
      tester,
    ) async {
      // The pill is a shape, not a reimplementation. Rolling our own would mean
      // rebuilding the selection indicator, the label behaviour, the ripples
      // and the semantics — and every one of those is an accessibility
      // affordance somebody relies on.
      await _pump(tester, AppTheme.hyper, bottom: navBar());

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.destinations.length, mainDestinations.length);
      expect(find.text('Workout'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
    });

    testWidgets('does not pad itself away from its own bottom edge', (
      tester,
    ) async {
      // NavigationBar adds the system gesture inset itself. Inside a floating
      // pill that lands *inside* the glass, pushing the icons up and leaving a
      // band of empty pane beneath them, on top of the margin already holding
      // the pill clear of the screen.
      tester.view.padding = const FakeViewPadding(bottom: 96);
      addTearDown(tester.view.resetPadding);

      await _pump(tester, AppTheme.hyper, bottom: navBar());

      final pill = tester.getRect(find.byType(GlassSurface));
      final bar = tester.getRect(find.byType(NavigationBar));

      expect(bar.bottom - pill.bottom, closeTo(0, 1));
    });
  });

  group('switching tabs', () {
    Future<void> pumpTabs(WidgetTester tester, int index) => tester.pumpWidget(
      MaterialApp(
        home: TabTransition(index: index, child: const Text('tab body')),
      ),
    );

    double opacity(WidgetTester tester) => tester
        .widget<Opacity>(
          find.descendant(
            of: find.byType(TabTransition),
            matching: find.byType(Opacity),
          ),
        )
        .opacity;

    testWidgets('the first tab is simply there', (tester) async {
      // The app opening should not look like a tab being switched to.
      await pumpTabs(tester, 0);

      expect(opacity(tester), 1);
    });

    testWidgets('a new tab settles in rather than cutting', (tester) async {
      await pumpTabs(tester, 0);
      await pumpTabs(tester, 1);
      await tester.pump(const Duration(milliseconds: 16));

      final mid = opacity(tester);
      expect(mid, lessThan(1));
      // Never from nothing: fading up from zero blinks the screen dark on every
      // tab press, which is worse than the cut it replaces.
      expect(mid, greaterThan(0.3));

      await tester.pumpAndSettle();
      expect(opacity(tester), 1);
    });

    testWidgets('honours reduced motion', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: TabTransition(index: 0, child: Text('tab body')),
          ),
        ),
      );
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: TabTransition(index: 1, child: Text('tab body')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(opacity(tester), 1);
    });
  });
}
