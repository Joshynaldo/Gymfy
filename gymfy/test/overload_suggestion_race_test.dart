// The earned increase has to survive being asked for early.
//
// The bug this pins down: the log sheet took its suggestion from
// `ref.read(overloadSuggestionProvider(...)).value` — the value resolved *so
// far*. That provider is a database query, so for the first frames after an
// exercise becomes the current one it has no value yet, and "not resolved yet"
// came back looking exactly like "no suggestion".
//
// The window is small, and it is precisely the one a user is in: tap an
// exercise under Up next, tap Log set. The query for that exercise started a
// frame ago. When it lost the race the sheet opened empty, with no note and no
// prefilled weight — so the increase you earned last week simply never showed
// up, on some sets and not others.
//
// The delay here stands in for that query. The point is not the number of
// milliseconds; it is that the screen must not answer before the answer
// exists.

import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/features/overload/data/overload_math.dart';
import 'package:gymfy/features/overload/data/overload_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/features/workout/screens/active_workout_screen.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

const _sessionId = 1;
const _dayId = 10;

final _session = WorkoutSession(
  id: _sessionId,
  dayId: _dayId,
  name: 'Legs',
  startedAt: DateTime(2026, 9, 19, 18),
);

final _squat = Exercise(
  id: 'barbell_back_squat',
  name: 'Barbell back squat',
  muscleIds: const ['quads'],
  isPlateLoaded: false,
  isCustom: false,
  isArchived: false,
);

final _planned = PlannedExercise(
  entry: WorkoutExercise(
    id: 1,
    dayId: _dayId,
    exerciseId: _squat.id,
    position: 0,
    defaultSets: 3,
    defaultReps: 8,
    defaultRepsMax: null,
    warmupSets: 0,
  ),
  exercise: _squat,
);

/// What last week earned: three sets at the target, so the bar goes up.
const _earned = OverloadSuggestion(
  weight: 62.5,
  reason: OverloadReason.earned,
);

void main() {
  /// Mounts the active workout screen with a suggestion that takes [delay] to
  /// arrive, the way a real database read does.
  Future<void> pump(WidgetTester tester, {required Duration delay}) async {
    // A phone. The sheet is a header, a readout, twelve keys and two buttons;
    // on the binding's default 800x600 the buttons fall off the bottom edge
    // and every tap silently misses.
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
          dayExercisesProvider.overrideWith(
            (ref, dayId) => Stream.value([_planned]),
          ),
          overloadSuggestionProvider.overrideWith((ref, key) async {
            await Future<void>.delayed(delay);
            return _earned;
          }),
        ],
        child: MaterialApp(
          theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
          home: const ActiveWorkoutScreen(sessionId: _sessionId),
        ),
      ),
    );
  }

  testWidgets('the sheet waits for a suggestion still in flight', (
    tester,
  ) async {
    await pump(tester, delay: const Duration(milliseconds: 400));

    // Deliberately NOT pumpAndSettle: settling would resolve the suggestion
    // first and test the easy case. These pumps build the screen without
    // advancing the clock far enough for the query to land — the state the
    // user is in when they tap straight through.
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Log set 1'));
    await tester.pumpAndSettle();

    expect(
      find.text('62.5'),
      findsOneWidget,
      reason: 'the earned weight should be on the readout, ready to save',
    );
    expect(
      find.textContaining('going up to'),
      findsWidgets,
      reason: 'and the reason for it should be stated',
    );
  });

  testWidgets('a suggestion already resolved still arrives', (tester) async {
    // The guard on the guard. If the await were wired to something that never
    // completes, the test above could only be made to pass by breaking this
    // one — the ordinary case, where the query finished long before the tap.
    await pump(tester, delay: Duration.zero);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log set 1'));
    await tester.pumpAndSettle();

    expect(find.text('62.5'), findsOneWidget);
  });
}
