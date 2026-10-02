// The active workout's running order: supersets, free workouts, and adding,
// swapping, reordering and removing exercises mid-session.
//
// The repository side of each edit is in session_order_test.dart; this pins
// down the screen — what it shows, and which edit each control asks for.
//
// Providers are overridden rather than pointing at a real database; drift
// keeps a stream-cleanup timer alive that `pumpAndSettle` waits on forever.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
import 'package:gymfy/features/overload/data/overload_repository.dart';
import 'package:gymfy/features/settings/data/notification_preferences.dart';
import 'package:gymfy/features/workout/data/personal_records.dart';
import 'package:gymfy/features/workout/data/rest_timer_controller.dart';
import 'package:gymfy/features/workout/data/rest_timer_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/features/workout/screens/active_workout_screen.dart';
import 'package:gymfy/shared/database/app_database.dart' hide RestTimer;
import 'package:gymfy/shared/widgets/app_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/default_accent.dart';

const _sessionId = 1;
const _dayId = 10;

Exercise _exercise(String id, String name) => Exercise(
  id: id,
  name: name,
  muscleIds: const ['chest'],
  isPlateLoaded: false,
  isCustom: false,
  isArchived: false,
  isTimed: false,
  equipment: 'other',
);

final _bench = _exercise('bench', 'Bench press');
final _row = _exercise('row', 'Cable row');
final _fly = _exercise('fly', 'Cable fly');
final _dip = _exercise('dip', 'Dip');

WorkoutExercise _slot(
  Exercise exercise,
  int position, {
  int? group,
  int sets = 3,
  int warmups = 0,
}) => WorkoutExercise(
  id: position + 100,
  dayId: _dayId,
  exerciseId: exercise.id,
  position: position,
  defaultSets: sets,
  defaultReps: 8,
  warmupSets: warmups,
  supersetGroup: group,
);

/// A running-order entry; [planned] null for one added mid-session.
SessionExerciseEntry _entry(
  Exercise exercise,
  int position, {
  WorkoutExercise? planned,
}) => SessionExerciseEntry(
  row: SessionExercise(
    id: position + 1,
    sessionId: _sessionId,
    exerciseId: exercise.id,
    position: position,
    workoutExerciseId: planned?.id,
    // Copied from the slot, as starting a session does.
    supersetGroup: planned?.supersetGroup,
  ),
  exercise: exercise,
  planned: planned,
);

LoggedSet _set(Exercise exercise, {int number = 1}) => LoggedSet(
  id: exercise.id.hashCode + number,
  sessionId: _sessionId,
  exerciseId: exercise.id,
  setNumber: number,
  weight: 60,
  reps: 8,
  setType: SetType.normal.name,
);

/// Records every edit and logged set instead of writing them.
class _RecordingSessions extends SessionRepository {
  _RecordingSessions(super.db);

  final logged = <String>[];
  final added = <List<String>>[];
  final swaps = <({int id, String exerciseId})>[];
  final orders = <List<int>>[];
  final removed = <int>[];

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
  }) async => logged.add(exerciseId);

  @override
  Future<int> addExercises(int sessionId, List<String> exerciseIds) async {
    added.add(exerciseIds);
    return exerciseIds.length;
  }

  @override
  Future<bool> swapExercise({
    required int sessionExerciseId,
    required String exerciseId,
  }) async {
    swaps.add((id: sessionExerciseId, exerciseId: exerciseId));
    return true;
  }

  @override
  Future<void> reorderExercises(int sessionId, List<int> orderedIds) async =>
      orders.add(orderedIds);

  @override
  Future<bool> removeExercise(int sessionExerciseId) async {
    removed.add(sessionExerciseId);
    return true;
  }

  /// Superset edits as "next:id", "previous:id" or "leave:id".
  final supersets = <String>[];

  @override
  Future<void> supersetWithNext(int sessionExerciseId) async =>
      supersets.add('next:$sessionExerciseId');

  @override
  Future<void> supersetWithPrevious(int sessionExerciseId) async =>
      supersets.add('previous:$sessionExerciseId');

  @override
  Future<void> leaveSuperset(int sessionExerciseId) async =>
      supersets.add('leave:$sessionExerciseId');
}

