// The Stats tab's muscle map: volume and fatigue share one body diagram, and
// switching between them changes the data *and* what the caption claims
// brightness means.
//
// The rank and all-time sections above and below the map are covered in
// `stats_rank_test.dart`; here they are stubbed empty so a caption test isn't
// also a test of six other providers.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/calculator/data/ranked_lifts.dart';
import 'package:gymfy/features/home/data/activity_repository.dart';
import 'package:gymfy/features/home/data/recap.dart';
import 'package:gymfy/features/home/data/recap_repository.dart';
import 'package:gymfy/features/muscle_map/data/muscle_colors.dart';
import 'package:gymfy/features/muscle_map/data/muscle_fatigue_repository.dart';
import 'package:gymfy/features/muscle_map/data/muscle_volume_repository.dart';
import 'package:gymfy/features/muscle_map/widgets/muscle_map_view.dart';
import 'package:gymfy/features/progress/data/measurements_repository.dart';
import 'package:gymfy/features/stats/widgets/stats_sections.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

/// Everything on this screen that would otherwise open a database.
///
/// Not laziness: a real database keeps drift's stream-cleanup timer alive, and
/// the test binding fails a test that ends with a timer pending — so a screen
/// this well connected has to be stubbed at its leaves or nothing here passes.
final _quietData = [
  measurementHistoryProvider.overrideWith(
    (ref) => Stream.value(const <BodyMeasurement>[]),
  ),
  recapSetsProvider.overrideWith((ref) => Stream.value(const <RecapSet>[])),
  activityMinutesProvider.overrideWith(
    (ref) => Stream.value(const <DateTime, int>{}),
  ),
  workoutStreakProvider.overrideWith((ref) => Stream.value(0)),
  // Ranking one lift reaches its logged history and its tested max, so this is
  // overridden whole rather than at each of its several leaves.
  rankedLiftsProvider.overrideWithValue((
    ranked: const <RankedLift>[],
    unlogged: const <String>[],
  )),
];

Future<void> _pump(
  WidgetTester tester, {
  Map<String, double> volume = const {'chest': 1.0},
  Map<String, double> fatigue = const {'chest': 0.5},
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...defaultDisplayOverrides,
        ..._quietData,
        weeklyMuscleIntensitiesProvider.overrideWith(
          (ref) => Stream.value(volume),
        ),
        muscleFatigueProvider.overrideWith((ref) => Stream.value(fatigue)),
      ],
      child: const MaterialApp(home: Scaffold(body: BodyMapSection())),
    ),
  );
  // Plain pumps, not pumpAndSettle: the body SVG is a real asset load that the
  // fake clock never advances, so settling would wait forever. The captions and
  // toggles under test render without it.
  await tester.pump();
  await tester.pump();
}

Future<void> _switchToFatigue(WidgetTester tester) async {
  await tester.tap(find.text('Fatigue'));
  // Twice: one frame applies the selection, the next picks up the first value
  // from the fatigue stream it just started watching.
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('opens on volume', (tester) async {
    await _pump(tester);

    // No "Muscle map" heading any more: the section is what the Body segment
    // of Progress shows, and the segment control above it is the heading. A
    // title repeating the tab you are already on is a line of nothing.
    expect(find.text('Volume'), findsOneWidget);
    expect(find.text('Fatigue'), findsOneWidget);
    expect(
      find.textContaining('Training volume over the last 7 days'),
      findsOneWidget,
    );
  });

  testWidgets('switching to fatigue retitles and recaptions', (tester) async {
    await _pump(tester);
    await _switchToFatigue(tester);

    expect(find.text('Fatigue'), findsWidgets);
    // Brightness means something different here, so saying "volume" would be
    // actively wrong.
    expect(find.textContaining('Brighter = less recovered'), findsOneWidget);
    expect(find.textContaining('Training volume'), findsNothing);
  });

  testWidgets('an empty fatigue map says you are recovered, not untrained', (
    tester,
  ) async {
    await _pump(tester, fatigue: const {});
    await _switchToFatigue(tester);

    // "No training logged" would be the wrong story: you may have trained hard
    // last week and simply be ready again.
    expect(find.textContaining('Everything is recovered'), findsOneWidget);
    expect(find.textContaining('No training logged'), findsNothing);
  });

  testWidgets('an empty volume map asks for a workout', (tester) async {
    await _pump(tester, volume: const {});

    expect(find.textContaining('No training logged'), findsOneWidget);
  });

  testWidgets('switching back to volume restores its caption', (tester) async {
    await _pump(tester);
    await _switchToFatigue(tester);

    await tester.tap(find.text('Volume'));
    await tester.pump();
    await tester.pump();

    expect(
      find.textContaining('Training volume over the last 7 days'),
      findsOneWidget,
    );
  });

  testWidgets('fatigue is red and volume follows the accent', (tester) async {
    // The two readings share one diagram, so colour is what tells them apart
    // at a glance. In the accent they were the same picture twice.
    await _pump(tester);
    expect(
      tester.widget<MuscleMapView>(find.byType(MuscleMapView)).heatColor,
      isNull,
      reason: 'volume should keep following the chosen accent',
    );

    await _switchToFatigue(tester);
    expect(
      tester.widget<MuscleMapView>(find.byType(MuscleMapView)).heatColor,
      fatigueColor,
    );
  });

  testWidgets('the front/back toggle still works in fatigue mode', (
    tester,
  ) async {
    await _pump(tester);
    await _switchToFatigue(tester);

    expect(find.text('Front'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pump();

    // Still on fatigue — flipping the body must not silently reset the reading.
    expect(find.textContaining('Brighter = less recovered'), findsOneWidget);
  });
}
