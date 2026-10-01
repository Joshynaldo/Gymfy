// The ongoing workout notification.
//
// Three questions, kept apart because they fail differently: what it says
// (a pure function), when it is sent (the wiring — an update that never goes
// out leaves yesterday's set on the lock screen), and whether its "Log set"
// button writes the right set exactly once when it comes back in.

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/overload/data/overload_repository.dart';
import 'package:gymfy/features/settings/data/notification_preferences.dart';
import 'package:gymfy/features/wear/data/wear_bridge.dart';
import 'package:gymfy/features/wear/data/wear_sync.dart';
import 'package:gymfy/features/workout/data/next_set.dart';
import 'package:gymfy/features/workout/data/rest_timer_controller.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/features/workout_notification/data/workout_notification.dart';
import 'package:gymfy/shared/data/notification_service.dart';
// RestTimer is also a Drift row class in here — the controller is the one
// this test means.
import 'package:gymfy/shared/database/app_database.dart' hide RestTimer;
import 'package:gymfy/shared/utils/units.dart';

final _session = WorkoutSession(
  id: 1,
  name: 'Push A',
  startedAt: DateTime(2026, 10, 1, 18),
);

NextSet _next({
  String name = 'Bench Press',
  int number = 2,
  double weight = 80,
  int reps = 8,
  int? seconds,
  bool confident = true,
}) => (
  exerciseId: name.toLowerCase().replaceAll(' ', '_'),
  exerciseName: name,
  setNumber: number,
  plannedSets: 3,
  weightKg: weight,
  reps: seconds == null ? reps : 0,
  seconds: seconds,
  confident: confident,
);

RestTimerState _rest(int remaining, {int total = 90}) => (
  exerciseId: 'bench_press',
  exerciseName: 'Bench Press',
  totalSeconds: total,
  remainingSeconds: remaining,
);

/// The request a "Log set" button would send, read back.
RemoteSetRequest? _request(WorkoutNotificationContent? content) {
  final command = content?.logCommand ?? '';
  if (!command.startsWith('${WearBridge.commandLogSet}:')) return null;
  return WearBridge.parseLogSet(
    command.substring(WearBridge.commandLogSet.length + 1),
  );
}

