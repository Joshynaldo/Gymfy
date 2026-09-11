import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/data/notification_service.dart';
import '../../settings/data/notification_preferences.dart';
import 'rest_timer_repository.dart';

part 'rest_timer_controller.g.dart';

/// A rest countdown in progress.
typedef RestTimerState = ({
  String exerciseId,
  String exerciseName,

  /// What the timer was started with, so the bar can show progress.
  int totalSeconds,

  /// Seconds left. Reaches zero and stays there until dismissed, so the bar can
  /// say "rest over" rather than vanishing the moment it finishes.
  int remainingSeconds,
});

/// The one rest timer.
///
/// Deliberately app-wide and single: you rest between sets of one exercise at a
/// time, and two countdowns at once would be a bug rather than a feature.
/// Starting a new one replaces whatever was running, notification included.
///
/// Null means no timer is running.
///
/// The countdown is driven from a wall-clock deadline rather than by counting
/// ticks, so a dropped or throttled tick — which is exactly what happens when
/// the screen sleeps mid-set — can't make the timer drift slow.
@Riverpod(keepAlive: true)
class RestTimer extends _$RestTimer {
  Timer? _ticker;
  DateTime? _deadline;

  @override
  RestTimerState? build() {
    ref.onDispose(_stopTicker);
    return null;
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Whether the user wants rest-timer notifications at all. Covers both the
  /// live countdown in the shade and the alert when it finishes — one setting,
  /// because they're one notification that changes as the rest ends.
  bool get _notificationsOn => ref.read(restTimerAlertsProvider).value ?? true;

  bool get _vibrate => ref.read(restTimerVibrateProvider).value ?? true;

  /// Puts the live countdown in the shade and arms the backstop alarm.
  ///
  /// Both, because they cover different failures: the countdown is drawn by
  /// Android and stays correct even if this app is frozen, but it can't make a
  /// sound when it reaches zero. The alarm can, if the app isn't running by
  /// then to do it itself.
  Future<void> _showRest({
    required String exerciseName,
    required int seconds,
  }) async {
    // Everything off `ref` is read up front, before any await. `adjust` calls
    // this without waiting for it, so the provider can be disposed part-way
    // through — reading `ref` after that gap throws.
    final notifications = ref.read(notificationServiceProvider);
    final wanted = _notificationsOn;
    final vibrate = _vibrate;

    // Clear whatever was there first: without this, stopping one timer and
    // starting another could leave the old alarm to fire.
    await notifications.cancelRestOver();
    if (!wanted) return;
    await notifications.showRestRunning(
      seconds: seconds,
      exerciseName: exerciseName,
    );
    await notifications.scheduleRestOver(
      seconds: seconds,
      exerciseName: exerciseName,
      vibrate: vibrate,
    );
  }

  /// Starts (or restarts) a rest countdown for one exercise.
  Future<void> start({
    required String exerciseId,
    required String exerciseName,
    required int seconds,
  }) async {
    final total = clampRestSeconds(seconds);
    _stopTicker();
    _deadline = DateTime.now().add(Duration(seconds: total));
    state = (
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      totalSeconds: total,
      remainingSeconds: total,
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());

    await _showRest(exerciseName: exerciseName, seconds: total);
  }

  void _tick() {
    final current = state;
    final deadline = _deadline;
    if (current == null || deadline == null) {
      _stopTicker();
      return;
    }

    final remaining = deadline.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _stopTicker();
      state = (
        exerciseId: current.exerciseId,
        exerciseName: current.exerciseName,
        totalSeconds: current.totalSeconds,
        remainingSeconds: 0,
      );
      // We're still running, so announce it ourselves rather than leaving it to
      // the alarm — immediate and reliable, where an inexact alarm can lag.
      // This also cancels the alarm, so it can't buzz again a moment later.
      if (_notificationsOn) {
        ref
            .read(notificationServiceProvider)
            .notifyRestOver(
              exerciseName: current.exerciseName,
              vibrate: _vibrate,
            );
      }
      return;
    }
    state = (
      exerciseId: current.exerciseId,
      exerciseName: current.exerciseName,
      totalSeconds: current.totalSeconds,
      remainingSeconds: remaining,
    );
  }

  /// Adds (or with a negative [delta], removes) time from a running timer.
  ///
  /// Extends the total as well as the remaining time, so the progress bar stays
  /// honest instead of jumping backwards.
  void adjust(int delta) {
    final current = state;
    final deadline = _deadline;
    if (current == null || deadline == null) return;

    final remaining = deadline.difference(DateTime.now()).inSeconds + delta;
    if (remaining <= 0) {
      // Adjusting down past zero means "I'm done resting".
      stop();
      return;
    }
    _deadline = DateTime.now().add(Duration(seconds: remaining));
    state = (
      exerciseId: current.exerciseId,
      exerciseName: current.exerciseName,
      totalSeconds: current.totalSeconds + delta,
      remainingSeconds: remaining,
    );

    // Both the shade countdown and the alarm were set against the old deadline.
    _showRest(exerciseName: current.exerciseName, seconds: remaining);
  }

  /// Clears the timer and any pending notification.
  void stop() {
    _stopTicker();
    _deadline = null;
    state = null;
    ref.read(notificationServiceProvider).cancelRestOver();
  }
}
