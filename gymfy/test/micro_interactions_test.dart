// The small motions: a surface giving way under a finger, a number travelling
// to its new value, and one bloom of light for the moments worth marking.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/shared/widgets/animated_count.dart';
import 'package:gymfy/shared/widgets/celebration.dart';
import 'package:gymfy/shared/widgets/pressable.dart';

import 'support/default_accent.dart';

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

  group('Celebration', () {
    /// How many painters are on screen with nothing celebrating.
    Future<int> baseline(WidgetTester tester) async {
      // Same overrides as the real pump below: a ProviderScope cannot change
      // how many overrides it carries between builds.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [defaultAccentOverride],
          child: const MaterialApp(home: Scaffold(body: Text('done'))),
        ),
      );
      return find.byType(CustomPaint).evaluate().length;
    }

    Future<void> pump(WidgetTester tester, {bool enabled = true}) =>
        tester.pumpWidget(
          ProviderScope(
            overrides: [defaultAccentOverride],
            child: MaterialApp(
              home: Scaffold(
                body: Celebration(enabled: enabled, child: const Text('done')),
              ),
            ),
          ),
        );

    testWidgets('blooms once and then leaves nothing behind', (tester) async {
      final quiet = await baseline(tester);

      await pump(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CustomPaint).evaluate().length, greaterThan(quiet));

      await tester.pumpAndSettle();
      // The important half. A celebration that leaves a repainting layer behind
      // is a celebration you keep paying for until the screen is closed.
      expect(find.byType(CustomPaint).evaluate().length, quiet);
      expect(find.text('done'), findsOneWidget);
    });

    testWidgets('says nothing when there is nothing to say', (tester) async {
      final quiet = await baseline(tester);

      await pump(tester, enabled: false);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CustomPaint).evaluate().length, quiet);
      expect(find.text('done'), findsOneWidget);
    });

    testWidgets('does not bloom under reduced motion', (tester) async {
      final quiet = await baseline(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [defaultAccentOverride],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: Scaffold(body: Celebration(child: Text('done'))),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CustomPaint).evaluate().length, quiet);
    });
  });
}

String _round(double value) => value.round().toString();
