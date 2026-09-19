// The small motions: a surface giving way under a finger, a number travelling
// to its new value, and content arriving into a screen already on display.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/shared/widgets/animated_count.dart';
import 'package:gymfy/shared/widgets/fade_slide_in.dart';
import 'package:gymfy/shared/widgets/pressable.dart';

/// The scale the [Pressable] is currently drawing its child at.
double _scale(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find
        .descendant(
          of: find.byType(Pressable),
          matching: find.byType(Transform),
        )
        .first,
  );
  // entry(0, 0), not getMaxScaleOnAxis(): that returns the largest scale across
  // all three axes, and Transform.scale leaves z at 1 — so every shrink would
  // read back as exactly 1.0 and this helper would quietly always pass.
  return transform.transform.entry(0, 0);
}

void main() {
  group('Pressable', () {
    testWidgets('gives way under the finger and springs back', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Pressable(
                onTap: () {},
                child: const SizedBox(width: 200, height: 80),
              ),
            ),
          ),
        ),
      );

      expect(_scale(tester), 1);

      final press = await tester.startGesture(
        tester.getCenter(find.byType(Pressable)),
      );
      // Two pumps, both load-bearing. With no other recogniser competing for
      // the pointer, the tap gesture only claims it once kPressTimeout has
      // expired, so the first pump is what gets the InkWell to report a press
      // at all — and the controller does not tick until the frame after it is
      // started, so the second is what gets it to move.
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        _scale(tester),
        lessThan(1),
        reason: 'the surface should be moving away under the finger',
      );

      await press.up();
      await tester.pumpAndSettle();
      expect(_scale(tester), closeTo(1, 0.001));
    });

    testWidgets('the give is felt, not watched', (tester) async {
      // Small on purpose. Anything deeper and a list of cards visibly jumps
      // around as you scan it.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Pressable(
                onTap: () {},
                child: const SizedBox(width: 200, height: 80),
              ),
            ),
          ),
        ),
      );

      final press = await tester.startGesture(
        tester.getCenter(find.byType(Pressable)),
      );
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      final pressed = _scale(tester);
      expect(pressed, lessThan(1));
      expect(pressed, greaterThan(0.9));

      await press.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a decorative one is disposed without a murmur', (
      tester,
    ) async {
      // A regression test for a crash with a genuinely confusing cause. The
      // controller was created lazily, so for a Pressable that was never
      // pressed, dispose() was the first code to touch it — and building an
      // AnimationController needs a lookup up the widget tree, which is illegal
      // once the element is being torn down. Every card with no onTap took the
      // whole screen down on the way out.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Pressable(child: SizedBox(width: 200, height: 80)),
          ),
        ),
      );
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      expect(tester.takeException(), isNull);
    });

    testWidgets('stays still when the platform asks for less motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Center(
                child: Pressable(
                  onTap: () {},
                  child: const SizedBox(width: 200, height: 80),
                ),
              ),
            ),
          ),
        ),
      );

      final press = await tester.startGesture(
        tester.getCenter(find.byType(Pressable)),
      );
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 60));
      expect(_scale(tester), 1);

      await press.up();
      await tester.pumpAndSettle();
    });

    testWidgets('still reports the tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Pressable(
                onTap: () => taps++,
                child: const SizedBox(width: 200, height: 80),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Pressable));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });
  });

  group('AnimatedCount', () {
    Future<void> pump(WidgetTester tester, double value, {double? from}) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedCount(
                value: value,
                from: from,
                format: (value) => value.round().toString(),
              ),
            ),
          ),
        );

    testWidgets('is simply there on arrival', (tester) async {
      // Counting up from zero is a nice flourish exactly once and an irritation
      // every time after that, so it is opt-in rather than the default.
      await pump(tester, 1200);

      expect(find.text('1200'), findsOneWidget);
    });

    testWidgets('travels when the value changes', (tester) async {
      await pump(tester, 1200);
      await pump(tester, 2400);
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.text('2400'), findsNothing);
      expect(find.text('1200'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('2400'), findsOneWidget);
    });

    testWidgets('counts up from nothing when asked', (tester) async {
      await pump(tester, 1200, from: 0);

      expect(find.text('1200'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('1200'), findsOneWidget);
    });

    testWidgets('never shows a number that was not true', (tester) async {
      // Uses the settle curve rather than a spring: a count that runs past its
      // target and comes back has, for a few frames, displayed a weight nobody
      // lifted.
      await pump(tester, 100, from: 0);

      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final shown = int.parse(tester.widget<Text>(find.byType(Text)).data!);
        expect(shown, lessThanOrEqualTo(100));
      }
    });

    testWidgets('lands on the value even with no motion', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: AnimatedCount(value: 750, from: 0, format: _round),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('750'), findsOneWidget);
    });
  });

  group('FadeSlideIn', () {
    // Used on list rows, the staggered hub, and keyed content swaps. It was
    // the only animated widget in the app that never asked about reduced
    // motion — so a person who turns that setting on because movement makes
    // them ill still had every row in the app slide and fade at them.
    //
    // Checked through the widget's own output rather than its internals: the
    // opacity and the offset are what a person actually receives.

    /// The opacity and vertical offset [FadeSlideIn] is currently drawing at.
    (double, double) drawnAt(WidgetTester tester) {
      final fade = tester.widget<FadeTransition>(
        find
            .descendant(
              of: find.byType(FadeSlideIn),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      final transform = tester.widget<Transform>(
        find
            .descendant(
              of: find.byType(FadeSlideIn),
              matching: find.byType(Transform),
            )
            .first,
      );
      return (fade.opacity.value, transform.transform.getTranslation().y);
    }

    Future<void> pump(WidgetTester tester, {required bool reduceMotion}) {
      return tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: const Scaffold(body: FadeSlideIn(child: Text('a row'))),
          ),
        ),
      );
    }

    testWidgets('arrives already in place under reduced motion', (
      tester,
    ) async {
      await pump(tester, reduceMotion: true);

      // On the very first frame, before any time has passed. Not "faster" —
      // there is nothing to wait through, because a shortened animation is
      // still an animation.
      expect(drawnAt(tester), (1.0, 0.0));
    });

    testWidgets('still animates when motion is welcome', (tester) async {
      // The other half. Without this, deleting the animation entirely would
      // pass the test above, and the app would lose the thing it was built
      // for.
      await pump(tester, reduceMotion: false);

      final (opacity, offset) = drawnAt(tester);
      expect(opacity, lessThan(1), reason: 'it should start transparent');
      expect(offset, greaterThan(0), reason: 'and a few pixels low');

      await tester.pumpAndSettle();
      expect(drawnAt(tester), (1.0, 0.0), reason: 'and settle flush');
    });
  });
}

String _round(double value) => value.round().toString();
