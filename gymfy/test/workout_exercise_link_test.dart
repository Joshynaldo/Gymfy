// Tapping an exercise while training opens the same detail screen the library
// does — the animation, the muscles worked, the rank.
//
// The interesting part is *how* it opens. `context.go('/exercises/<id>')`
// would switch to the Exercises tab and strand you there mid-workout, so this
// pushes instead. That distinction is invisible on screen and easy to undo by
// accident, which is what this pins down.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
import 'package:gymfy/features/exercises/screens/exercise_detail_screen.dart';
import 'package:gymfy/features/overload/data/overload_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/features/workout/screens/active_workout_screen.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

const _sessionId = 1;
const _dayId = 10;

final _bench = Exercise(
  id: 'barbell_bench_press',
  name: 'Barbell Bench Press',
  muscleIds: const ['chest', 'triceps'],
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

final _entry = WorkoutExercise(
  id: 1,
  dayId: _dayId,
  exerciseId: 'barbell_bench_press',
  position: 0,
  defaultSets: 3,
  defaultReps: 5,
  defaultRepsMax: null,
  warmupSets: 0,
);

void main() {
  /// Records what gets pushed, so the test can tell a push from a tab switch.
  final pushed = <Route<dynamic>>[];

  Future<void> pumpWorkout(WidgetTester tester) async {
    pushed.clear();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...defaultDisplayOverrides,
          sessionProvider.overrideWith((ref, id) => Stream.value(_session)),
          sessionSetsProvider.overrideWith(
            (ref, id) => Stream.value(const <LoggedSet>[]),
          ),
          dayExercisesProvider.overrideWith(
            (ref, dayId) => Stream.value([
              PlannedExercise(entry: _entry, exercise: _bench),
            ]),
          ),
          overloadSuggestionProvider.overrideWith((ref, key) async => null),
          // The detail screen looks the exercise up live.
          exerciseProvider.overrideWith((ref, id) => Stream.value(_bench)),
        ],
        child: MaterialApp(
          home: const ActiveWorkoutScreen(sessionId: _sessionId),
          navigatorObservers: [_Observer(pushed)],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping an exercise opens its detail screen', (tester) async {
    await pumpWorkout(tester);

    await tester.tap(find.text('Barbell Bench Press'));
    // Single pumps rather than settling: the detail screen's own async pieces
    // (the rank badge, the rest preference) read the database, and this test
    // is about the navigation, not about them.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ExerciseDetailScreen), findsOneWidget);
  });

  testWidgets('it is pushed, so the workout is still underneath', (
    tester,
  ) async {
    await pumpWorkout(tester);

    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // A push keeps the session on the stack to come back to. Routing to the
    // Exercises tab instead would leave the user to find their way back to a
    // workout they are halfway through.
    expect(pushed, hasLength(1));
    expect(pushed.single, isA<MaterialPageRoute<void>>());
  });
}

/// Collects pushed routes.
class _Observer extends NavigatorObserver {
  _Observer(this.pushed);

  final List<Route<dynamic>> pushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previous) {
    // The home route arrives with no previous; only later pushes are ours.
    if (previous != null) pushed.add(route);
  }
}
