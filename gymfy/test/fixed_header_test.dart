// Anything a screen pins to its top has to clear the app bar — measured, on
// the real screen, in pixels.
//
// Written after the exercise library's search field turned out to be sitting
// behind the bar and taking none of its own taps. The cause was not the number:
// `barInsets` was right. It was *where* the number was read. The padding that
// accounts for the app bar exists only below the Scaffold, and the screen was
// computing it in its own `build`, above — so it saw the status bar alone, 44
// where the answer was 100, and the bar's remaining fifty-six pixels landed on
// top of the field.
//
// Nothing looked wrong. The field was drawn, in the right place on the flat
// themes, and merely unreachable on Hyper — which is why this is measured
// rather than eyeballed.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
import 'package:gymfy/app/theme/glass.dart';
import 'package:gymfy/features/exercises/screens/exercise_library_screen.dart';
import 'package:gymfy/shared/widgets/glass_app_bar.dart';
import 'package:gymfy/shared/widgets/glass_scaffold.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

final _exercises = [
  Exercise(
    id: 'barbell_bench_press',
    name: 'Barbell bench press',
    muscleIds: const ['chest'],
    isPlateLoaded: true,
    isCustom: false,
    isArchived: false,
  ),
  Exercise(
    id: 'barbell_row',
    name: 'Barbell row',
    muscleIds: const ['lats'],
    isPlateLoaded: true,
    isCustom: false,
    isArchived: false,
  ),
];

void main() {
  testWidgets('a pinned header reads its inset from inside the scaffold', (
    tester,
  ) async {
    // The general form of the bug, kept independent of any one screen's
    // layout: a screen pins something to its top, pads it down by barInsets,
    // and the padding must account for the app bar rather than the status bar
    // alone. Read from the wrong context this comes out at 44 instead of 100
    // and the header sits behind a bar that still takes its taps.
    tester.view.padding = const FakeViewPadding(top: 44 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [...defaultDisplayOverrides],
        child: MaterialApp(
          theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
          home: GlassScaffold(
            appBar: const GlassAppBar(title: Text('Screen')),
            body: (context) => Padding(
              padding: topBarInset(context),
              child: const Align(
                alignment: Alignment.topCenter,
                child: Text('pinned'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.getTopLeft(find.text('pinned')).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.byType(AppBar)).dy),
    );
  });

  testWidgets('the library search field lives in the bar', (tester) async {
    // A phone with a status bar, because the bug is exactly the difference
    // between the status bar and the status bar plus the app bar.
    tester.view.padding = const FakeViewPadding(top: 44 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...defaultDisplayOverrides,
          exerciseListProvider.overrideWith((ref) => Stream.value(_exercises)),
        ],
        child: MaterialApp(
          theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
          home: const ExerciseLibraryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Part of the bar rather than the first thing in the body. That is what
    // stops it scrolling away on the one screen whose whole purpose is finding
    // something, and it means the scrim that fades in on scroll covers the
    // field too rather than leaving it floating over moving rows.
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(TextField),
      ),
      findsOneWidget,
    );
  });

  testWidgets('and so do the rows under it', (tester) async {
    // The same measurement one layer down: if the header is clear but the list
    // is not, the first row is the one that cannot be tapped.
    tester.view.padding = const FakeViewPadding(top: 44 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...defaultDisplayOverrides,
          exerciseListProvider.overrideWith((ref) => Stream.value(_exercises)),
        ],
        child: MaterialApp(
          theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
          home: const ExerciseLibraryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final barBottom = tester.getBottomLeft(find.byType(AppBar)).dy;

    expect(
      tester.getTopLeft(find.text('Barbell bench press')).dy,
      greaterThan(barBottom),
    );
  });
}
