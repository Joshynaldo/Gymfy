import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../l10n/app_language.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/utils/units.dart';
import '../../settings/data/notification_preferences.dart';
import '../../wear/data/wear_bridge.dart';
import '../../wear/data/wear_sync.dart';
import '../../workout/data/next_set.dart';
import '../../workout/data/rest_timer_controller.dart';
import '../../workout/data/session_repository.dart';

part 'workout_notification.g.dart';

// The running workout as an ongoing notification: which exercise, which set,
// the rest countdown, and buttons to log the set and steer the rest without
// unlocking the phone.
//
// Built the way the watch is. Dart decides every word and Kotlin draws them
// (android/.../WorkoutNotification.kt), and the buttons send the same command
// strings the watch sends, into the same handler (WearCommands) — so a set
// logged from the shade and one logged from the wrist cannot behave
// differently, and neither can behave differently from the app.
//
// Every word includes the buttons' and the channel's, so they follow the
// app's language rather than the phone's: Kotlin only has an English
// fallback for the moment before Dart has sent anything.

/// What the notification says. Null content means "no notification".
typedef WorkoutNotificationContent = ({
  /// The workout's name.
  String title,

  /// One line: the exercise and the set, e.g. "Bench Press · Set 3 of 4".
  String text,

  /// The expanded view: [text] and what one tap on "Log set" will log. Empty
  /// when there is nothing to add.
  String bigText,

  /// A word in the header beside the countdown, e.g. "Resting".
  String subText,

  /// When the rest ends, as whole-second epoch milliseconds, or zero.
  ///
  /// A deadline, like the watch's, because the *system* counts down to it:
  /// Android renders the chronometer, so it keeps moving while this app is
  /// frozen in the background. A count pushed from Dart would stop the moment
  /// the process did.
  int restEndsAtMs,

  /// What "Log set" sends, or empty for no button. See [WearBridge.logSetCommand].
  String logCommand,

  /// The words Kotlin puts on the buttons, on the notification once the app
  /// has gone, and on the channel in the system settings.
  WorkoutNotificationLabels labels,
});

/// The notification's fixed words, in one language.
typedef WorkoutNotificationLabels = ({
  String logSet,
  String skipRest,
  String tapToOpen,
  String channelName,
  String channelDescription,
});

/// The fixed words in [l10n]'s language.
WorkoutNotificationLabels workoutNotificationLabels(AppLocalizations l10n) => (
  logSet: l10n.workoutNotificationLogSet,
  skipRest: l10n.workoutNotificationSkipRest,
  tapToOpen: l10n.workoutNotificationTapToOpen,
  channelName: l10n.workoutNotificationChannel,
  channelDescription: l10n.workoutNotificationChannelDescription,
);

/// Builds the notification for the workout that is running, or null for none.
///
/// Pure, like the watch payload, so what it says is testable without a
/// platform channel. [logId] goes into the "Log set" command and is what
/// makes a double tap one set; the caller mints a new one whenever the rest
/// of the content changes.
///
/// Worded in [l10n]'s language, English without it.
WorkoutNotificationContent? workoutNotificationFrom({
  required WorkoutSession? session,
  required NextSet? next,
  required RestTimerState? rest,
  required DateTime now,
  required WeightUnit unit,
  required String logId,
  AppLocalizations? l10n,
}) {
  if (session == null) return null;

  final strings = l10n ?? englishLocalizations;
  final endsAt = restDeadlineMs(rest, now);
  final text = next == null
      // A free workout before its first exercise: nothing to log yet, and
      // the notification says so rather than showing a blank line.
      ? strings.workoutNotificationNoExercises
      : '${next.exerciseName} · ${describeSetPosition(next, l10n: l10n)}';

  // Only a set worth logging blind gets the button, and only then are its
  // numbers spelled out: "Next: 0 kg × 10 reps" for a squat you have never
  // done would be a placeholder dressed up as advice. See NextSet.confident.
  final loggable = next != null && next.confident;

  return (
    title: session.name,
    text: text,
    bigText: loggable
        ? '$text\n'
              '${strings.workoutNotificationNext(describeNextNumbers(next, unit, l10n: l10n))}'
        : '',
    subText: endsAt > 0 ? strings.workoutNotificationResting : '',
    restEndsAtMs: endsAt,
    logCommand: loggable
        ? WearBridge.logSetCommand(
            id: logId,
            exerciseId: next.exerciseId,
            // Kilograms, as stored, so nothing is converted on the way back.
            weight: next.weightKg,
            unit: WeightUnit.kg,
            reps: next.seconds == null ? next.reps : null,
            seconds: next.seconds,
          )
        : '',
    labels: workoutNotificationLabels(strings),
  );
}

/// Shows and clears the notification, through the watch's platform channel.
///
/// The same channel on purpose: the buttons answer through it (as
/// [WearBridge.commandMethod] calls), and one hand-written channel is less to
/// keep in step than two.
class WorkoutNotificationBridge {
  const WorkoutNotificationBridge(this._channel);

  final MethodChannel _channel;

  static const showMethod = 'showWorkoutNotification';
  static const clearMethod = 'clearWorkoutNotification';

  /// Whether this platform has the notification at all. Android only: the
  /// countdown it carries is a system chronometer, which iOS has no
  /// equivalent of (the same reason the rest timer posts none there).
  static bool get supported => WearBridge.supported;

