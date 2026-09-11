// The warm-up feature as it appears on screen: the two log buttons in the
// active workout, how warm-up rows are marked and re-tagged, and planning a
// count in the day builder.
//
// Providers are overridden rather than pointing the screens at a real database:
// drift keeps a stream-cleanup timer alive, which `pumpAndSettle` waits on
// forever. See the note in `support/default_accent.dart` — the repository logic
// is covered against a real database in `warmup_sets_test.dart` instead.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/overload/data/overload_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/features/workout/screens/active_workout_screen.dart';
import 'package:gymfy/features/workout/screens/day_builder_screen.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

const _sessionId = 1;
const _dayId = 10;

final _bench = Exercise(
  id: 'barbell_bench_press',
  name: 'Barbell Bench Press',
  muscleIds: const ['chest'],
  isPlateLoaded: false,
  isCustom: false,
  isArchived: false,
);

final _session = WorkoutSession(
  id: _sessionId,
  dayId: _dayId,
  name: 'Push',
  startedAt: DateTime(2026, 8, 24, 18),
);

final _day = WorkoutDay(id: _dayId, splitId: 1, name: 'Push', position: 0);

WorkoutExercise _entry({int warmupSets = 0}) => WorkoutExercise(
  id: 1,
  dayId: _dayId,
  exerciseId: _bench.id,
  position: 0,
  defaultSets: 3,
  defaultReps: 5,
  defaultRepsMax: null,
  warmupSets: warmupSets,
);

LoggedSet _set({
  required int id,
  required int setNumber,
  required double weight,
  bool isWarmup = false,
}) => LoggedSet(
  id: id,
  sessionId: _sessionId,
  exerciseId: _bench.id,
  setNumber: setNumber,
  weight: weight,
  reps: 5,
  isWarmup: isWarmup,
);

/// Records the re-tag call instead of writing it, so the tap can be asserted on
/// without a live database behind the screen.
class _RecordingSessionRepository extends SessionRepository {
  _RecordingSessionRepository(super.db);

  ({int id, bool isWarmup})? lastSetWarmup;

  @override
  Future<void> setWarmup({required int id, required bool isWarmup}) async {
    lastSetWarmup = (id: id, isWarmup: isWarmup);
  }
}

/// Same idea for the day builder's save.
class _RecordingWorkoutRepository extends WorkoutRepository {
  _RecordingWorkoutRepository(super.db);

  int? lastWarmupSets;

  @override
  Future<void> updatePlannedExercise(
    int id, {
    required int sets,
    required int reps,
    int? repsMax,
    int warmupSets = 0,
  }) async {
    lastWarmupSets = warmupSets;
  }
}