void main() {
  final now = DateTime(2026, 10, 1, 18, 30);

  WorkoutNotificationContent? build({
    WorkoutSession? session,
    NextSet? next,
    RestTimerState? rest,
    DateTime? at,
    WeightUnit unit = WeightUnit.kg,
    String logId = 'id-1',
  }) => workoutNotificationFrom(
    session: session ?? _session,
    next: next,
    rest: rest,
    now: at ?? now,
    unit: unit,
    logId: logId,
  );

  group('what it says', () {
    test('nothing at all without a workout', () {
      expect(
        workoutNotificationFrom(
          session: null,
          next: _next(),
          rest: null,
          now: now,
          unit: WeightUnit.kg,
          logId: 'x',
        ),
        isNull,
      );
    });

    test('the workout, the exercise and which set', () {
      final content = build(next: _next());

      expect(content?.title, 'Push A');
      expect(content?.text, 'Bench Press · Set 2 of 3');
      expect(
        content?.bigText,
        'Bench Press · Set 2 of 3\nNext: 80 kg × 8 reps',
      );
      expect(content?.subText, isEmpty);
      expect(content?.restEndsAtMs, 0);
    });

    test('"Log set" logs exactly what it says, in kilograms', () {
      final request = _request(build(next: _next(), logId: 'n-7'));

      expect(request?.id, 'n-7');
      expect(request?.exerciseId, 'bench_press');
      expect(request?.weight, 80);
      expect(request?.unit, WeightUnit.kg);
      expect(request?.reps, 8);
      expect(request?.seconds, isNull);
    });

    test(
      'a pounds user reads pounds, and the button still sends kilograms',
      () {
        // Nothing converts on the way back, so nothing drifts by a rounding.
        final content = build(next: _next(weight: 100), unit: WeightUnit.lbs);

        expect(content?.bigText, contains('lbs'));
        expect(_request(content)?.weight, 100);
        expect(_request(content)?.unit, WeightUnit.kg);
      },
    );

    test('a hold is logged as seconds, never reps', () {
      final request = _request(
        build(next: _next(name: 'Plank', weight: 0, seconds: 45)),
      );

      expect(request?.seconds, 45);
      expect(request?.reps, isNull);
    });

    test('no button, and no numbers, for a set that is only a guess', () {
      // "Log 0 kg × 8" for a lift with no history would write a set nobody
      // did; tapping the notification still opens the app.
      final content = build(next: _next(weight: 0, confident: false));

      expect(content?.logCommand, isEmpty);
      expect(content?.bigText, isEmpty);
      expect(content?.text, 'Bench Press · Set 2 of 3');
    });

    test('an empty workout says so, with nothing to log', () {
      final content = build();

      expect(content?.text, 'No exercises yet');
      expect(content?.logCommand, isEmpty);
    });

    test('a rest hands the system a deadline to count down to', () {
      final content = build(next: _next(), rest: _rest(90));

      expect(content?.subText, 'Resting');
      expect(
        content?.restEndsAtMs,
        now.add(const Duration(seconds: 90)).millisecondsSinceEpoch,
      );
    });

    test('and the deadline holds still while the timer ticks', () {
      // The rest timer rebuilds the notification every second; if the
      // content moved with it, every tick would re-post the notification.
      final first = build(next: _next(), rest: _rest(90));
      final later = build(
        next: _next(),
        rest: _rest(89),
        at: now.add(const Duration(milliseconds: 1003)),
      );

      expect(later, first);
    });

    test('a rest that has run out is no countdown at all', () {
      final content = build(next: _next(), rest: _rest(0));

      expect(content?.restEndsAtMs, 0);
      expect(content?.subText, isEmpty);
    });
  });

  group('keeping it in step', () {
    late _SpyNotificationBridge bridge;
    late StreamController<WorkoutSession?> sessions;
    late StreamController<bool> setting;

    setUp(() {
      bridge = _SpyNotificationBridge();
      sessions = StreamController<WorkoutSession?>.broadcast();
      setting = StreamController<bool>.broadcast();
    });

    tearDown(() async {
      await sessions.close();
      await setting.close();
    });

    ProviderContainer containerWith() {
      final container = ProviderContainer(
        overrides: [
          workoutNotificationBridgeProvider.overrideWithValue(bridge),
          workoutNotificationProvider.overrideWith((ref) => setting.stream),
          inProgressSessionProvider.overrideWith((ref) => sessions.stream),
          nextSetProvider.overrideWith(
            (ref, id) async => ref.watch(_nextProvider),
          ),
          restTimerProvider.overrideWith(_FakeTimer.new),
          weightUnitProvider.overrideWithValue(WeightUnit.kg),
        ],
      );
      addTearDown(container.dispose);
      // Kept alive the way main.dart does.
      container.listen(workoutNotificationSyncProvider, (_, _) {});
      return container;
    }

    /// Room for something that should *not* happen to happen anyway.
    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 20));

    /// Waits, up to a second, for something that should happen. Polled
    /// rather than a fixed delay: the first build of a test file runs cold,
    /// and a fixed 20 ms was sometimes not enough.
    Future<void> until(bool Function() done) async {
      for (var i = 0; i < 200 && !done(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    }

    /// Starts a workout and waits for its first notification.
    Future<void> start() async {
      setting.add(true);
      sessions.add(_session);
      await until(() => bridge.shown.isNotEmpty);
    }

    test('shows the running workout', () async {
      final container = containerWith();
      container.read(_nextProvider.notifier).value = _next(number: 1);

      await start();

      expect(bridge.shown.last.title, 'Push A');
      expect(bridge.shown.last.text, 'Bench Press · Set 1 of 3');
    });

    test(
      'updates when a set lands, the exercise changes, or a rest starts',
      () async {
        final container = containerWith();
        final next = container.read(_nextProvider.notifier);
        next.value = _next(number: 1);
        await start();

        next.value = _next(number: 2);
        await until(() => bridge.shown.last.text.contains('Set 2'));
        expect(bridge.shown.last.text, 'Bench Press · Set 2 of 3');

        next.value = _next(name: 'Cable Row', number: 1);
        await until(() => bridge.shown.last.text.startsWith('Cable'));
        expect(bridge.shown.last.text, 'Cable Row · Set 1 of 3');

        (container.read(restTimerProvider.notifier) as _FakeTimer).value =
            _rest(90);
        await until(() => bridge.shown.last.restEndsAtMs > 0);
        expect(bridge.shown.last.subText, 'Resting');
        expect(bridge.shown.last.restEndsAtMs, greaterThan(0));

        (container.read(restTimerProvider.notifier) as _FakeTimer).value = null;
        await until(() => bridge.shown.last.restEndsAtMs == 0);
        expect(bridge.shown.last.restEndsAtMs, 0);
      },
    );

    test('an unchanged state is not sent again', () async {
      final container = containerWith();
      container.read(_nextProvider.notifier).value = _next();
      await start();
      final sent = bridge.shown.length;

      // The same session again — a stream re-emitting is not a change.
      sessions.add(_session);
      await settle();

      expect(bridge.shown.length, sent);
    });

    test('every new state gets a new log id, and only a new state', () async {
      // The id is what makes two taps on one notification one set: it has
      // to stay put while the notification does, and move on once the set
      // has landed.
      final container = containerWith();
      final next = container.read(_nextProvider.notifier);
      next.value = _next(number: 1);
      await start();
      final first = _request(bridge.shown.last)!.id;

      sessions.add(_session);
      await settle();
      expect(_request(bridge.shown.last)!.id, first);

      next.value = _next(number: 2);
      await until(() => bridge.shown.last.text.contains('Set 2'));
      expect(_request(bridge.shown.last)!.id, isNot(first));
    });

    test('goes away when the workout is finished or discarded', () async {
      final container = containerWith();
      container.read(_nextProvider.notifier).value = _next();
      await start();
      final clearsBefore = bridge.cleared;

      // Finishing and discarding look the same from here: the in-progress
      // session stops existing.
      sessions.add(null);
      await until(() => bridge.cleared > clearsBefore);
      await settle();

      expect(bridge.cleared, clearsBefore + 1);
      expect(container.read(workoutNotificationSyncProvider), isNull);
    });

    test('goes away when switched off, and stays away', () async {
      final container = containerWith();
      container.read(_nextProvider.notifier).value = _next();
      await start();

      setting.add(false);
      await until(() => bridge.cleared > 0);
      final shown = bridge.shown.length;
      expect(bridge.cleared, greaterThan(0));

      container.read(_nextProvider.notifier).value = _next(number: 3);
      await settle();
      expect(bridge.shown.length, shown);
    });

    test('shows nothing until the setting has loaded', () async {
      // Someone who switched it off must not see it flash up at launch.
      containerWith();
      sessions.add(_session);
      await settle();

      expect(bridge.shown, isEmpty);
      expect(bridge.cleared, 0);
    });

    test('clears a leftover once at launch, not on every rebuild', () async {
      // A notification left behind by a process that died mid-workout.
      containerWith();
      setting.add(true);
      sessions.add(null);
      await until(() => bridge.cleared > 0);
      sessions.add(null);
      await settle();

      expect(bridge.cleared, 1);
    });

    test('can be sent again, for when permission arrives late', () async {
      final container = containerWith();
      container.read(_nextProvider.notifier).value = _next();
      await start();
      final last = bridge.shown.last;

      container.read(workoutNotificationSyncProvider.notifier).resend();

      expect(bridge.shown.last, last);
      expect(bridge.shown.where((c) => c == last), hasLength(2));
    });

    test('knows whether Android actually showed it', () async {
      // The rest timer moves its countdown in here only while it is really
      // on screen.
      final container = containerWith();
      container.read(_nextProvider.notifier).value = _next();
      await start();
      final sync = container.read(workoutNotificationSyncProvider.notifier);
      await until(() => sync.posted);
      expect(sync.posted, isTrue);

      sessions.add(null);
      await until(() => !sync.posted);
      expect(sync.posted, isFalse);
    });

    test('and does not claim it when Android refused', () async {
      bridge.onScreen = false;
      final container = containerWith();
      container.read(_nextProvider.notifier).value = _next();
      await start();

      expect(bridge.shown, isNotEmpty);
      expect(
        container.read(workoutNotificationSyncProvider.notifier).posted,
        isFalse,
      );
    });
  });

  group('the rest countdown', () {
    Future<List<String>> startRestWith(
      WorkoutNotificationSync Function() sync,
    ) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final notifications = _RecordingNotifications();
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(notifications),
          restTimerAlertsProvider.overrideWith((ref) => Stream.value(true)),
          workoutNotificationSyncProvider.overrideWith(sync),
        ],
      );
      addTearDown(container.dispose);
      container.listen(restTimerAlertsProvider, (_, _) {});
      await container.read(restTimerAlertsProvider.future);

      await container
          .read(restTimerProvider.notifier)
          .start(exerciseId: 'bench', exerciseName: 'Bench', seconds: 90);
      return notifications.calls;
    }

    test(
      'is not posted a second time while the workout notification is up',
      () async {
        // No 'show': the countdown is inside the workout notification. The
        // "rest over" alert is still armed, because that one has to interrupt.
        expect(await startRestWith(_ShowingSync.new), [
          'cancel',
          'schedule:90',
        ]);
      },
    );

    test('stays with the rest timer when Android did not show it', () async {
      // Moving the countdown into a notification nobody can see would leave
      // the shade with no countdown at all.
      expect(await startRestWith(_BlockedSync.new), [
        'cancel',
        'show:90',
        'schedule:90',
      ]);
    });
  });

  group('from the shade to the database', () {
    late AppDatabase db;
    late SessionRepository sessions;
    late int sessionId;
    late ProviderContainer container;
    late _SpyNotificationBridge notification;
    late _FakeWearBridge wear;

    setUp(() async {
      _restStarts.clear();
      db = AppDatabase.forTesting(NativeDatabase.memory());
      sessions = SessionRepository(db);
      await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              id: 'bench',
              name: 'Bench',
              muscleIds: const ['chest'],
            ),
          );
      final plans = WorkoutRepository(db);
      final dayId = await plans.createDay(await plans.createSplit('PPL'), 'A');
      await plans.addExercisesToDay(dayId, ['bench']);
      sessionId = await sessions.startSession(dayId: dayId, name: 'Push A');

      notification = _SpyNotificationBridge();
      wear = _FakeWearBridge();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          workoutNotificationBridgeProvider.overrideWithValue(notification),
          wearBridgeProvider.overrideWithValue(wear),
          restTimerProvider.overrideWith(_SpyRestTimer.new),
          overloadSuggestionProvider.overrideWith((ref, key) async => null),
        ],
      );
      // What main.dart keeps alive.
      container.listen(workoutNotificationSyncProvider, (_, _) {});
      container.read(wearCommandsProvider);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    /// Waits for the notification to say [text].
    Future<WorkoutNotificationContent> shows(String text) async {
      for (var i = 0; i < 100; i++) {
        final last = notification.shown.lastOrNull;
        if (last != null && last.text == text) return last;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      fail(
        'the notification never said "$text"; it said '
        '${notification.shown.map((c) => c.text).toList()}',
      );
    }

    test(
      '"Log set" writes the set once, and the notification moves on',
      () async {
        await sessions.logSet(
          sessionId: sessionId,
          exerciseId: 'bench',
          setNumber: 1,
          weight: 80,
          reps: 8,
        );
        final before = await shows('Bench · Set 2 of 3');
        expect(before.bigText, contains('80 kg × 8 reps'));

        // Two taps on the same notification: the same command twice.
        await wear.handler!(before.logCommand);
        await wear.handler!(before.logCommand);

        final sets = await sessions.watchSessionSets(sessionId).first;
        expect(sets, hasLength(2), reason: 'a double tap is one set');
        expect(sets.last.setNumber, 2);
        expect(sets.last.weight, 80);
        expect(sets.last.reps, 8);
        expect(_restStarts, ['bench']);

        final after = await shows('Bench · Set 3 of 3');
        expect(_request(after)!.id, isNot(_request(before)!.id));
      },
    );

    test('the rest buttons reach the same timer as the watch\'s', () async {
      final timer = container.read(restTimerProvider.notifier) as _SpyRestTimer;

      await wear.handler!(WearBridge.commandAddThirty);
      await wear.handler!(WearBridge.commandSkipRest);

      expect(timer.calls, ['adjust:30', 'stop']);
    });
  });
}