  /// Posts or updates the notification, and says whether it is on screen.
  ///
  /// Never throws, and quietly does nothing without notification permission
  /// or with its channel switched off (both checked on the Kotlin side) — the
  /// app works the same without it. False then, and on every platform
  /// without the bridge.
  Future<bool> show(WorkoutNotificationContent content) async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>(showMethod, {
            'title': content.title,
            'text': content.text,
            'bigText': content.bigText,
            'subText': content.subText,
            'restEndsAtMs': content.restEndsAtMs,
            'logCommand': content.logCommand,
            'logLabel': content.labels.logSet,
            'skipRestLabel': content.labels.skipRest,
            'tapToOpenLabel': content.labels.tapToOpen,
            'channelName': content.labels.channelName,
            'channelDescription': content.labels.channelDescription,
          }) ??
          false;
    } on PlatformException {
      // Best effort, like everything on this channel.
      return false;
    } on MissingPluginException {
      // No host implementation — a test, or a platform without the bridge.
      return false;
    }
  }

  /// Removes the notification. Safe to call when there is none.
  Future<void> clear() async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>(clearMethod);
    } on PlatformException {
      // As above.
    } on MissingPluginException {
      // As above.
    }
  }
}

@Riverpod(keepAlive: true)
WorkoutNotificationBridge workoutNotificationBridge(Ref ref) =>
    const WorkoutNotificationBridge(WearBridge.channel);

/// Keeps the notification in step with the workout.
///
/// Updates when a set is logged, the exercise changes, a rest starts, is
/// extended or ends, and removes the notification when the workout is
/// finished or discarded (the in-progress session goes away either way) or
/// the setting is switched off.
///
/// Kept alive from the app root for the same reason as [WearSync]: it is
/// needed most when every screen is gone.
@Riverpod(keepAlive: true)
class WorkoutNotificationSync extends _$WorkoutNotificationSync {
  /// What was last sent, so an unchanged state is not sent again. The rest
  /// timer rebuilds this every second; the deadline it produces does not
  /// move, so neither does this.
  WorkoutNotificationContent? _shown;

  /// The content as last computed with no log id, to tell a real change from
  /// a repeat of the same state.
  WorkoutNotificationContent? _basis;

  String _logId = '';
  int _minted = 0;

  /// Whether the last thing sent was a clear. Starts false so the first
  /// build with nothing to show clears once — a notification left behind by
  /// a process that died mid-workout is not this process's to keep.
  bool _cleared = false;

  bool _posted = false;

  /// Whether the notification is actually on screen, as far as Android last
  /// said — not merely wanted. Without permission, or with its channel
  /// switched off in the system settings, it is not, and the rest timer then
  /// keeps its own countdown rather than leaving the shade with none.
  bool get posted => _posted && _shown != null;

  @override
  WorkoutNotificationContent? build() {
    final enabled = ref.watch(workoutNotificationProvider);
    final session = ref.watch(inProgressSessionProvider);
    // Nothing is decided until both are known, so a user who switched this
    // off never sees it flash up while the setting loads.
    if (!enabled.hasValue || !session.hasValue) return _shown;

    final running = session.value;
    if (enabled.value != true || running == null) {
      _hide();
      return null;
    }

    final nextAsync = ref.watch(nextSetProvider(running.id));
    // The first answer only; a reload keeps showing the previous one.
    if (nextAsync.isLoading && !nextAsync.hasValue) return _shown;

    final rest = ref.watch(restTimerProvider);
    final unit = ref.watch(weightUnitProvider);
    // Watched, so switching the app's language re-posts the notification in
    // the new one instead of leaving the old words in the shade.
    final l10n = ref.watch(appLocalizationsProvider);
    final now = clock.now();

    WorkoutNotificationContent? contentWith(String logId) =>
        workoutNotificationFrom(
          session: running,
          next: nextAsync.value,
          rest: rest,
          now: now,
          unit: unit,
          logId: logId,
          l10n: l10n,
        );

    // A new log id for every new state, and only then. The button's
    // PendingIntent keeps its id until the notification is replaced, so two
    // taps on one notification send one id twice — and WearCommands applies
    // it once. Once the set lands the content changes and the next tap
    // carries a fresh id; a second tap that lands just after that re-post is
    // caught by WearCommands too, by the prefix (see shadeDoubleTapWindow).
    final basis = contentWith('');
    if (basis != _basis) {
      _basis = basis;
      _logId =
          '$shadeLogIdPrefix${clock.now().microsecondsSinceEpoch}-${_minted++}';
    }

    final content = contentWith(_logId)!;
    if (content != _shown) {
      _shown = content;
      _cleared = false;
      _send(content);
    }
    return content;
  }

  void _send(WorkoutNotificationContent content) {
    ref
        .read(workoutNotificationBridgeProvider)
        .show(content)
        .then((onScreen) => _posted = onScreen);
  }

  void _hide() {
    _basis = null;
    _shown = null;
    _posted = false;
    if (_cleared) return;
    _cleared = true;
    ref.read(workoutNotificationBridgeProvider).clear();
  }

  /// Sends the current notification again.
  ///
  /// For right after notification permission is granted: until then every
  /// post was dropped on the Kotlin side, and the state has not changed, so
  /// nothing else would send it.
  void resend() {
    final content = _shown;
    if (content != null) _send(content);
  }
}
