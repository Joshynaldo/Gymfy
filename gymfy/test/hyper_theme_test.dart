// The Hyper theme: glass surfaces over a living backdrop.
//
// The only theme that is a construction rather than a palette, so it is the
// only one whose *mechanics* need testing — that the material is switched on,
// that every other theme is untouched by it, and that the backdrop stops
// animating when nobody is looking at it.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/app/theme/glass.dart';
import 'package:gymfy/app/theme/hyper_backdrop.dart';
import 'package:gymfy/shared/widgets/app_card.dart';

import 'support/default_accent.dart';

/// Pumps [child] under [theme], with the backdrop in place as the app has it.
Future<void> _pump(
  WidgetTester tester,
  AppTheme theme, {
  Widget child = const SizedBox.shrink(),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [defaultAccentOverride],
      child: MaterialApp(
        theme: buildAppTheme(theme, AccentPalette.blue),
        builder: (context, inner) => HyperBackdrop(child: inner!),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('the theme', () {
    test('is offered in the picker like any other', () {
      expect(AppTheme.values, contains(AppTheme.hyper));
      expect(AppTheme.parse('hyper'), AppTheme.hyper);
    });

    test('turns the glass material on, and only it does', () {
      for (final theme in AppTheme.values) {
        final glass = buildAppTheme(
          theme,
          AccentPalette.blue,
        ).extension<GlassStyle>();

        expect(glass, isNotNull, reason: '${theme.name} has no glass style');
        expect(
          glass!.enabled,
          theme == AppTheme.hyper,
          reason: '${theme.name} glass should be ${theme == AppTheme.hyper}',
        );
      }
    });

    test('glass surfaces are translucent, or the blur is wasted', () {
      // An opaque tint would paint over the very thing it is blurring, which
      // is the mistake that makes "glass" look like a slightly different grey.
      final glass = buildAppTheme(
        AppTheme.hyper,
        AccentPalette.blue,
      ).extension<GlassStyle>()!;

      expect(glass.tint.a, lessThan(0.5));
      expect(glass.blur, greaterThan(0));
    });

    test('a flat theme falls all the way through to an opaque box', () {
      final glass = buildAppTheme(
        AppTheme.darkDefault,
        AccentPalette.blue,
      ).extension<GlassStyle>()!;

      expect(glass.enabled, isFalse);
      expect(glass.blur, 0);
    });
  });

  group('the backdrop', () {
    testWidgets('paints nothing on a flat theme', (tester) async {
      await _pump(tester, AppTheme.darkDefault);

      expect(find.byType(CustomPaint), findsWidgets); // Material's own
      // The telling one: with no glass there is no repeating animation, so the
      // tree comes to rest. This is also the assertion that would have caught
      // the ticker running on every theme.
      await tester.pumpAndSettle();
    });

    testWidgets('keeps animating while the glass theme is on', (tester) async {
      await _pump(tester, AppTheme.hyper);

      // Never settles, by design — the field drifts for as long as it is shown.
      // `pumpAndSettle` would time out here, so the frames are pumped by hand.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });

    testWidgets('holds still under reduced motion, but stays painted', (
      tester,
    ) async {
      // The drift is continuous, behind everything, and never ends — the
      // clearest case in the app for the setting, and it was ignoring it.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [defaultAccentOverride],
          child: MaterialApp(
            theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
            builder: (context, inner) => MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: HyperBackdrop(child: inner!),
            ),
            home: const Scaffold(body: SizedBox.shrink()),
          ),
        ),
      );

      // Settles, where the same tree on the glass theme never does. That is
      // the whole assertion: the ticker is not running.
      await tester.pumpAndSettle();

      // And the field is still there. Removing it instead of freezing it would
      // also pass the line above, and would leave every glass surface tinting
      // flat black — which is what the backdrop exists to prevent.
      expect(find.byType(HyperBackdrop), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('cards', () {
    testWidgets('become panes on the glass theme', (tester) async {
      await _pump(
        tester,
        AppTheme.hyper,
        child: const AppCard(child: Text('hello')),
      );

      expect(find.byType(GlassSurface), findsOneWidget);
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('but do not pay for a blur they cannot use', (tester) async {
      // A card lies directly on the backdrop, so the only thing behind it is a
      // smooth colour field — and a blurred smooth field is the same smooth
      // field. The BackdropFilter would be an offscreen render pass per card,
      // on a scrolling list, for a result identical to the pixel.
      //
      // Worth a test rather than a comment: it is exactly the kind of cost that
      // gets reintroduced by someone reading `GlassSurface` and assuming every
      // pane should blur.
      await _pump(
        tester,
        AppTheme.hyper,
        child: const AppCard(child: Text('hello')),
      );

      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('stay ordinary boxes everywhere else', (tester) async {
      // The compatibility story: six existing themes must look exactly as they
      // did, and nothing about them should now cost a blur pass.
      for (final theme in AppTheme.values.where((t) => t != AppTheme.hyper)) {
        await _pump(tester, theme, child: const AppCard(child: Text('hello')));

        expect(find.byType(GlassSurface), findsNothing, reason: theme.name);
        expect(find.byType(BackdropFilter), findsNothing, reason: theme.name);
      }
    });
  });
}
