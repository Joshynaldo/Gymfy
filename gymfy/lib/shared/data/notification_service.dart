import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

part 'notification_service.g.dart';

/// Channel for the live countdown that sits in the shade while you rest.
///
/// Low importance on purpose: it should appear quietly in the shade and on the
/// lock screen, never buzz or slide in over what you're doing. A channel's
/// importance is fixed once Android has created it, which is why the alert
/// below gets a channel of its own rather than sharing this one.
const restTimerRunningChannelId = 'rest_timer_running';

/// Channel for the "rest over" alert, which does need to interrupt.
const restTimerDoneChannelId = 'rest_timer_done';

/// Fixed notification id, shared by the live countdown and the alert.
///
/// One id on purpose: the alert *replaces* the countdown in place rather than
/// stacking a second notification underneath it. You get one rest-timer
/// notification that changes as the rest finishes, not two to dismiss.
const restTimerNotificationId = 1;

/// Shows, updates and cancels the rest-timer notification.
///
/// Every method is safe to call whether or not permission was granted, or the
/// platform even supports notifications — a gym app must not fall over because
/// someone declined a permission. Failures are swallowed because there is no
/// useful recovery: the on-screen countdown is the real timer.
class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  bool _ready = false;

  /// Prepares the plugin and the timezone database.
  ///
  /// Called lazily on first use rather than at startup: most launches never
  /// start a rest timer, and this costs a timezone database load.
  Future<void> _ensureReady() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Without a Darwin entry the plugin never initialises on iOS and every
        // call below quietly does nothing — no error, no notification.
        //
        // Permissions are all false here and asked for later, in
        // [requestPermission]: requesting at initialise would put the system
        // dialog on screen the first time anything touches this service, which
        // is long before the user has started a rest.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Alert settings for the "rest over" notification on iOS.
  ///
  /// No badge: a count on the app icon would sit there after the rest is over
  /// and have to be cleared by hand, which is not what a timer should leave
  /// behind.
  static const _darwinAlert = DarwinNotificationDetails(
    presentAlert: true,
    presentSound: true,
    presentBadge: false,
    interruptionLevel: InterruptionLevel.timeSensitive,
  );

  /// Asks for notification permission, returning whether it was granted.
  ///
  /// Android 13+ requires this at runtime; older versions grant it at install
  /// and the call is a no-op that reports true. iOS always asks, and only once
  /// — a second call returns the answer already on file rather than showing the
  /// dialog again.
  Future<bool> requestPermission() async {
    try {
      await _ensureReady();

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }

      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              sound: true,
              // Not asked for, because nothing here sets one.
              badge: false,
            ) ??
            false;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Posts (or updates) the live countdown, ending [seconds] from now.
  ///
  /// This is shown immediately, not scheduled, and the countdown itself is
  /// drawn by Android: [usesChronometer] with [chronometerCountDown] ticks
  /// down to the [when] timestamp on its own. Nothing in Dart has to run for
  /// the numbers to keep moving, so the time stays correct while you're in
  /// another app and even if this app gets frozen in the background.
  ///
  /// Does nothing on iOS. There is no equivalent of the chronometer there, so
  /// the best iOS could manage is a notification showing a time that never
  /// changes — which is worse than none, because it looks broken and has to be
  /// dismissed by hand. The scheduled "rest over" alert still fires, so the
  /// part that matters is unaffected.
  Future<void> showRestRunning({
    required int seconds,
    required String exerciseName,
  }) async {
    if (Platform.isIOS) return;
    try {
      await _ensureReady();
      final endsAt = DateTime.now().add(Duration(seconds: seconds));
      await _plugin.show(
        id: restTimerNotificationId,
        title: 'Resting',
        body: exerciseName,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            restTimerRunningChannelId,
            'Rest timer countdown',
            channelDescription:
                'Shows the rest countdown while you are in another app.',
            importance: Importance.low,
            priority: Priority.low,
            // Android draws the countdown from this timestamp.
            when: endsAt.millisecondsSinceEpoch,
            showWhen: true,
            usesChronometer: true,
            chronometerCountDown: true,
            // A rest in progress isn't a message to be swiped away, and
            // tapping it to come back to the app shouldn't dismiss it either.
            ongoing: true,
            autoCancel: false,
            // Updating it (say, after +30s) must not make a sound each time.
            onlyAlertOnce: true,
            silent: true,
            category: AndroidNotificationCategory.stopwatch,
          ),
        ),
      );
    } catch (_) {
      // Nothing to do: the on-screen timer still works.
    }
  }

  /// Replaces the live countdown with the alert that rest is over.
  ///
  /// Used when the app is still running as the timer reaches zero, which is the
  /// common case. [scheduleRestOver] covers the case where it isn't.
  Future<void> notifyRestOver({
    required String exerciseName,
    required bool vibrate,
  }) async {
    try {
      await _ensureReady();
      // Drop the backstop alarm first, so it can't buzz a second time for a
      // rest that has already been announced.
      await _plugin.cancel(id: restTimerNotificationId);
      await _plugin.show(
        id: restTimerNotificationId,
        title: 'Rest over',
        body: 'Next set of $exerciseName',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            restTimerDoneChannelId,
            'Rest timer',
            channelDescription: 'Tells you when a rest between sets is over.',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: vibrate,
            category: AndroidNotificationCategory.alarm,
            // This one is finished business, so it behaves like a normal
            // notification: swipeable, and gone once tapped.
            timeoutAfter: 60000,
          ),
          iOS: _darwinAlert,
        ),
      );
    } catch (_) {
      // Nothing to do: the on-screen timer still works.
    }
  }

  /// Schedules the same alert via an alarm, as a backstop.
  ///
  /// Only matters if this app's process is frozen or killed before the rest
  /// ends — otherwise [notifyRestOver] gets there first and cancels this.
  ///
  /// Uses an inexact schedule on purpose. An exact alarm would need
  /// `SCHEDULE_EXACT_ALARM`, which Android 13+ makes the user grant by hand and
  /// Play restricts to genuine alarm-clock apps — too much friction, and a real
  /// risk at review time, for a rest timer.
  ///
  /// This needs `ScheduledNotificationReceiver` declared in the app's
  /// `AndroidManifest.xml`. Without it Android fires the alarm into nothing and
  /// no notification ever appears, silently.
  Future<void> scheduleRestOver({
    required int seconds,
    required String exerciseName,
    required bool vibrate,
  }) async {
    try {
      await _ensureReady();
      await _plugin.zonedSchedule(
        id: restTimerNotificationId,
        title: 'Rest over',
        body: 'Next set of $exerciseName',
        scheduledDate: tz.TZDateTime.now(
          tz.local,
        ).add(Duration(seconds: seconds)),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            restTimerDoneChannelId,
            'Rest timer',
            channelDescription: 'Tells you when a rest between sets is over.',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: vibrate,
            timeoutAfter: 60000,
            category: AndroidNotificationCategory.alarm,
          ),
          // On iOS this is the *only* rest notification — there's no live
          // countdown to replace, so it carries the whole feature there.
          iOS: _darwinAlert,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Nothing to do: the on-screen timer still works.
    }
  }

  /// Clears the notification and any pending alarm — the user skipped ahead,
  /// stopped the timer, or finished the workout.
  Future<void> cancelRestOver() async {
    try {
      await _ensureReady();
      await _plugin.cancel(id: restTimerNotificationId);
    } catch (_) {
      // Already gone, or notifications aren't available. Either is fine.
    }
  }
}

/// App-wide access to the [NotificationService].
@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  return NotificationService(FlutterLocalNotificationsPlugin());
}