/// Records what would have been posted.
class _SpyNotificationBridge implements WorkoutNotificationBridge {
  final shown = <WorkoutNotificationContent>[];
  var cleared = 0;

  /// What Android answers: false without permission, or with the channel
  /// switched off.
  var onScreen = true;

  @override
  Future<bool> show(WorkoutNotificationContent content) async {
    shown.add(content);
    return onScreen;
  }

  @override
  Future<void> clear() async => cleared++;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Plays the watch, and the notification's receiver, for the command path.
class _FakeWearBridge implements WearBridge {
  Future<void> Function(String command)? handler;

  @override
  void listen(Future<void> Function(String command)? onCommand) =>
      handler = onCommand;

  @override
  Future<void> push(WearWorkout workout) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// The next set, settable from a test.
class _Next extends Notifier<NextSet?> {
  @override
  NextSet? build() => null;

  set value(NextSet? next) => state = next;
}

final _nextProvider = NotifierProvider<_Next, NextSet?>(_Next.new);

/// A rest timer a test can set directly.
class _FakeTimer extends RestTimer {
  @override
  RestTimerState? build() => null;

  set value(RestTimerState? rest) => state = rest;
}

final _restStarts = <String>[];

class _SpyRestTimer extends RestTimer {
  final calls = <String>[];

