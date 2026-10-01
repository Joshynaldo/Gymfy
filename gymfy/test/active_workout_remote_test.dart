// The active workout and the controls outside it.
//
// The card's "which exercise am I on" moved out of the screen so the
// notification and the watch can share it — which only works if the screen
// follows a pick made elsewhere. And the screen is where notification
// permission is asked for, when a workout opens.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/features/overload/data/overload_repository.dart';
import 'package:gymfy/features/settings/data/notification_preferences.dart';
import 'package:gymfy/features/workout/data/next_set.dart';
import 'package:gymfy/features/workout/data/personal_records.dart';
import 'package:gymfy/features/workout/data/rest_timer_controller.dart';
import 'package:gymfy/features/workout/data/rest_timer_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/screens/active_workout_screen.dart';
import 'package:gymfy/features/workout_notification/data/workout_notification.dart';
import 'package:gymfy/shared/data/notification_service.dart';
import 'package:gymfy/shared/database/app_database.dart' hide RestTimer;
import 'package:gymfy/shared/widgets/app_card.dart';

import 'support/default_accent.dart';

const _sessionId = 1;

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

SessionExerciseEntry _entry(Exercise exercise, int position) =>
    SessionExerciseEntry(
      row: SessionExercise(
        id: position + 1,
        sessionId: _sessionId,
        exerciseId: exercise.id,
        position: position,
        workoutExerciseId: position + 100,
      ),
      exercise: exercise,
      planned: WorkoutExercise(
        id: position + 100,
        dayId: 10,
        exerciseId: exercise.id,
        position: position,
        defaultSets: 3,
        defaultReps: 8,
        warmupSets: 0,
      ),
    );

class _NoBests extends PersonalRecordsRepository {
  _NoBests(super.db);

  @override
  Future<RecordBaseline> baselineFor(
    String exerciseId, {
    required int sessionId,
  }) async => const RecordBaseline();
}

class _NoTimer extends RestTimer {
  @override
  RestTimerState? build() => null;
}

/// Answers the permission question without a device, and counts the asks.
class _Permissions extends NotificationService {
  _Permissions({required this.grant})
    : super(FlutterLocalNotificationsPlugin());

  final bool grant;
  var asked = 0;

  @override
  Future<bool> requestPermission() async {
    asked++;
    return grant;
  }
}

/// Counts re-sends instead of posting anything.
var _resends = 0;

class _SpySync extends WorkoutNotificationSync {
  @override
  WorkoutNotificationContent? build() => null;

  @override
  void resend() => _resends++;
}

void main() {
  late AppDatabase db;
  final bench = _exercise('bench', 'Bench press');
  final row = _exercise('row', 'Cable row');

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    _resends = 0;
  });
  tearDown(() => db.close());

  Future<void> pump(
    WidgetTester tester, {
    bool notificationOn = false,
    _Permissions? permissions,
  }) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final session = WorkoutSession(
      id: _sessionId,
      dayId: 10,
      name: 'Push',
      startedAt: DateTime(2026, 10, 1, 18),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          defaultBodyFigureOverride,
          defaultAccentOverride,
          defaultWeightUnitOverride,
          ...defaultLoggingOverrides,
          workoutNotificationProvider.overrideWith(
            (ref) => Stream.value(notificationOn),
          ),
          notificationServiceProvider.overrideWithValue(
            permissions ?? _Permissions(grant: true),
          ),
          workoutNotificationSyncProvider.overrideWith(_SpySync.new),
          sessionRepositoryProvider.overrideWithValue(SessionRepository(db)),
          personalRecordsRepositoryProvider.overrideWithValue(_NoBests(db)),
          sessionProvider.overrideWith((ref, id) => Stream.value(session)),
          sessionSetsProvider.overrideWith(
            (ref, id) => Stream.value(const <LoggedSet>[]),
          ),
          sessionExercisesProvider.overrideWith(
            (ref, id) => Stream.value([_entry(bench, 0), _entry(row, 1)]),
          ),
          overloadSuggestionProvider.overrideWith((ref, key) async => null),
          restTimerProvider.overrideWith(_NoTimer.new),
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

  Finder onCard(String name) =>
      find.descendant(of: find.byType(AppPanel), matching: find.text(name));

  testWidgets('follows a pick made from the notification or the watch', (
    tester,
  ) async {
    // Mid-superset a set logged from the wrist moves on to the partner; the
    // phone, picked up a moment later, has to be showing the same exercise.
    await pump(tester);
    expect(onCard('Bench press'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ActiveWorkoutScreen)),
    );
    container.read(pickedExerciseProvider(_sessionId).notifier).pick('row');
    await tester.pumpAndSettle();

    expect(onCard('Cable row'), findsOneWidget);
  });

  testWidgets('asks for notification permission as the workout opens', (
    tester,
  ) async {
    final permissions = _Permissions(grant: true);
    await pump(tester, notificationOn: true, permissions: permissions);

    expect(permissions.asked, 1);
    // Everything posted before the answer was dropped; send it again.
    expect(_resends, 1);
  });

  testWidgets('a refusal is left alone', (tester) async {
    final permissions = _Permissions(grant: false);
    await pump(tester, notificationOn: true, permissions: permissions);

    expect(permissions.asked, 1);
    expect(_resends, 0);
  });

  testWidgets('does not ask with the workout notification off', (tester) async {
    final permissions = _Permissions(grant: true);
    await pump(tester, permissions: permissions);

    expect(permissions.asked, 0);
  });

  testWidgets(
    'does not ask on iOS, which has no workout notification',
    (tester) async {
      // A permission dialog for a feature the platform does not have.
      final permissions = _Permissions(grant: true);
      await pump(tester, notificationOn: true, permissions: permissions);

      expect(permissions.asked, 0);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
