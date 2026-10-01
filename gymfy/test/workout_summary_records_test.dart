// The workout summary's personal records, and its top set.
//
// Providers are overridden rather than pointing at a real database; drift
// keeps a stream-cleanup timer alive that `pumpAndSettle` waits on forever.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
import 'package:gymfy/features/muscle_map/data/muscle_volume_repository.dart';
import 'package:gymfy/features/workout/data/personal_records.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/screens/workout_summary_screen.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

const _sessionId = 3;

final _bench = Exercise(
  id: 'barbell_bench_press',
  name: 'Barbell bench press',
  muscleIds: const ['chest'],
  isPlateLoaded: false,
  isCustom: false,
  isArchived: false,
  isTimed: false,
  equipment: 'other',
);

final _session = WorkoutSession(
  id: _sessionId,
  name: 'Push',
  startedAt: DateTime(2026, 9, 24, 18),
  completedAt: DateTime(2026, 9, 24, 19),
);

LoggedSet _set(int id, double weight, SetType type) => LoggedSet(
  id: id,
  sessionId: _sessionId,
  exerciseId: _bench.id,
  setNumber: id,
  weight: weight,
  reps: 5,
  setType: type.name,
);

Future<void> _pump(
  WidgetTester tester, {
  required List<LoggedSet> sets,
  List<ExerciseRecords> records = const [],
}) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...defaultDisplayOverrides,
        sessionProvider.overrideWith((ref, id) => Stream.value(_session)),
        sessionSetsProvider.overrideWith((ref, id) => Stream.value(sets)),
        allExercisesProvider.overrideWith((ref) => Stream.value([_bench])),
        sessionMuscleIntensitiesProvider.overrideWith(
          (ref, id) => Stream.value(const <String, double>{}),
        ),
        sessionRecordsProvider.overrideWith((ref, id) async => records),
      ],
      child: MaterialApp(
        theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
        home: const WorkoutSummaryScreen(sessionId: _sessionId),
      ),
    ),
  );
  // Pumped rather than settled: the muscle map below keeps frames coming,
  // and the numbers counting up need only a moment.
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  testWidgets('lists the records the session set', (tester) async {
    await _pump(
      tester,
      sets: [_set(1, 105, SetType.normal)],
      records: const [
        ExerciseRecords(
          exerciseId: 'barbell_bench_press',
          records: [
            BrokenRecord(kind: RecordKind.weight, value: 105, previous: 100),
          ],
        ),
      ],
    );

    expect(find.text('1 personal record'), findsOneWidget);
    expect(find.text('Heaviest weight · 105 kg, was 100 kg'), findsOneWidget);
  });

  testWidgets('says nothing about records when there are none', (tester) async {
    await _pump(tester, sets: [_set(1, 100, SetType.normal)]);

    expect(find.textContaining('personal record'), findsNothing);
  });

  testWidgets('the top set is a working set, not a heavier drop', (
    tester,
  ) async {
    // A mis-weighted drop set (or a warm-up) must not stand in as the top set
    // — the same strength filter as everywhere else.
    await _pump(
      tester,
      sets: [
        _set(1, 140, SetType.warmup),
        _set(2, 100, SetType.normal),
        _set(3, 120, SetType.drop),
      ],
    );

    expect(find.textContaining('Top set 100 kg'), findsOneWidget);
  });
}
