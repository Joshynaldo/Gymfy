// A percentage-of-1RM target and a training-block deload, as they read on the
// workout screen: the line on the exercise card, the weight the log sheet opens
// on, and the note in the sheet saying where that weight came from.

import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/features/overload/data/overload_math.dart';
import 'package:gymfy/features/overload/data/overload_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/features/workout/screens/active_workout_screen.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';
import 'support/session_entries.dart';

const _sessionId = 1;
const _dayId = 10;

final _session = WorkoutSession(
  id: _sessionId,
  dayId: _dayId,
  name: 'Squat',
  startedAt: DateTime(2026, 9, 19, 18),
);

final _squat = Exercise(
  id: 'barbell_back_squat',
  name: 'Barbell back squat',
  muscleIds: const ['quads'],
  isPlateLoaded: false,
  isCustom: false,
  isArchived: false,
  isTimed: false,
  equipment: 'other',
);

final _planned = PlannedExercise(
  entry: WorkoutExercise(
    id: 1,
    dayId: _dayId,
    exerciseId: _squat.id,
    position: 0,
    defaultSets: 5,
    defaultReps: 5,
    warmupSets: 0,
    targetPercent: 75,
  ),
  exercise: _squat,
);

Future<void> _pump(WidgetTester tester, OverloadSuggestion suggestion) async {
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...defaultDisplayOverrides,
        sessionProvider.overrideWith((ref, id) => Stream.value(_session)),
        sessionSetsProvider.overrideWith(
          (ref, id) => Stream.value(const <LoggedSet>[]),
        ),
        sessionExercisesProvider.overrideWith(
          (ref, id) => Stream.value(sessionEntriesFor([_planned])),
        ),
        overloadSuggestionProvider.overrideWith((ref, key) async => suggestion),
      ],
      child: MaterialApp(
        theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
        home: const ActiveWorkoutScreen(sessionId: _sessionId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a percentage target names the percentage and the weight', (
    tester,
  ) async {
    await _pump(
      tester,
      const OverloadSuggestion(
        weight: 82.5,
        reason: OverloadReason.percentOfMax,
        targetPercent: 75,
      ),
    );

    expect(find.text('75% of your 1RM — 82.5 kg'), findsOneWidget);

    await tester.tap(find.text('Log set 1'));
    await tester.pumpAndSettle();

    // The sheet opens on the worked-out weight, and says why.
    expect(find.text('82.5'), findsOneWidget);
    expect(find.textContaining('Planned at 75% of your 1RM'), findsOneWidget);
  });

  testWidgets('a deload week says it is one, and how light', (tester) async {
    await _pump(
      tester,
      const OverloadSuggestion(
        weight: 60,
        reason: OverloadReason.blockDeload,
        deloadPercent: 60,
      ),
    );

    expect(find.text('Deload week at 60% — 60 kg'), findsOneWidget);

    await tester.tap(find.text('Log set 1'));
    await tester.pumpAndSettle();

    expect(find.text('60'), findsOneWidget);
    expect(find.textContaining('Deload week: 60%'), findsOneWidget);
  });
}