/// Records saves of a swap back to the plan.
class _RecordingPlans extends WorkoutRepository {
  _RecordingPlans(super.db);

  final replaced = <({int id, String exerciseId})>[];

  /// Answers like the real repository does when the exercise is already
  /// planned elsewhere in the day.
  bool refuse = false;

  @override
  Future<bool> replacePlannedExercise(int id, String exerciseId) async {
    if (refuse) return false;
    replaced.add((id: id, exerciseId: exerciseId));
    return true;
  }

  /// Superset saves to the plan as "pair:a+b" or "leave:id".
  final supersets = <String>[];

  @override
  Future<bool> supersetPlannedPair(int firstId, int secondId) async {
    if (refuse) return false;
    supersets.add('pair:$firstId+$secondId');
    return true;
  }

  @override
  Future<void> leaveSuperset(int id) async => supersets.add('leave:$id');
}

/// No bests yet, so no set is ever a record and nothing pops up.
class _NoBests extends PersonalRecordsRepository {
  _NoBests(super.db);

  @override
  Future<RecordBaseline> baselineFor(
    String exerciseId, {
    required int sessionId,
  }) async => const RecordBaseline();
}

/// Which exercises started a rest, in order.
final _restStarts = <String>[];

class _SpyTimer extends RestTimer {
  @override
  RestTimerState? build() => null;

  @override
  Future<void> start({
    required String exerciseId,
    required String exerciseName,
    required int seconds,
  }) async => _restStarts.add(exerciseId);
}