void main() {
  // Never queried — the repositories just need something to hold. Providers
  // above them are all overridden, so no statement ever reaches it.
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('active workout', () {
    Future<_RecordingSessionRepository> pumpWorkout(
      WidgetTester tester, {
      List<LoggedSet> sets = const [],
      int warmupSets = 0,
    }) async {
      final repository = _RecordingSessionRepository(db);
      final entry = _entry(warmupSets: warmupSets);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...defaultDisplayOverrides,
            sessionRepositoryProvider.overrideWithValue(repository),
            sessionProvider.overrideWith((ref, id) => Stream.value(_session)),
            sessionSetsProvider.overrideWith((ref, id) => Stream.value(sets)),
            dayExercisesProvider.overrideWith(
              (ref, dayId) => Stream.value([
                PlannedExercise(entry: entry, exercise: _bench),
              ]),
            ),
            // No history, so no suggestion — this test is about the phases.
            overloadSuggestionProvider.overrideWith((ref, key) async => null),
          ],
          child: const MaterialApp(
            home: ActiveWorkoutScreen(sessionId: _sessionId),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return repository;
    }

    testWidgets('both phases can be logged from the card', (tester) async {
      // The working-set button counts rather than saying "Add set": the number
      // it shows is the one about to be logged, so the card answers "which set
      // am I on" without the rows above being counted.
      await pumpWorkout(tester);

      expect(find.text('Warm-up'), findsOneWidget);
      expect(find.text('Log set 1'), findsOneWidget);
    });

    testWidgets('a planned count counts the warm-ups down', (tester) async {
      await pumpWorkout(tester, warmupSets: 3);

      expect(find.text('Warm-up 1 of 3'), findsOneWidget);
    });

    testWidgets('the countdown advances as warm-ups are logged', (
      tester,
    ) async {
      await pumpWorkout(
        tester,
        warmupSets: 3,
        sets: [_set(id: 1, setNumber: 1, weight: 40, isWarmup: true)],
      );

      expect(find.text('Warm-up 2 of 3'), findsOneWidget);
    });

    testWidgets('the countdown stops once the plan is met', (tester) async {
      await pumpWorkout(
        tester,
        warmupSets: 1,
        sets: [_set(id: 1, setNumber: 1, weight: 40, isWarmup: true)],
      );

      // Still offered — some days need a fourth — but no longer counting.
      expect(find.text('Warm-up'), findsOneWidget);
      expect(find.textContaining('of 1'), findsNothing);
    });

    testWidgets('warm-up rows are badged, working rows are not', (
      tester,
    ) async {
      await pumpWorkout(
        tester,
        sets: [
          _set(id: 1, setNumber: 1, weight: 40, isWarmup: true),
          _set(id: 2, setNumber: 1, weight: 100),
        ],
      );

      expect(find.text('W'), findsOneWidget);
      // Both rows are there — a warm-up is kept out of the numbers, never out
      // of the session you are standing in.
      expect(find.textContaining('40'), findsOneWidget);
      expect(find.textContaining('100'), findsOneWidget);
    });

    testWidgets('both phases number from one', (tester) async {
      await pumpWorkout(
        tester,
        sets: [
          _set(id: 1, setNumber: 1, weight: 40, isWarmup: true),
          _set(id: 2, setNumber: 2, weight: 60, isWarmup: true),
          _set(id: 3, setNumber: 1, weight: 100),
        ],
      );

      // Two rows numbered "1" is correct here: one warm-up, one working.
      // "Set 3 of 3" for your first real set would be the wrong story.
      expect(find.text('1'), findsNWidgets(2));
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('a warm-up row offers to become a working set', (tester) async {
      final repository = await pumpWorkout(
        tester,
        sets: [_set(id: 7, setNumber: 1, weight: 80, isWarmup: true)],
      );

      await tester.tap(find.byTooltip('Make this a working set'));
      await tester.pumpAndSettle();

      expect(repository.lastSetWarmup, (id: 7, isWarmup: false));
    });

    testWidgets('a working row offers to become a warm-up', (tester) async {
      final repository = await pumpWorkout(
        tester,
        sets: [_set(id: 8, setNumber: 1, weight: 80)],
      );

      await tester.tap(find.byTooltip('Make this a warm-up'));
      await tester.pumpAndSettle();

      expect(repository.lastSetWarmup, (id: 8, isWarmup: true));
    });
  });

  group('day builder', () {
    Future<_RecordingWorkoutRepository> pumpBuilder(
      WidgetTester tester, {
      int warmupSets = 0,
    }) async {
      final repository = _RecordingWorkoutRepository(db);
      final entry = _entry(warmupSets: warmupSets);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...defaultDisplayOverrides,
            workoutRepositoryProvider.overrideWithValue(repository),
            dayProvider.overrideWith((ref, id) => Stream.value(_day)),
            dayExercisesProvider.overrideWith(
              (ref, dayId) => Stream.value([
                PlannedExercise(entry: entry, exercise: _bench),
              ]),
            ),
          ],
          child: const MaterialApp(home: DayBuilderScreen(dayId: _dayId)),
        ),
      );
      await tester.pumpAndSettle();
      return repository;
    }

    testWidgets('warm-ups are not mentioned when there are none', (
      tester,
    ) async {
      await pumpBuilder(tester);

      // "0 warm-ups" on every cable curl would be noise on the row it least
      // belongs to.
      expect(find.textContaining('warm-up'), findsNothing);
    });

    testWidgets('a planned count is shown on the row', (tester) async {
      await pumpBuilder(tester, warmupSets: 2);

      expect(find.textContaining('2 warm-ups'), findsOneWidget);
    });

    testWidgets('one warm-up is not "1 warm-ups"', (tester) async {
      await pumpBuilder(tester, warmupSets: 1);

      expect(find.textContaining('1 warm-up'), findsOneWidget);
      expect(find.textContaining('warm-ups'), findsNothing);
    });

    testWidgets('a count can be picked and saved', (tester) async {
      final repository = await pumpBuilder(tester);

      await tester.tap(find.text('Barbell Bench Press'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '3'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repository.lastWarmupSets, 3);
    });

    testWidgets('zero is a real choice, not just the absence of one', (
      tester,
    ) async {
      final repository = await pumpBuilder(tester, warmupSets: 3);

      await tester.tap(find.text('Barbell Bench Press'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '0'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repository.lastWarmupSets, 0);
    });

    testWidgets('an unchanged exercise keeps the count it had', (tester) async {
      final repository = await pumpBuilder(tester, warmupSets: 2);

      await tester.tap(find.text('Barbell Bench Press'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // The dialog opens on the stored value, so saving without touching the
      // chips must not quietly reset it to zero.
      expect(repository.lastWarmupSets, 2);
    });
  });
}
