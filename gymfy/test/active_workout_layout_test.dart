// The shape of the active workout screen: one exercise is the card, the rest
// are rows.
//
// Worth pinning down because the failure mode is not a crash — it is five
// equally loud cards, which is what this replaced and which looked perfectly
// fine on a screen with one exercise in the plan.
//
// Providers are overridden rather than pointing at a real database; drift keeps
// a stream-cleanup timer alive that `pumpAndSettle` waits on forever.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/features/overload/data/overload_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/features/workout/screens/active_workout_screen.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/widgets/app_card.dart';

import 'support/default_accent.dart';

const _sessionId = 1;
const _dayId = 10;

final _session = WorkoutSession(
  id: _sessionId,
  dayId: _dayId,
  name: 'Push',
  startedAt: DateTime(2026, 9, 11, 18),
);

Exercise _exercise(String id, String name) => Exercise(
  id: id,
  name: name,
  muscleIds: const ['chest'],
  isPlateLoaded: false,
  isCustom: false,
  isArchived: false,
);

final _bench = _exercise('barbell_bench_press', 'Barbell bench press');
final _incline = _exercise('incline_press', 'Incline dumbbell press');
final _fly = _exercise('cable_fly', 'Cable fly');

PlannedExercise _planned(Exercise exercise, int position, {int sets = 3}) =>
    PlannedExercise(
      entry: WorkoutExercise(
        id: position + 1,
        dayId: _dayId,
        exerciseId: exercise.id,
        position: position,
        defaultSets: sets,
        defaultReps: 8,
        defaultRepsMax: null,
        warmupSets: 0,
      ),
      exercise: exercise,
    );

LoggedSet _set(Exercise exercise, int number) => LoggedSet(
  id: exercise.id.hashCode + number,
  sessionId: _sessionId,
  exerciseId: exercise.id,
  setNumber: number,
  weight: 100,
  reps: 8,
  isWarmup: false,
);

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, {List<LoggedSet> sets = const []}) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...defaultDisplayOverrides,
          sessionRepositoryProvider.overrideWithValue(SessionRepository(db)),
          sessionProvider.overrideWith((ref, id) => Stream.value(_session)),
          sessionSetsProvider.overrideWith((ref, id) => Stream.value(sets)),
          dayExercisesProvider.overrideWith(
            (ref, dayId) => Stream.value([
              _planned(_bench, 0),
              _planned(_incline, 1),
              _planned(_fly, 2),
            ]),
          ),
          overloadSuggestionProvider.overrideWith((ref, key) async => null),
        ],
        child: MaterialApp(
          theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
          home: const ActiveWorkoutScreen(sessionId: _sessionId),
        ),
      ),
    );
  }

  testWidgets('one exercise is the card, the rest are rows', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();

    // The card is the only surface with a log button on it.
    expect(find.text('Log set 1'), findsOneWidget);
    expect(find.text('UP NEXT'), findsOneWidget);
    expect(find.text('Incline dumbbell press'), findsOneWidget);
    expect(find.text('Cable fly'), findsOneWidget);
  });

  testWidgets('the card is the first exercise still short of its sets', (
    tester,
  ) async {
    // Working down the plan in order is what nearly every session is, so the
    // screen should already be on the right exercise without being told.
    await pump(
      tester,
      sets: [_set(_bench, 1), _set(_bench, 2), _set(_bench, 3)],
    );
    await tester.pumpAndSettle();

    // Bench is done — three of three — so the card has moved on, and its
    // button counts from one again.
    expect(find.text('Log set 1'), findsOneWidget);
    expect(find.text('Barbell bench press'), findsOneWidget);

    final rows = find.byType(AppCard);
    expect(rows, findsWidgets, reason: 'the others are rows under Up next');
  });

  testWidgets('tapping a row moves the card to it', (tester) async {
    // The bench is busy, so you do the flys now. Without this the screen
    // insists on an order the gym does not care about.
    await pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cable fly'));
    await tester.pumpAndSettle();

    // Cable fly now carries the button, and the bench has become a row.
    expect(
      find.descendant(
        of: find.byType(AppPanel),
        matching: find.text('Cable fly'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AppPanel),
        matching: find.text('Barbell bench press'),
      ),
      findsNothing,
    );
  });

  testWidgets('the log button counts the set you are about to do', (
    tester,
  ) async {
    await pump(tester, sets: [_set(_bench, 1)]);
    await tester.pumpAndSettle();

    expect(find.text('Log set 2'), findsOneWidget);
  });
}
