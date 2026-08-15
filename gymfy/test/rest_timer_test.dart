// Rest timers: how a length is resolved, how it's stored per exercise, and how
// the countdown behaves.

import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
import 'package:gymfy/features/settings/data/notification_preferences.dart';
import 'package:gymfy/features/workout/data/rest_timer_controller.dart';
import 'package:gymfy/features/workout/data/rest_timer_repository.dart';
import 'package:gymfy/shared/data/notification_service.dart';
import 'package:gymfy/shared/data/settings_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  group('formatRest', () {
    test('reads like a timer, not a number of seconds', () {
      expect(formatRest(90), '1:30');
      expect(formatRest(60), '1:00');
      expect(formatRest(45), '0:45');
      expect(formatRest(300), '5:00');
      // Seconds are always two digits, so the text doesn't change width as it
      // ticks from 1:10 down to 1:09.
      expect(formatRest(69), '1:09');
    });
  });

  group('clampRestSeconds', () {
    test('leaves sensible values alone', () {
      expect(clampRestSeconds(90), 90);
      expect(clampRestSeconds(minRestSeconds), minRestSeconds);
      expect(clampRestSeconds(maxRestSeconds), maxRestSeconds);
    });

    test('pulls absurd values into range', () {
      // Zero is not a rest length — "off" is a separate idea with its own
      // control, so it clamps up rather than being stored as a no-op timer.
      expect(clampRestSeconds(0), minRestSeconds);
      expect(clampRestSeconds(-30), minRestSeconds);
      expect(clampRestSeconds(99999), maxRestSeconds);
    });
  });

  group('parseRestSeconds', () {
    test('reads back what was written', () {
      expect(parseRestSeconds('90'), 90);
    });

    test('an unset or unreadable value is not a length', () {
      expect(parseRestSeconds(null), isNull);
      expect(parseRestSeconds(''), isNull);
      expect(parseRestSeconds('ninety'), isNull);
      expect(parseRestSeconds('90.5'), isNull);
    });

    test('an out-of-range stored value is clamped, not discarded', () {
      expect(parseRestSeconds('99999'), maxRestSeconds);
      expect(parseRestSeconds('1'), minRestSeconds);
    });
  });

  group('resolving a rest length', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      // Rest overrides have a foreign key onto exercises, so the seed data has
      // to exist before one can be written.
      await container.read(exerciseRepositoryProvider).seed();
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<T> firstValue<T>(StreamProvider<T> provider) {
      container.listen(provider, (_, _) {});
      return container.read(provider.future);
    }

    /// Reads the effective rest for an exercise once both streams have emitted.
    Future<int> effectiveRest(String exerciseId) async {
      await firstValue(defaultRestProvider);
      await firstValue(exerciseRestOverrideProvider(exerciseId));
      return container.read(restForExerciseProvider(exerciseId));
    }

    test('falls back to the documented default', () async {
      expect(await firstValue(defaultRestProvider), defaultRestSeconds);
      expect(await effectiveRest('barbell_bench_press'), defaultRestSeconds);
    });

    test('a changed default moves every exercise without an override', () async {
      await container
          .read(settingsRepositoryProvider)
          .write(defaultRestSecondsSetting, '120');

      expect(await effectiveRest('barbell_bench_press'), 120);
      expect(await effectiveRest('barbell_back_squat'), 120);
    });

    test('an override beats the default', () async {
      await container
          .read(restTimerRepositoryProvider)
          .setForExercise('barbell_bench_press', 180);

      expect(await effectiveRest('barbell_bench_press'), 180);
      // And only for that exercise.
      expect(await effectiveRest('barbell_back_squat'), defaultRestSeconds);
    });

    test('an override survives the default changing under it', () async {
      await container
          .read(restTimerRepositoryProvider)
          .setForExercise('barbell_bench_press', 180);
      await container
          .read(settingsRepositoryProvider)
          .write(defaultRestSecondsSetting, '45');

      expect(await effectiveRest('barbell_bench_press'), 180);
    });

    test('clearing an override goes back to following the default', () async {
      final repository = container.read(restTimerRepositoryProvider);
      await repository.setForExercise('barbell_bench_press', 180);
      await repository.clearForExercise('barbell_bench_press');

      expect(
        await firstValue(exerciseRestOverrideProvider('barbell_bench_press')),
        isNull,
      );
      expect(await effectiveRest('barbell_bench_press'), defaultRestSeconds);
    });

    test('setting an override twice overwrites rather than duplicating', () async {
      final repository = container.read(restTimerRepositoryProvider);
      await repository.setForExercise('barbell_bench_press', 120);
      await repository.setForExercise('barbell_bench_press', 180);

      expect(await effectiveRest('barbell_bench_press'), 180);
    });

    test('an absurd override is clamped on the way in', () async {
      await container
          .read(restTimerRepositoryProvider)
          .setForExercise('barbell_bench_press', 99999);

      expect(await effectiveRest('barbell_bench_press'), maxRestSeconds);
    });
  });

  group('the countdown', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('nothing is running to begin with', () {
      expect(container.read(restTimerProvider), isNull);
    });

    test('starting one reports the full length', () async {
      await container.read(restTimerProvider.notifier).start(
        exerciseId: 'barbell_bench_press',
        exerciseName: 'Barbell Bench Press',
        seconds: 90,
      );

      final state = container.read(restTimerProvider);
      expect(state?.exerciseName, 'Barbell Bench Press');
      expect(state?.totalSeconds, 90);
      expect(state?.remainingSeconds, 90);
    });

    test('starting a second one replaces the first', () async {
      final controller = container.read(restTimerProvider.notifier);
      await controller.start(
        exerciseId: 'barbell_bench_press',
        exerciseName: 'Barbell Bench Press',
        seconds: 90,
      );
      await controller.start(
        exerciseId: 'barbell_back_squat',
        exerciseName: 'Barbell Back Squat',
        seconds: 180,
      );

      // One timer, not two: you rest between sets of one exercise at a time.
      final state = container.read(restTimerProvider);
      expect(state?.exerciseId, 'barbell_back_squat');
      expect(state?.totalSeconds, 180);
    });

    test('an absurd length is clamped rather than started', () async {
      await container.read(restTimerProvider.notifier).start(
        exerciseId: 'barbell_bench_press',
        exerciseName: 'Barbell Bench Press',
        seconds: 99999,
      );

      expect(container.read(restTimerProvider)?.totalSeconds, maxRestSeconds);
    });

    test('stopping clears it', () async {
      final controller = container.read(restTimerProvider.notifier);
      await controller.start(
        exerciseId: 'barbell_bench_press',
        exerciseName: 'Barbell Bench Press',
        seconds: 90,
      );
      controller.stop();

      expect(container.read(restTimerProvider), isNull);
    });

    test('adding time extends the total as well as the remainder', () async {
      final controller = container.read(restTimerProvider.notifier);
      await controller.start(
        exerciseId: 'barbell_bench_press',
        exerciseName: 'Barbell Bench Press',
        seconds: 90,
      );
      controller.adjust(30);

      // The total moves too, so the progress bar can't jump backwards.
      final state = container.read(restTimerProvider);
      expect(state?.totalSeconds, 120);
      expect(state?.remainingSeconds, greaterThan(90));
    });

    test('taking away more time than is left ends the rest', () async {
      final controller = container.read(restTimerProvider.notifier);
      await controller.start(
        exerciseId: 'barbell_bench_press',
        exerciseName: 'Barbell Bench Press',
        seconds: 90,
      );
      controller.adjust(-200);

      expect(container.read(restTimerProvider), isNull);
    });

    test('adjusting when nothing runs does nothing', () {
      container.read(restTimerProvider.notifier).adjust(30);

      expect(container.read(restTimerProvider), isNull);
    });
  });

  group('what the timer tells the notification shade', () {
    late AppDatabase db;
    late _RecordingNotifications notifications;

    /// Builds a container with the notification service faked out, so these
    /// tests assert on intent rather than needing a real Android device.
    ///
    /// Waits for the preference to actually emit before returning: the timer
    /// reads it synchronously and falls back to "on" while it's still loading,
    /// so a test that didn't wait would silently exercise the default.
    Future<ProviderContainer> containerWith({required bool alertsOn}) async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(notifications),
          restTimerAlertsProvider.overrideWith((ref) => Stream.value(alertsOn)),
        ],
      );
      addTearDown(container.dispose);
      container.listen(restTimerAlertsProvider, (_, _) {});
      await container.read(restTimerAlertsProvider.future);
      return container;
    }

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      notifications = _RecordingNotifications();
    });

    tearDown(() => db.close());

    test('starting shows a live countdown and arms the backstop', () async {
      final container = await containerWith(alertsOn: true);

      await container.read(restTimerProvider.notifier).start(
        exerciseId: 'barbell_bench_press',
        exerciseName: 'Barbell Bench Press',
        seconds: 90,
      );

      // The shade countdown is what makes the timer visible from another app;
      // the schedule only covers this app being frozen before rest ends.
      expect(notifications.calls, ['cancel', 'show:90', 'schedule:90']);
    });

    test('with notifications off nothing is posted', () async {
      final container = await containerWith(alertsOn: false);

      await container.read(restTimerProvider.notifier).start(
        exerciseId: 'barbell_bench_press',
        exerciseName: 'Barbell Bench Press',
        seconds: 90,
      );

      // The clear still happens, so turning the setting off mid-rest can't
      // leave an orphaned notification stuck in the shade.
      expect(notifications.calls, ['cancel']);
    });

    test('adding time re-posts against the new deadline', () async {
      final container = await containerWith(alertsOn: true);
      final controller = container.read(restTimerProvider.notifier);
      await controller.start(
        exerciseId: 'barbell_bench_press',
        exerciseName: 'Barbell Bench Press',
        seconds: 90,
      );
      notifications.calls.clear();

      controller.adjust(30);
      // adjust deliberately doesn't block the UI on the notification, so let
      // the fire-and-forget call land before asserting.
      await Future<void>.delayed(Duration.zero);

      // Roughly 120s: the exact figure depends on where in the second we are.
      expect(notifications.calls.first, 'cancel');
      expect(notifications.calls[1], anyOf('show:120', 'show:119'));
      expect(notifications.calls[2], anyOf('schedule:120', 'schedule:119'));
    });

    test('stopping clears the shade', () async {
      final container = await containerWith(alertsOn: true);
      final controller = container.read(restTimerProvider.notifier);
      await controller.start(
        exerciseId: 'barbell_bench_press',
        exerciseName: 'Barbell Bench Press',
        seconds: 90,
      );
      notifications.calls.clear();

      controller.stop();
      await Future<void>.delayed(Duration.zero);

      expect(notifications.calls, ['cancel']);
    });
  });
}

/// Stands in for the real service, which needs a device to do anything.
///
/// Extends rather than reimplements so that adding a method to
/// [NotificationService] can't silently leave this fake behind.
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
