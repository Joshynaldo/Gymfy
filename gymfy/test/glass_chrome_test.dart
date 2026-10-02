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
    Widget navBar({int selected = 0, ValueChanged<int>? onSelected}) => Builder(
      builder: (context) => GlassNavBar(
        selectedIndex: selected,
        onDestinationSelected: onSelected ?? (_) {},
        destinations: mainDestinations(context),
      ),
    );

    /// The pill itself, not the padding that floats it.
    Finder pill() => find.descendant(
      of: find.byType(GlassNavBar),
      matching: find.byType(GlassSurface),
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

    testWidgets('keeps its labels on a flat theme', (tester) async {
      await _pump(tester, AppTheme.darkDefault, bottom: navBar());

      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).labelBehavior,
        isNull,
        reason: 'the flat themes keep the bar they have always had',
      );
    });

    testWidgets('floats as a pill on the glass theme', (tester) async {
      await _pump(tester, AppTheme.hyper, bottom: navBar());

      expect(pill(), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      // Narrower than the screen is the whole point: a bar welded to the bottom
      // edge is chrome, a bar hovering above it is an object in front of the
      // content.
      final screenWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(tester.getSize(pill()).width, lessThan(screenWidth));
    });

    testWidgets('has one tab per destination, each a button with its name', (
      tester,
    ) async {
      // The pill's tabs are the design's own rather than Material's, so the
      // things the Material bar gave for free are checked here instead: every
      // tab is announced as a button, by name, and says whether it's the one
      // you're on.
      await _pump(tester, AppTheme.hyper, bottom: navBar(selected: 1));

      final tabs = find.byType(GlassNavTab);
      expect(tabs, findsNWidgets(4));
      expect(
        tester.getSemantics(tabs.at(1)),
        isSemantics(label: 'Workout', isButton: true, isSelected: true),
      );
      expect(
        tester.getSemantics(tabs.at(2)),
        isSemantics(label: 'Progress', isButton: true, isSelected: false),
      );
    });

    testWidgets('shows icons only, but still knows its labels', (tester) async {
      // Four labels across a pill inset from both edges is four lines of tiny
      // type competing with the screen above them, and these four are the
      // destinations you learn on the first day.
      //
      // Hidden, not removed: each tab keeps its name as its tooltip and its
      // label for screen readers. That is the difference between a visual
      // decision and an accessibility one.
      await _pump(tester, AppTheme.hyper, bottom: navBar());

      for (final label in ['Home', 'Workout', 'Progress', 'More']) {
        expect(find.text(label), findsNothing, reason: label);
        expect(find.byTooltip(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('a tap reports the tab', (tester) async {
      final picked = <int>[];
      await _pump(
        tester,
        AppTheme.hyper,
        bottom: navBar(onSelected: picked.add),
      );

      await tester.tap(find.byType(GlassNavTab).at(3));

      expect(picked, [3]);
    });

    testWidgets('the selected tab gets a pane of glass that fades in', (
      tester,
    ) async {
      // The design's tab switch: the old tab's pane fades out as the new one
      // fades in, rather than Material's capsule growing behind the icon.
      double paneOpacity(int tab) => tester
          .widget<AnimatedOpacity>(
            find.descendant(
              of: find.byType(GlassNavTab).at(tab),
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .opacity;

      await _pump(tester, AppTheme.hyper, bottom: navBar(selected: 0));
      expect(paneOpacity(0), 1);
      expect(paneOpacity(2), 0);

      await _pump(tester, AppTheme.hyper, bottom: navBar(selected: 2));
      expect(paneOpacity(0), 0);
      expect(paneOpacity(2), 1);

      // Partway through, not cut over in one frame.
      final fading = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byType(GlassNavTab).at(2),
          matching: find.byType(FadeTransition),
        ),
      );
      await tester.pump(const Duration(milliseconds: 60));
      expect(fading.opacity.value, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(fading.opacity.value, 1);
    });

    testWidgets('does not pad itself away from its own bottom edge', (
      tester,
    ) async {
      // The system gesture inset holds the pill clear of the screen edge; it
      // must not also land *inside* the glass, pushing the icons up and
      // leaving a band of empty pane beneath them.
      tester.view.padding = const FakeViewPadding(bottom: 96);
      addTearDown(tester.view.resetPadding);

      await _pump(tester, AppTheme.hyper, bottom: navBar());

      final glass = tester.getRect(pill());
      final tab = tester.getRect(find.byType(GlassNavTab).first);

      // The tabs sit in the pill with its own 5px of padding, and no more.
      expect(glass.bottom - tab.bottom, closeTo(5, 1));
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
