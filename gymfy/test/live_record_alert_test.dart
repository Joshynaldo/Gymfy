// The live PR alert, end to end on the active workout screen: log a set
// through the sheet, and a set that beats your best is celebrated on the spot.
//
// The record maths is covered in live_records_test.dart; this pins down the
// wiring — that the check runs on a saved set, reads the bests *before* the set
// is written, stays quiet for an ordinary set, and clears itself.
//
// Providers are overridden rather than pointing at a real database; drift
// keeps a stream-cleanup timer alive that `pumpAndSettle` waits on forever.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/features/overload/data/overload_repository.dart';
import 'package:gymfy/features/settings/data/notification_preferences.dart';
import 'package:gymfy/features/workout/data/personal_records.dart';
import 'package:gymfy/features/workout/data/logging_preferences.dart';
import 'package:gymfy/features/workout/data/rest_timer_controller.dart';
import 'package:gymfy/features/workout/data/rest_timer_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/features/workout/screens/active_workout_screen.dart';
import 'package:gymfy/shared/database/app_database.dart' hide RestTimer;

import 'support/default_accent.dart';
import 'support/session_entries.dart';

const _sessionId = 1;
const _dayId = 10;

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
  dayId: _dayId,
  name: 'Push',
  startedAt: DateTime(2026, 9, 24, 18),
);

final _planned = PlannedExercise(
  entry: WorkoutExercise(
    id: 1,
    dayId: _dayId,
    exerciseId: _bench.id,
    position: 0,
    defaultSets: 3,
    defaultReps: 5,
    defaultRepsMax: null,
    warmupSets: 0,
  ),
  exercise: _bench,
);

/// Records logged sets instead of writing them.
class _RecordingSessions extends SessionRepository {
  _RecordingSessions(super.db);

  final logged = <({double weight, int reps, SetType type, double? rpe})>[];

  @override
  Future<void> logSet({
    required int sessionId,
    required String exerciseId,
    required int setNumber,
    required double weight,
    required int reps,
    SetType setType = SetType.normal,
    int? seconds,
    double? rpe,
    int? rir,
  }) async {
    logged.add((weight: weight, reps: reps, type: setType, rpe: rpe));
  }
}

/// Your best so far: 100 kg × 5. Counts how often it was asked, and whether
/// any set had been written yet when it was.
class _FixedBests extends PersonalRecordsRepository {
  _FixedBests(super.db, this.sessions);

  final _RecordingSessions sessions;
  final loggedWhenAsked = <int>[];

  @override
  Future<RecordBaseline> baselineFor(String exerciseId) async {
    loggedWhenAsked.add(sessions.logged.length);
    return RecordBaseline(
      weightKg: 100,
      oneRmKg: estimatedOneRmOf(weightKg: 100, reps: 5),
    );
  }
}

/// A rest timer that does nothing, so no notification plugin is touched.
class _SilentTimer extends RestTimer {
  @override
  RestTimerState? build() => null;

  @override
  Future<void> start({
    required String exerciseId,
    required String exerciseName,
    required int seconds,
  }) async {}
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<({_RecordingSessions sessions, _FixedBests bests})> pump(
    WidgetTester tester, {
    bool reduceMotion = false,
    Stream<EffortRatingMode> Function()? effort,
  }) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final sessions = _RecordingSessions(db);
    final bests = _FixedBests(db, sessions);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          defaultBodyFigureOverride,
          defaultAccentOverride,
          defaultWeightUnitOverride,
          warmupRampProvider.overrideWith(
            (ref) => Stream.value(defaultWarmupRamp),
          ),
          effortRatingModeProvider.overrideWith(
            (ref) => effort?.call() ?? Stream.value(EffortRatingMode.off),
          ),
          sessionRepositoryProvider.overrideWithValue(sessions),
          personalRecordsRepositoryProvider.overrideWithValue(bests),
          sessionProvider.overrideWith((ref, id) => Stream.value(_session)),
          sessionSetsProvider.overrideWith(
            (ref, id) => Stream.value(const <LoggedSet>[]),
          ),
          sessionExercisesProvider.overrideWith(
            (ref, id) => Stream.value(sessionEntriesFor([_planned])),
          ),
          overloadSuggestionProvider.overrideWith((ref, key) async => null),
          restTimerProvider.overrideWith(_SilentTimer.new),
          restForExerciseProvider.overrideWith((ref, id) => 90),
          restTimerAlertsProvider.overrideWith((ref) => Stream.value(false)),
        ],
        child: MaterialApp(
          theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          home: const ActiveWorkoutScreen(sessionId: _sessionId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (sessions: sessions, bests: bests);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.widgetWithText(Center, key).last);
    await tester.pump();
  }

  /// Logs [weight] × [reps] through the sheet, the way a user does.
  Future<void> logSet(WidgetTester tester, String weight, String reps) async {
    await tester.tap(find.text('Log set 1'));
    await tester.pumpAndSettle();
    // Empty readout: no prefill without history in this session.
    for (final key in weight.split('')) {
      await tapKey(tester, key);
    }
    await tester.tap(find.text('Next: reps'));
    await tester.pumpAndSettle();
    for (final key in reps.split('')) {
      await tapKey(tester, key);
    }
    await tester.tap(find.text('Save set'));
    // Not settled: the pane is on a five-second timer and settling would be
    // racing it. A few frames are enough for the save and the spring.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('a heavier set is celebrated as it is saved', (tester) async {
    final fakes = await pump(tester);

    await logSet(tester, '105', '5');

    expect(fakes.sessions.logged.single.weight, 105);
    expect(find.text('New personal record'), findsOneWidget);
    expect(find.textContaining('Heaviest weight'), findsOneWidget);

    // Gone on its own, so it never covers the next set.
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('New personal record'), findsNothing);
  });

  testWidgets('the bests are read before the set is written', (tester) async {
    final fakes = await pump(tester);

    await logSet(tester, '105', '5');

    // Asked once, with nothing logged yet — a set is never measured against
    // itself.
    expect(fakes.bests.loggedWhenAsked, [0]);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('an ordinary set is not', (tester) async {
    await pump(tester);

    await logSet(tester, '90', '5');

    expect(find.text('New personal record'), findsNothing);
  });

  testWidgets('still appears with reduced motion', (tester) async {
    await pump(tester, reduceMotion: true);

    await logSet(tester, '105', '5');

    expect(find.text('New personal record'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('a rating switched on is asked for on the very first set', (
    tester,
  ) async {
    // The setting arrives late, the way a settings row read from disk does.
    // Read cold off a plain provider it would answer "off" first, and the
    // first set of the session would go unrated.
    final fakes = await pump(
      tester,
      effort: () => Stream.fromFuture(
        Future.delayed(
          const Duration(milliseconds: 400),
          () => EffortRatingMode.rpe,
        ),
      ),
    );

    await tester.tap(find.text('Log set 1'));
    await tester.pumpAndSettle();
    await tapKey(tester, '9');
    await tapKey(tester, '0');
    await tester.tap(find.text('Next: reps'));
    await tester.pumpAndSettle();
    await tapKey(tester, '5');

    expect(find.text('HOW HARD · RPE'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('effort-9')));
    await tester.pump();
    await tester.tap(find.text('Save set'));
    await tester.pumpAndSettle();

    expect(fakes.sessions.logged.single.rpe, 9);
  });

  testWidgets('can be dismissed early', (tester) async {
    await pump(tester);

    await logSet(tester, '105', '5');
    await tester.tap(find.text('New personal record'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('New personal record'), findsNothing);
  });
}
