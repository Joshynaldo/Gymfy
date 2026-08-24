// The Muscles tab's two readings: volume and fatigue share one body diagram,
// and switching between them changes the data *and* what the caption claims
// brightness means.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/muscle_map/data/muscle_fatigue_repository.dart';
import 'package:gymfy/features/muscle_map/data/muscle_volume_repository.dart';
import 'package:gymfy/features/muscle_map/screens/muscle_map_screen.dart';

import 'support/default_accent.dart';

Future<void> _pump(
  WidgetTester tester, {
  Map<String, double> volume = const {'chest': 1.0},
  Map<String, double> fatigue = const {'chest': 0.5},
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        defaultAccentOverride,
        weeklyMuscleIntensitiesProvider.overrideWith(
          (ref) => Stream.value(volume),
        ),
        muscleFatigueProvider.overrideWith((ref) => Stream.value(fatigue)),
      ],
      child: const MaterialApp(home: MuscleMapScreen()),
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

    expect(find.text('Muscle map'), findsOneWidget);
    expect(find.textContaining('Training volume over the last 7 days'),
        findsOneWidget);
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

    expect(find.textContaining('Training volume over the last 7 days'),
        findsOneWidget);
    expect(find.text('Muscle map'), findsOneWidget);
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
