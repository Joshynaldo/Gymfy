// Content passing behind the bars: the arrangement that makes the glass mean
// something, and the padding rules that stop it hiding anything.
//
// This is the riskiest part of the redesign, because getting it wrong looks
// fine on the screen you happened to check and hides the last row of a list on
// one you didn't. The failure mode is silent, so it is tested rather than
// eyeballed.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/app/theme/glass.dart';
import 'package:gymfy/shared/widgets/glass_dialog.dart';
import 'package:gymfy/shared/widgets/glass_scaffold.dart';

import 'support/default_accent.dart';

/// Reads [barInsets] from inside a screen laid out the way the app lays it out.
Future<EdgeInsets> _insetsInside(
  WidgetTester tester,
  AppTheme theme, {
  bool wrapInSafeArea = false,
}) async {
  late EdgeInsets seen;

  Widget probe(BuildContext context) {
    seen = barInsets(context);
    return const SizedBox.shrink();
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [defaultAccentOverride],
      child: MaterialApp(
        theme: buildAppTheme(theme, AccentPalette.blue),
        home: GlassScaffold(
          appBar: AppBar(title: const Text('Screen')),
          body: (context) => wrapInSafeArea
              ? SafeArea(child: Builder(builder: probe))
              : Builder(builder: probe),
        ),
      ),
    ),
  );
  await tester.pump();
  return seen;
}

void main() {
  group('GlassScaffold', () {
    testWidgets('lays the body behind the bar on a glass theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [defaultAccentOverride],
          child: MaterialApp(
            theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
            home: GlassScaffold(
              appBar: AppBar(title: const Text('Screen')),
              body: (context) => const SizedBox.shrink(),
            ),
          ),
        ),
      );

      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).extendBodyBehindAppBar,
        isTrue,
      );
    });

    testWidgets('leaves the flat themes laid out as they were', (tester) async {
      for (final theme in AppTheme.values.where((t) => t != AppTheme.hyper)) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [defaultAccentOverride],
            child: MaterialApp(
              theme: buildAppTheme(theme, AccentPalette.blue),
              home: GlassScaffold(
                appBar: AppBar(title: const Text('Screen')),
                body: (context) => const SizedBox.shrink(),
              ),
            ),
          ),
        );

        expect(
          tester.widget<Scaffold>(find.byType(Scaffold)).extendBodyBehindAppBar,
          isFalse,
          reason: theme.name,
        );
      }
    });
  });

  group('barInsets', () {
    testWidgets('clears the app bar on a glass theme', (tester) async {
      final insets = await _insetsInside(tester, AppTheme.hyper);

      // Whatever the bar occupies — the number is Scaffold's, not ours. What
      // matters is that a list adding this cannot start underneath the title.
      expect(insets.top, greaterThanOrEqualTo(kToolbarHeight));
    });

    testWidgets('is nothing at all on a flat theme', (tester) async {
      // The compatibility promise: six themes keep the layout they had, and
      // adding barInsets to their padding changes not one pixel.
      for (final theme in AppTheme.values.where((t) => t != AppTheme.hyper)) {
        expect(
          await _insetsInside(tester, theme),
          EdgeInsets.zero,
          reason: theme.name,
        );
      }
    });

    testWidgets('a SafeArea in between eats it', (tester) async {
      // Not a bug — it is what SafeArea is for — but it is the trap in this
      // whole arrangement, and it cost the Stats screen its top padding until
      // the SafeArea came out. A screen cannot both hand its insets to a list
      // and consume them on the way down.
      final insets = await _insetsInside(
        tester,
        AppTheme.hyper,
        wrapInSafeArea: true,
      );

      expect(insets, EdgeInsets.zero);
    });

    testWidgets('splits into a top and a bottom half that agree', (
      tester,
    ) async {
      late EdgeInsets whole;
      late EdgeInsets top;
      late EdgeInsets bottom;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [defaultAccentOverride],
          child: MaterialApp(
            theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
            home: GlassScaffold(
              appBar: AppBar(title: const Text('Screen')),
              body: (context) => Builder(
                builder: (context) {
                  whole = barInsets(context);
                  top = topBarInset(context);
                  bottom = bottomBarInset(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(top.top, whole.top);
      expect(bottom.bottom, whole.bottom);
      // The halves are halves: a screen using both must not pad twice.
      expect(top.bottom, 0);
      expect(bottom.top, 0);
    });
  });

  group('GlassDialog', () {
    Future<void> pump(WidgetTester tester, AppTheme theme) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [defaultAccentOverride],
          child: MaterialApp(
            theme: buildAppTheme(theme, AccentPalette.blue),
            home: const Scaffold(
              body: GlassDialog(
                title: Text('Rename'),
                content: Text('Pick a new name.'),
                actions: [Text('Save')],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('is a plain AlertDialog on a flat theme', (tester) async {
      await pump(tester, AppTheme.darkDefault);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('blurs the screen behind it on a glass theme', (tester) async {
      // The one surface where the blur is unarguable: a dialog genuinely covers
      // content, so filtering it keeps the sense that the screen is still there
      // while making sure none of it competes with the question.
      await pump(tester, AppTheme.hyper);

      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Pick a new name.'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('keeps its fill readable rather than glassy', (tester) async {
      // Text sits directly on this, over moving content. A card's few percent
      // of white would leave it unreadable — glass you can read a paragraph
      // through is a window.
      await pump(tester, AppTheme.hyper);

      // Asserted against the material rather than against the widget tree: the
      // fill is a property of the sheet tier, and a test that reaches for the
      // third DecoratedBox inside a BackdropFilter breaks every time the pane
      // gains a wrapper without ever having checked the thing that matters.
      final glass = buildAppTheme(
        AppTheme.hyper,
        AccentPalette.blue,
      ).extension<GlassStyle>()!;

      for (final stop in glass.sheet.fill) {
        expect(
          stop.a,
          greaterThan(0.7),
          reason: 'a sheet you can read a paragraph through is a window',
        );
      }
    });
  });
}