  @override
  RestTimerState? build() => null;

  @override
  Future<void> start({
    required String exerciseId,
    required String exerciseName,
    required int seconds,
  }) async => _restStarts.add(exerciseId);

  @override
  void adjust(int delta) => calls.add('adjust:$delta');

  @override
  void stop() => calls.add('stop');
}

/// A workout notification that is up.
class _ShowingSync extends WorkoutNotificationSync {
  @override
  WorkoutNotificationContent? build() => (
    title: 'Push A',
    text: 'Bench · Set 2 of 3',
    bigText: '',
    subText: '',
    restEndsAtMs: 0,
    logCommand: '',
  );

  @override
  bool get posted => true;
}

/// A workout notification that is wanted, but that Android did not show —
/// no permission, or its channel switched off in the system settings.
class _BlockedSync extends _ShowingSync {
  @override
  bool get posted => false;
}

/// Stands in for the real notification service, as in rest_timer_test.dart.
class _RecordingNotifications extends NotificationService {
  _RecordingNotifications() : super(FlutterLocalNotificationsPlugin());

  final List<String> calls = <String>[];

  @override
  Future<void> showRestRunning({
    required int seconds,
    required String exerciseName,
  }) async => calls.add('show:$seconds');

  @override
  Future<void> notifyRestOver({
    required String exerciseName,
    required bool vibrate,
  }) async => calls.add('over:$vibrate');

  @override
  Future<void> scheduleRestOver({
    required int seconds,
    required String exerciseName,
    required bool vibrate,
  }) async => calls.add('schedule:$seconds');

  @override
  Future<void> cancelRestOver() async => calls.add('cancel');
}
