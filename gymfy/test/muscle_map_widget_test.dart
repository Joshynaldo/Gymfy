// Exercises the MuscleMap widget end to end: it loads a real SVG asset,
// rewrites the muscle fills, and renders without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/muscle_map/widgets/muscle_map.dart';
import 'package:gymfy/shared/models/muscle_ids.dart';

void main() {
  testWidgets('renders an SVG for each body side with intensities', (
    tester,
  ) async {
    for (final side in BodySide.values) {
      await tester.pumpWidget(
        ProviderScope(
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
      await tester.pumpAndSettle();

      expect(find.byType(SvgPicture), findsOneWidget);
    }
  });
}
