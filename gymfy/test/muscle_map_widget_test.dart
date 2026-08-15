// Exercises the MuscleMap widget end to end: it loads a real SVG asset,
// rewrites the muscle fills, and renders without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/muscle_map/widgets/muscle_map.dart';
import 'package:gymfy/shared/models/muscle_ids.dart';

import 'support/default_accent.dart';

void main() {
  testWidgets('renders an SVG for each body side with intensities', (
    tester,
  ) async {
    for (final side in BodySide.values) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [defaultAccentOverride],
          child: MaterialApp(
            home: Scaffold(
              body: MuscleMap(
                side: side,
                intensities: const {MuscleId.chest: 1, MuscleId.lats: 0.5},
              ),
            ),
          ),
        ),
      );
      // Loading the SVG asset and decoding it are real async work, which the
      // fake test clock won't advance. runAsync lets them actually complete;
      // then a pump rebuilds with the loaded picture.
      await tester.runAsync(() async {
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (find.byType(SvgPicture).evaluate().isNotEmpty) break;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SvgPicture), findsOneWidget);
    }
  });
}
