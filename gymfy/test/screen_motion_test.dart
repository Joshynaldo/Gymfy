// Motion where it lands on actual screens: the card that changes underneath
// you, the row that arrives when you log a set, and the still that flies into
// its detail screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/shared/widgets/exercise_thumbnail.dart';

import 'support/default_accent.dart';

/// The thumbnail reads the accent from a provider; pinning it keeps these
/// tests off the database.
Widget _app(Widget child) => ProviderScope(
  overrides: [defaultAccentOverride],
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  group('the exercise hero', () {
    test('both ends derive their tag from the same place', () {
      // A Hero whose halves disagree by one character does not fail — it
      // silently stops flying, which is indistinguishable from the animation
      // never having been written. So neither end spells the tag out.
      expect(exerciseHeroTag('bench-press'), exerciseHeroTag('bench-press'));
      expect(
        exerciseHeroTag('bench-press'),
        isNot(exerciseHeroTag('incline-press')),
      );
    });

    testWidgets('a still only flies when a list asks it to', (tester) async {
      // The picker, the day builder and the active workout all draw the same
      // exercises. If the thumbnail carried a tag by default, any screen
      // showing an exercise twice — or two of these lists at once — would
      // assert on duplicate tags.
      await tester.pumpWidget(
        _app(const ExerciseThumbnail(gifPath: 'assets/exercises/squat.webp')),
      );

      expect(find.byType(Hero), findsNothing);
    });

    testWidgets('and does when it is given a tag', (tester) async {
      await tester.pumpWidget(
        _app(
          ExerciseThumbnail(
            gifPath: 'assets/exercises/squat.webp',
            heroTag: exerciseHeroTag('squat'),
          ),
        ),
      );

      expect(find.byType(Hero), findsOneWidget);
    });

    testWidgets('an exercise with no animation never flies', (tester) async {
      // The fallback is the shared dumbbell icon. Flying that into a video
      // would be an animation making a promise about the destination that the
      // destination does not keep.
      await tester.pumpWidget(
        _app(
          ExerciseThumbnail(
            gifPath: null,
            heroTag: exerciseHeroTag('custom-lift'),
          ),
        ),
      );

      expect(find.byType(Hero), findsNothing);
    });
  });
}
