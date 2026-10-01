// The warm-up calculator from the active workout: it opens on today's working
// weight, reads the plate inventory you saved, and logs what you pick as
// warm-ups, numbered in the ramp-up phase.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/features/overload/data/overload_repository.dart';
import 'package:gymfy/features/plates/data/plate_math.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/features/workout/screens/active_workout_screen.dart';
import 'package:gymfy/shared/data/settings_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

const _sessionId = 1;
const _dayId = 10;

final _squat = Exercise(
  id: 'barbell_back_squat',
  name: 'Barbell back squat',
  muscleIds: const ['quads'],
  isPlateLoaded: true,
  isCustom: false,
  isArchived: false,
  isTimed: false,
  equipment: 'barbell',
);

final _session = WorkoutSession(
  id: _sessionId,
  dayId: _dayId,
  name: 'Legs',
  startedAt: DateTime(2026, 9, 24, 18),
);

final _planned = PlannedExercise(
  entry: WorkoutExercise(
    id: 1,
    dayId: _dayId,
    exerciseId: _squat.id,
    position: 0,
    defaultSets: 3,
    defaultReps: 5,
    defaultRepsMax: null,
    warmupSets: 0,
  ),
  exercise: _squat,
);

/// Records logged sets instead of writing them.
class _RecordingSessions extends SessionRepository {
  _RecordingSessions(super.db);

  final logged = <({int setNumber, double weight, int reps, SetType type})>[];

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
    logged.add((
      setNumber: setNumber,
      weight: weight,
      reps: reps,
      type: setType,
    ));
  }
}

/// Settings served from a map, arriving a moment late the way a database row
/// does — so a read that does not wait for them gets the defaults instead.
///
/// Not the real repository over an in-memory database: drift's stream cleanup
/// timer outlives the widget tree and fails the test after it passed.
class _FakeSettings extends SettingsRepository {
  _FakeSettings(super.db, this.values);

  final Map<String, String> values;

  @override
  Stream<String?> watchRaw(String name) => Stream.fromFuture(
    Future.delayed(const Duration(milliseconds: 50), () => values[name]),
  );
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  testWidgets('opens on today’s weight and logs the ramp as warm-ups', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // A gym without 5s or 2.5s, saved before the workout. The calculator must
    // load with *these* plates even though nothing on the screen watched them.
    final settings = _FakeSettings(db, {
      platesKgSetting: encodePlates(const [25, 20, 10]),
    });

    final sessions = _RecordingSessions(db);
    final today = [
      // One working set already done today, plus a warm-up before it.
      LoggedSet(
        id: 1,
        sessionId: _sessionId,
        exerciseId: _squat.id,
        setNumber: 1,
        weight: 40,
        reps: 5,
        setType: SetType.warmup.name,
      ),
      LoggedSet(
        id: 2,
        sessionId: _sessionId,
        exerciseId: _squat.id,
        setNumber: 1,
        weight: 100,
        reps: 5,
        setType: SetType.normal.name,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...defaultDisplayOverrides,
          settingsRepositoryProvider.overrideWithValue(settings),
          sessionRepositoryProvider.overrideWithValue(sessions),
          sessionProvider.overrideWith((ref, id) => Stream.value(_session)),
          sessionSetsProvider.overrideWith((ref, id) => Stream.value(today)),
          dayExercisesProvider.overrideWith(
            (ref, dayId) => Stream.value([_planned]),
          ),
          overloadSuggestionProvider.overrideWith((ref, key) async => null),
        ],
        child: MaterialApp(
          theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
          home: const ActiveWorkoutScreen(sessionId: _sessionId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Warm-up calculator'));
    await tester.pumpAndSettle();

    expect(find.text('Warm-up calculator'), findsWidgets);
    // 80 % of 100 with no 5s: 25 a side, 70 kg — the saved inventory, not the
    // default one (which would make 80 exactly).
    expect(find.text('70 kg × 2'), findsOneWidget);
    expect(find.text('80 kg × 2'), findsNothing);

    await tester.tap(find.text('Log 4 warm-up sets'));
    await tester.pumpAndSettle();

    expect(sessions.logged.map((s) => s.type).toSet(), {SetType.warmup});
    expect(sessions.logged.map((s) => s.weight), [20, 40, 60, 70]);
    // Numbered on from the warm-up already logged.
    expect(sessions.logged.map((s) => s.setNumber), [2, 3, 4, 5]);
  });
}