void main() {
  late AppDatabase db;
  late _RecordingSessions sessions;
  late _RecordingPlans plans;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sessions = _RecordingSessions(db);
    plans = _RecordingPlans(db);
    _restStarts.clear();
  });
  tearDown(() => db.close());

  Future<void> pump(
    WidgetTester tester, {
    required List<SessionExerciseEntry> entries,
    List<LoggedSet> sets = const [],
    bool free = false,
  }) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final session = WorkoutSession(
      id: _sessionId,
      dayId: free ? null : _dayId,
      name: free ? 'Free workout' : 'Push',
      startedAt: DateTime(2026, 9, 30, 18),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...defaultDisplayOverrides,
          sessionRepositoryProvider.overrideWithValue(sessions),
          workoutRepositoryProvider.overrideWithValue(plans),
          personalRecordsRepositoryProvider.overrideWithValue(_NoBests(db)),
          sessionProvider.overrideWith((ref, id) => Stream.value(session)),
          sessionSetsProvider.overrideWith((ref, id) => Stream.value(sets)),
          sessionExercisesProvider.overrideWith(
            (ref, id) => Stream.value(entries),
          ),
          overloadSuggestionProvider.overrideWith((ref, key) async => null),
          exerciseListProvider.overrideWith(
            (ref) => Stream.value([_bench, _row, _fly, _dip]),
          ),
          restTimerProvider.overrideWith(_SpyTimer.new),
          restForExerciseProvider.overrideWith((ref, id) => 90),
          restTimerAlertsProvider.overrideWith((ref) => Stream.value(false)),
        ],
        child: MaterialApp(
          theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
          home: const ActiveWorkoutScreen(sessionId: _sessionId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The name on the current exercise card.
  Finder onCard(String name) =>
      find.descendant(of: find.byType(AppPanel), matching: find.text(name));

  /// Logs 60 × 8 on the current card through the sheet.
  Future<void> logSet(WidgetTester tester) async {
    await tester.tap(find.textContaining('Log set'));
    await tester.pumpAndSettle();
    for (final key in ['6', '0']) {
      await tester.tap(find.widgetWithText(Center, key).last);
      await tester.pump();
    }
    await tester.tap(find.text('Next: reps'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Center, '8').last);
    await tester.pump();
    await tester.tap(find.text('Save set'));
    await tester.pumpAndSettle();
  }

  group('supersets', () {
    // Bench and row are one superset; the fly stands alone.
    List<SessionExerciseEntry> superset() => [
      _entry(_bench, 0, planned: _slot(_bench, 0, group: 1)),
      _entry(_row, 1, planned: _slot(_row, 1, group: 1)),
      _entry(_fly, 2, planned: _slot(_fly, 2)),
    ];

    testWidgets('the card names its partner', (tester) async {
      await pump(tester, entries: superset());

      expect(onCard('Bench press'), findsOneWidget);
      expect(find.textContaining('Superset with Cable row'), findsOneWidget);
    });

    testWidgets('up next groups the rest of the superset', (tester) async {
      await pump(tester, entries: superset());

      expect(find.text('SUPERSET'), findsOneWidget);
      expect(find.text('Cable row'), findsOneWidget);
      expect(find.text('Cable fly'), findsOneWidget);
    });

    testWidgets('a standalone exercise shows no superset line', (tester) async {
      await pump(tester, entries: superset());

      await tester.tap(find.text('Cable fly'));
      await tester.pumpAndSettle();

      expect(onCard('Cable fly'), findsOneWidget);
      expect(find.textContaining('Superset with'), findsNothing);
    });

    testWidgets('mid-superset there is no rest; the card moves on', (
      tester,
    ) async {
      await pump(tester, entries: superset());

      await logSet(tester);

      expect(sessions.logged, ['bench']);
      expect(_restStarts, isEmpty);
      expect(onCard('Cable row'), findsOneWidget);
    });

    testWidgets('the last of the superset rests, then goes back to the top', (
      tester,
    ) async {
      await pump(tester, entries: superset());

      await logSet(tester); // bench, straight on to the row
      await logSet(tester); // row, then rest

      expect(sessions.logged, ['bench', 'row']);
      expect(_restStarts, ['row']);
      expect(onCard('Bench press'), findsOneWidget);
    });

    testWidgets('a warm-up stays on its exercise and rests like any set', (
      tester,
    ) async {
      // Ramping the bench up happens before the rounds start; bouncing to
      // the row after every ramp-up set would mean tapping back each time.
      await pump(
        tester,
        entries: [
          _entry(_bench, 0, planned: _slot(_bench, 0, group: 1, warmups: 2)),
          _entry(_row, 1, planned: _slot(_row, 1, group: 1)),
        ],
      );

      await tester.tap(find.text('Warm-up 1 of 2'));
      await tester.pumpAndSettle();
      for (final key in ['4', '0']) {
        await tester.tap(find.widgetWithText(Center, key).last);
        await tester.pump();
      }
      await tester.tap(find.text('Next: reps'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(Center, '5').last);
      await tester.pump();
      await tester.tap(find.text('Save set'));
      await tester.pumpAndSettle();

      expect(sessions.logged, ['bench']);
      expect(onCard('Bench press'), findsOneWidget);
      expect(_restStarts, ['bench']);
    });

    testWidgets('an extra set whose partner is finished rests', (tester) async {
      // Four sets of bench against three of row: after round three, the
      // bench's fourth set has no partner left to go to, so it is the end of
      // a round and gets its rest.
      await pump(
        tester,
        entries: [
          _entry(_bench, 0, planned: _slot(_bench, 0, group: 1, sets: 4)),
          _entry(_row, 1, planned: _slot(_row, 1, group: 1)),
        ],
        sets: [
          for (var n = 1; n <= 3; n++) ...[
            _set(_bench, number: n),
            _set(_row, number: n),
          ],
        ],
      );
      expect(onCard('Bench press'), findsOneWidget);

      await logSet(tester);

      expect(sessions.logged, ['bench']);
      expect(_restStarts, ['bench']);
      expect(onCard('Cable row'), findsNothing);
    });

    testWidgets('a standalone exercise rests after every set', (tester) async {
      await pump(tester, entries: superset());
      await tester.tap(find.text('Cable fly'));
      await tester.pumpAndSettle();

      await logSet(tester);

      expect(_restStarts, ['fly']);
    });
  });

  group('free workout', () {
    testWidgets('starts empty, with a way to add exercises', (tester) async {
      await pump(tester, entries: const [], free: true);

      expect(find.text('Free workout'), findsWidgets);
      expect(find.text('Add exercise'), findsOneWidget);
      expect(find.textContaining('Log set'), findsNothing);
    });

    testWidgets('adding asks the picker and appends what was picked', (
      tester,
    ) async {
      await pump(tester, entries: const [], free: true);

      await tester.tap(find.text('Add exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dip'));
      await tester.tap(find.text('Cable fly'));
      await tester.pump();
      await tester.tap(find.text('Add 2'));
      await tester.pumpAndSettle();

      expect(sessions.added, [
        ['dip', 'fly'],
      ]);
    });

    testWidgets('an added exercise works to 3 × 10', (tester) async {
      await pump(tester, entries: [_entry(_dip, 0)], free: true);

      expect(onCard('Dip'), findsOneWidget);
      expect(find.text('3 × 10'), findsOneWidget);
    });
  });

  group('supersets made mid-session', () {
    Future<void> openSuperset(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Exercise options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Superset'));
      await tester.pumpAndSettle();
    }

    testWidgets('a free workout pairs neighbours without asking about a plan', (
      tester,
    ) async {
      await pump(
        tester,
        entries: [_entry(_dip, 0), _entry(_row, 1)],
        free: true,
      );

      await openSuperset(tester);
      await tester.tap(find.text('Superset with Cable row'));
      await tester.pumpAndSettle();

      // No plan to save to, so no "for how long?" question.
      expect(find.text('For how long?'), findsNothing);
      expect(sessions.supersets, ['next:1']);
      expect(plans.supersets, isEmpty);
    });

    testWidgets('a planned pair can be saved to the plan as well', (
      tester,
    ) async {
      await pump(
        tester,
        entries: [
          _entry(_bench, 0, planned: _slot(_bench, 0)),
          _entry(_row, 1, planned: _slot(_row, 1)),
        ],
      );

      await openSuperset(tester);
      await tester.tap(find.text('Superset with Cable row'));
      await tester.pumpAndSettle();
      expect(find.text('For how long?'), findsOneWidget);
      await tester.tap(find.text('This workout and the plan'));
      await tester.pumpAndSettle();

      expect(sessions.supersets, ['next:1']);
      expect(plans.supersets, ['pair:100+101']);
    });

    testWidgets('or kept to this workout', (tester) async {
      await pump(
        tester,
        entries: [
          _entry(_bench, 0, planned: _slot(_bench, 0)),
          _entry(_row, 1, planned: _slot(_row, 1)),
        ],
      );

      await openSuperset(tester);
      await tester.tap(find.text('Superset with Cable row'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Just this workout'));
      await tester.pumpAndSettle();

      expect(sessions.supersets, ['next:1']);
      expect(plans.supersets, isEmpty);
    });

    testWidgets('a plan that keeps them apart keeps the superset to today, '
        'and says so', (tester) async {
      plans.refuse = true;
      await pump(
        tester,
        entries: [
          _entry(_bench, 0, planned: _slot(_bench, 0)),
          _entry(_row, 1, planned: _slot(_row, 1)),
        ],
      );

      await openSuperset(tester);
      await tester.tap(find.text('Superset with Cable row'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('This workout and the plan'));
      await tester.pumpAndSettle();

      expect(sessions.supersets, ['next:1']);
      expect(
        find.textContaining("aren't next to each other in the plan"),
        findsOneWidget,
      );
    });

    testWidgets('a superset can be left, from the plan too', (tester) async {
      await pump(
        tester,
        entries: [
          _entry(_bench, 0, planned: _slot(_bench, 0, group: 1)),
          _entry(_row, 1, planned: _slot(_row, 1, group: 1)),
        ],
      );

      await openSuperset(tester);
      // Already paired with the row, so only leaving is offered.
      expect(find.text('Superset with Cable row'), findsNothing);
      await tester.tap(find.text('Remove from superset'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('This workout and the plan'));
      await tester.pumpAndSettle();

      expect(sessions.supersets, ['leave:1']);
      expect(plans.supersets, ['leave:100']);
    });

    testWidgets('one exercise alone is not offered a superset', (tester) async {
      await pump(tester, entries: [_entry(_dip, 0)], free: true);

      await tester.tap(find.byTooltip('Exercise options'));
      await tester.pumpAndSettle();

      expect(find.text('Superset'), findsNothing);
      expect(find.text('Swap exercise'), findsOneWidget);
    });
  });

  group('editing mid-session', () {
    testWidgets('the picker leaves out what is already in the workout', (
      tester,
    ) async {
      await pump(
        tester,
        entries: [_entry(_bench, 0, planned: _slot(_bench, 0))],
      );

      await tester.tap(find.text('Add exercise'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Bench press'),
        ),
        findsNothing,
      );
      expect(find.text('Dip'), findsOneWidget);
    });

    testWidgets('a planned exercise can be swapped for today only', (
      tester,
    ) async {
      await pump(
        tester,
        entries: [_entry(_bench, 0, planned: _slot(_bench, 0))],
      );

      await tester.tap(find.byTooltip('Exercise options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Swap exercise'));
      await tester.pumpAndSettle();
      expect(find.text('Swap Bench press'), findsOneWidget);
      await tester.tap(find.text('Dip'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Just this workout'));
      await tester.pumpAndSettle();

      expect(sessions.swaps, [(id: 1, exerciseId: 'dip')]);
      expect(plans.replaced, isEmpty);
    });

    testWidgets('or saved to the plan as well', (tester) async {
      await pump(
        tester,
        entries: [_entry(_bench, 0, planned: _slot(_bench, 0))],
      );

      await tester.tap(find.byTooltip('Exercise options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Swap exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dip'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('This workout and the plan'));
      await tester.pumpAndSettle();

      expect(sessions.swaps, [(id: 1, exerciseId: 'dip')]);
      expect(plans.replaced, [(id: 100, exerciseId: 'dip')]);
    });

    testWidgets('a plan that already has it keeps the swap to today, and says '
        'so', (tester) async {
      plans.refuse = true;
      await pump(
        tester,
        entries: [_entry(_bench, 0, planned: _slot(_bench, 0))],
      );

      await tester.tap(find.byTooltip('Exercise options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Swap exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dip'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('This workout and the plan'));
      await tester.pumpAndSettle();

      expect(sessions.swaps, [(id: 1, exerciseId: 'dip')]);
      expect(plans.replaced, isEmpty);
      expect(find.textContaining("already in this day's plan"), findsOneWidget);
    });

    testWidgets('an added exercise swaps without asking about the plan', (
      tester,
    ) async {
      await pump(tester, entries: [_entry(_dip, 0)], free: true);

      await tester.tap(find.byTooltip('Exercise options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Swap exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cable fly'));
      await tester.pumpAndSettle();

      expect(find.text('Just this workout'), findsNothing);
      expect(sessions.swaps, [(id: 1, exerciseId: 'fly')]);
    });

    testWidgets('an untouched exercise can be removed', (tester) async {
      await pump(
        tester,
        entries: [
          _entry(_bench, 0, planned: _slot(_bench, 0)),
          _entry(_row, 1, planned: _slot(_row, 1)),
        ],
      );

      await tester.tap(find.byTooltip('Exercise options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from workout'));
      await tester.pumpAndSettle();

      expect(sessions.removed, [1]);
    });

    testWidgets('but not once it has sets', (tester) async {
      await pump(
        tester,
        entries: [_entry(_bench, 0, planned: _slot(_bench, 0))],
        sets: [_set(_bench)],
      );

      await tester.tap(find.byTooltip('Exercise options'));
      await tester.pumpAndSettle();

      expect(find.text('Swap exercise'), findsOneWidget);
      expect(find.text('Remove from workout'), findsNothing);
    });

    testWidgets('the order can be changed and saved', (tester) async {
      await pump(
        tester,
        entries: [
          _entry(_bench, 0, planned: _slot(_bench, 0)),
          _entry(_row, 1, planned: _slot(_row, 1)),
          _entry(_fly, 2, planned: _slot(_fly, 2)),
        ],
      );

      await tester.tap(find.text('Reorder'));
      await tester.pumpAndSettle();
      expect(find.text('Reorder exercises'), findsOneWidget);

      // Drag the bench below the row by its handle.
      final handle = find.byIcon(LucideIcons.gripHorizontal).first;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump();
      // In steps, the way a finger moves: one jump is not a drag.
      for (var i = 0; i < 7; i++) {
        await gesture.moveBy(const Offset(0, 10));
        await tester.pump();
      }
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(sessions.orders, [
        [2, 1, 3],
      ]);
    });

    testWidgets('a single exercise has nothing to reorder', (tester) async {
      await pump(
        tester,
        entries: [_entry(_bench, 0, planned: _slot(_bench, 0))],
      );

      expect(find.text('Reorder'), findsNothing);
    });
  });
}
