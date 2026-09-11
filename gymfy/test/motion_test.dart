// The motion language: the curves everything moves on, and the promise that
// none of it happens when the platform asks for reduced motion.
//
// Curves are worth testing the way a formula is worth testing. A mistuned
// constant does not throw — it produces an animation that is subtly wrong in a
// way nobody can name, and the two properties below (a spring overshoots, a
// settle does not) are exactly the ones a well-meaning tweak destroys.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/app/theme/motion.dart';

/// Samples a curve across its whole range.
List<double> _samples(Curve curve, {int steps = 200}) => [
  for (var i = 0; i <= steps; i++) curve.transform(i / steps),
];

void main() {
  group('SpringCurve', () {
    test('starts at nothing and arrives exactly', () {
      for (final curve in [
        AppCurves.spring,
        AppCurves.settle,
        AppCurves.emphasis,
      ]) {
        expect(curve.transform(0), 0);
        expect(curve.transform(1), 1);
      }
    });

    test('has settled before it is cut off', () {
      // The one that actually matters. Curve.transform returns 1 at t == 1 by
      // definition, so a badly tuned spring hides its failure right up to the
      // last frame and then jumps — the exact snap the spring exists to
      // prevent. Sampling just short of the end is what catches it.
      for (final curve in [
        AppCurves.spring,
        AppCurves.settle,
        AppCurves.emphasis,
      ]) {
        expect(
          curve.transform(0.99),
          closeTo(1, 0.01),
          reason: '$curve is still moving when its time runs out',
        );
      }
    });

    test('a spring overshoots — that is what makes it a spring', () {
      expect(
        _samples(AppCurves.spring).reduce((a, b) => a > b ? a : b),
        greaterThan(1),
      );
    });

    test('the overshoot is weight, not bounce', () {
      // Past about 20% the movement stops reading as momentum and starts
      // reading as a cartoon.
      expect(
        _samples(AppCurves.spring).reduce((a, b) => a > b ? a : b),
        lessThan(1.2),
      );
    });

    test('settle never passes its target', () {
      // Used for anything whose *size* changes. A single frame above 1 there
      // means content briefly larger than the box holding it, which shows up as
      // clipping or a scrollbar flicking in and out.
      for (final value in _samples(AppCurves.settle)) {
        expect(value, lessThanOrEqualTo(1.0001));
      }
    });

    test('every curve moves forward for most of its life', () {
      // Guards against a curve that stalls: a long flat stretch reads as the
      // app having hung, whatever the total duration says.
      final values = _samples(AppCurves.settle, steps: 20);
      for (var i = 1; i < values.length; i++) {
        expect(values[i], greaterThan(values[i - 1]));
      }
    });
  });

  group('reduced motion', () {
    testWidgets('collapses every duration to nothing', (tester) async {
      late Duration enabled;
      late Duration disabled;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Builder(
            builder: (context) {
              enabled = motionOf(context, AppDurations.standard);
              return MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: Builder(
                  builder: (context) {
                    disabled = motionOf(context, AppDurations.standard);
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(enabled, AppDurations.standard);
      // Not "shorter" — none at all. Reduce motion is an accessibility setting
      // people turn on because movement makes them ill, so a faster animation
      // is still the wrong answer.
      expect(disabled, Duration.zero);
    });

    testWidgets('hands the page transition straight through', (tester) async {
      final builder = const GymfyPageTransitionsBuilder();
      const child = SizedBox.shrink();
      late Widget result;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              result = builder.buildTransitions<void>(
                MaterialPageRoute(builder: (_) => child),
                context,
                const AlwaysStoppedAnimation(0.5),
                const AlwaysStoppedAnimation(0),
                child,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(identical(result, child), isTrue);
    });
  });

  group('page transitions', () {
    test('are used on Android, and not on iOS', () {
      // Cupertino's builder is also what installs the swipe-from-the-edge back
      // gesture. Replacing it would trade a nicer animation for a navigation
      // gesture every iPhone user already has in their hands, so iOS keeps its
      // own — and this is here so a later "let's be consistent" edit has to be
      // a deliberate one.
      final builders = buildAppTheme(
        AppTheme.hyper,
        AccentPalette.blue,
      ).pageTransitionsTheme.builders;

      expect(
        builders[TargetPlatform.android],
        isA<GymfyPageTransitionsBuilder>(),
      );
      expect(
        builders[TargetPlatform.iOS],
        isNot(isA<GymfyPageTransitionsBuilder>()),
      );
    });

    test('every theme moves the same way', () {
      // Motion is not a palette decision: the glass theme is a material, not a
      // different app.
      for (final theme in AppTheme.values) {
        expect(
          buildAppTheme(
            theme,
            AccentPalette.blue,
          ).pageTransitionsTheme.builders[TargetPlatform.android],
          isA<GymfyPageTransitionsBuilder>(),
          reason: theme.name,
        );
      }
    });

    testWidgets('the outgoing screen never fades to nothing', (tester) async {
      // If it did, there would be a frame or two of the gap between the two
      // screens showing the backdrop straight through — which reads as a flash
      // rather than as one screen covering another.
      const builder = GymfyPageTransitionsBuilder();
      late Widget result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = builder.buildTransitions<void>(
                MaterialPageRoute(builder: (_) => const SizedBox.shrink()),
                context,
                const AlwaysStoppedAnimation(1),
                // Fully covered by the next screen.
                const AlwaysStoppedAnimation(1),
                const SizedBox.shrink(),
              );
              return result;
            },
          ),
        ),
      );

      final fades = tester.widgetList<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fades, isNotEmpty);
      for (final fade in fades) {
        expect(fade.opacity.value, greaterThan(0));
      }
    });
  });
}
