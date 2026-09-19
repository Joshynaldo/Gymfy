// The app's motion, audited against the animation-patterns review checklist.
//
// Three of these guard things that are invisible when broken. A missing
// reduce-motion check looks perfect to anyone who does not use the setting; a
// shader rebuilt sixty times a second looks identical to one built once. Both
// were real here, and neither would have been caught by a test that only
// asked whether the animation played.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/motion.dart';

void main() {
  group('the duration scale', () {
    test('keeps every UI duration inside the feedback budget', () {
      // "No animation exceeds ~0.5s for UI feedback; longer only for
      // decorative/ambient effects." The ambient exception is the backdrop
      // drift, which is not on this scale.
      for (final d in const [
        AppDurations.press,
        AppDurations.quick,
        AppDurations.standard,
        AppDurations.slow,
      ]) {
        expect(
          d.inMilliseconds,
          lessThanOrEqualTo(500),
          reason: '$d is long enough to read as lag rather than feedback',
        );
      }
    });

    test('and stays a scale rather than a collection of numbers', () {
      // Four steps, strictly increasing. A fifth value that sits between two
      // others is how a scale rots back into "whatever looked right".
      const steps = [
        AppDurations.press,
        AppDurations.quick,
        AppDurations.standard,
        AppDurations.slow,
      ];
      for (var i = 1; i < steps.length; i++) {
        expect(steps[i], greaterThan(steps[i - 1]));
      }
    });
  });

  group('motionOf', () {
    testWidgets('returns nothing when the system asks for reduced motion', (
      tester,
    ) async {
      late Duration seen;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              seen = motionOf(context, AppDurations.standard);
              return const SizedBox();
            },
          ),
        ),
      );

      // Zero, not "shorter". A quick animation is still an animation, and the
      // setting exists because movement makes some people ill.
      expect(seen, Duration.zero);
    });

    testWidgets('and the full duration otherwise', (tester) async {
      late Duration seen;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Builder(
            builder: (context) {
              seen = motionOf(context, AppDurations.standard);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(seen, AppDurations.standard);
    });
  });

  group('every animating widget asks about reduced motion', () {
    // A source-reading test, like one_entrance_test and one_wheel_test. The
    // behavioural alternative would be one widget test per animated widget,
    // and the failure being guarded against is someone adding the twentieth
    // one without knowing the rule exists.
    final animates = RegExp(
      r'AnimationController\(|AnimatedContainer\(|TweenAnimationBuilder|'
      r'AnimatedOpacity\(|AnimatedSwitcher\(|AnimatedAlign\(|'
      r'AnimatedPositioned\(|AnimatedScale\(|AnimatedDefaultTextStyle\(|'
      r'\.animateToPage\(|\.nextPage\(|\.previousPage\(',
    );
    final asks = RegExp(r'motionOf\(|disableAnimationsOf\(');

    test('no file animates without consulting the setting', () {
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('.g.dart')) continue;
        final source = entity.readAsStringSync();
        if (animates.hasMatch(source) && !asks.hasMatch(source)) {
          offenders.add(entity.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'these files animate but never check MediaQuery.disableAnimations. '
            'Route the duration through motionOf(context, ...) — see '
            'lib/app/theme/motion.dart',
      );
    });

    test('counter-check: the scan actually reaches the animating files', () {
      // Without this, a regex that matched nothing would pass the test above
      // perfectly and guard nothing at all.
      var found = 0;
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (animates.hasMatch(entity.readAsStringSync())) found++;
      }
      expect(found, greaterThan(8), reason: 'expected the app to animate');
    });
  });

  group('the backdrop painter', () {
    // "Per-frame closures stay cheap — no allocation, formatting, or layout
    // math inside." This one runs behind every screen for a whole session on
    // the older Android hardware the app targets, so it is the single worst
    // place in the app to do work twice.
    final source = File(
      'lib/app/theme/hyper_backdrop.dart',
    ).readAsStringSync();

    test('repaints from the controller rather than rebuilding each frame', () {
      expect(
        source,
        contains('super(repaint: drift)'),
        reason: 'the painter must outlive the frame, or the constructor work '
            'below happens sixty times a second',
      );
      expect(
        source,
        isNot(contains('AnimatedBuilder(')),
        reason: 'an AnimatedBuilder here rebuilds the painter every frame, '
            'which is exactly what `repaint:` replaced',
      );
    });

    test('does its colour conversions once, not per frame', () {
      // _shift is an RGB→HSL→RGB round trip, and none of its five results
      // depends on the drift — so every call belongs above paint(), in the
      // constructor's initialiser list.
      //
      // Counted by position rather than searched for inside the method body:
      // the only `_shift(` allowed after paint() begins is the static
      // definition itself, and a substring search would match that.
      final paintAt = source.indexOf('void paint(');
      expect(paintAt, greaterThan(0));

      final calls = '_shift('.allMatches(source).map((m) => m.start).toList();
      final before = calls.where((i) => i < paintAt).length;
      final after = calls.where((i) => i > paintAt).length;

      expect(
        before,
        5,
        reason: 'the two wash colours and three orb colours should all be '
            'computed in the constructor',
      );
      expect(
        after,
        1,
        reason: 'only the static _shift declaration itself may appear after '
            'paint() — anything else runs sixty times a second and always '
            'returns the same colour',
      );
    });

    test('and caches the full-screen wash shader by size', () {
      expect(source, contains('_washRect != rect'));
    });
  });
}
