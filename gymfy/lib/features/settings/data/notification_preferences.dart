import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/settings_repository.dart';

/// Setting key: play an alert when a rest timer runs out.
const restTimerAlertsSetting = 'rest_timer_alerts';

/// Setting key: vibrate as well as alerting.
const restTimerVibrateSetting = 'rest_timer_vibrate';

/// Setting key: keep the running workout in an ongoing notification, with
/// buttons to log the next set and control the rest.
const workoutNotificationSetting = 'workout_notification';

/// Reads a stored on/off setting.
///
/// Only the exact strings `true` and `false` count. Anything else — unset, or a
/// value written by a build that stored flags differently — falls back to
/// [orElse] rather than guessing, so a preference nobody has touched behaves
/// like the documented default.
bool parseFlag(String? raw, {required bool orElse}) {
  return switch (raw) {
    'true' => true,
    'false' => false,
    _ => orElse,
  };
}

/// Builds a provider for one on/off setting.
///
/// The notification preferences are all the same shape, so they share one
/// factory rather than near-identical stream providers.
StreamProvider<bool> _flagProvider(String name, {required bool orElse}) {
  return StreamProvider<bool>((ref) {
    return ref
        .watch(settingsRepositoryProvider)
        .watchRaw(name)
        .map((raw) => parseFlag(raw, orElse: orElse));
  });
}

/// Whether rest timers alert when they finish. On unless turned off — a silent
/// timer is not much of a timer.
final restTimerAlertsProvider = _flagProvider(
  restTimerAlertsSetting,
  orElse: true,
);

/// Whether the alert vibrates too. On by default: a gym is loud, and a phone in
/// a pocket is the normal case.
final restTimerVibrateProvider = _flagProvider(
  restTimerVibrateSetting,
  orElse: true,
);

/// Whether a running workout shows its ongoing notification. On by default:
/// it is silent, it goes away with the workout, and it is the one way to log
/// a set with the phone locked.
final workoutNotificationProvider = _flagProvider(
  workoutNotificationSetting,
  orElse: true,
);

/// Writes an on/off setting.
Future<void> setFlag(WidgetRef ref, String name, bool value) {
  return ref.read(settingsRepositoryProvider).write(name, value.toString());
}
