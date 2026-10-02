import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/utils/units.dart';

part 'wear_bridge.g.dart';

/// What the watch is told about the current workout.
///
/// Formatted strings, not model objects. The rule that made the home-screen
/// widgets work — and the one thing worth keeping from that deleted phase —
/// is that **the other side never reads the database**: Dart decides what the
/// words are, and the Kotlin on the watch renders them without knowing what a
/// set, a unit or a schema version is.
///
/// The cost is that the watch shows the last state that was *pushed* rather
/// than the truth as of this millisecond. For a thing you glance at between
/// sets that is the right trade; the alternative is schema knowledge in two
/// languages, kept in step by hand.
typedef WearWorkout = ({
  /// Whether a workout is running at all. False blanks the watch face rather
  /// than leaving yesterday's session sitting there looking current.
  bool active,

  /// The session's name, e.g. "Push A".
  String workout,

  /// The exercise the rest timer belongs to, or empty when nothing is resting.
  String exercise,

  /// Ready-to-draw line about the set count, e.g. "12 sets logged".
  String sets,

  /// When the current rest ends, as epoch milliseconds. Zero when no timer.
  ///
  /// A deadline, deliberately, rather than a seconds-remaining count. Pushing
  /// a new value every second would mean a Data Layer write per second for
  /// the length of every rest — on two batteries — and it would still be
  /// wrong the moment the watch missed one. Given the deadline the watch
  /// counts down on its own, stays right while disconnected, and needs one
  /// message per timer instead of ninety.
  int restEndsAtMs,

  /// What the rest was started with, so the watch can draw a progress ring.
  int restTotalSeconds,

  /// The last working set, ready to draw, e.g. "80 kg x 8".
  ///
  /// Empty when there is nothing to repeat. Formatted here for the same
  /// reason as everything else: the watch does not know what a unit is.
  String lastSet,

  // The next set, for logging from the wrist. The numbers below are the one
  // place the payload carries numbers rather than words, because the watch
  // has to *change* them with + and -; everything about what they mean —
  // which unit, how big a step, whether it counts reps or seconds — is still
  // decided here and sent along with them.

  /// The exercise the next set belongs to — the one the phone's card is on.
  ///
  /// Empty when there is nothing to log, which is also how the watch decides
  /// whether to offer logging at all. A phone on an older build never sends
  /// it, and the watch falls back to the repeat button.
  String nextExercise,

  /// Its id, opaque to the watch and sent back with a log, so the set lands
  /// on the exercise that was on the wrist even if the phone has moved on.
  String nextExerciseId,

  /// Ready to draw: "Set 3 of 4".
  String nextSet,

  /// The suggested weight, already in [weightUnit] and already rounded to
  /// something loadable — the watch never converts anything.
  double nextWeight,

  /// The suggested reps, or the hold in seconds when [nextTimed].
  int nextReps,

  /// Whether [nextReps] is a hold in seconds rather than a rep count.
  bool nextTimed,

  /// "kg" or "lbs": the label beside the weight, and echoed back with a log
  /// so the phone knows which unit the number is in.
  String weightUnit,

  /// How far one press of + or - (or one crown step) moves the weight, in
  /// [weightUnit].
  double weightStep,

  /// What the watch writes between the whole and the fraction of
  /// [nextWeight]: "." in English, "," in German — the phone app's language,
  /// like every line the phone words, so "82,5 kg" on the phone is not
  /// "82.5 kg" on the wrist. A watch paired with a phone on an older build
  /// never gets it and writes a dot.
  String decimalSeparator,
});

/// No workout — what the watch shows when nothing is happening.
const idleWearWorkout = (
  active: false,
  workout: '',
  exercise: '',
  sets: '',
  restEndsAtMs: 0,
  restTotalSeconds: 0,
  lastSet: '',
  nextExercise: '',
  nextExerciseId: '',
  nextSet: '',
  nextWeight: 0.0,
  nextReps: 0,
  nextTimed: false,
  weightUnit: '',
  weightStep: 0.0,
  decimalSeparator: '.',
);

/// One "log this set" request, as it arrived — not yet checked against the
/// workout. See [WearBridge.parseLogSet].
typedef RemoteSetRequest = ({
  /// Caller-generated, applied at most once. See [WearBridge.commandLogSet].
  String id,
  String exerciseId,

  /// In [unit], as shown where the button was pressed.
  double weight,
  WeightUnit unit,

  /// Exactly one of these is set: reps for a counted set, seconds for a hold.
  int? reps,
  int? seconds,
});

/// Sends workout state to the Wear OS companion.
///
/// A hand-written platform channel rather than a pub package. This project
/// has already lost days to plugins that pin their own Gradle versions
/// (`share_plus` x `file_picker` x AGP 9) and is past release; the entire
/// surface needed here is one method call, which is less code than the
/// dependency would be risk. Same reasoning as the hand-written CSV reader.
class WearBridge {
  const WearBridge(this._channel);

  final MethodChannel _channel;

  static const channel = MethodChannel('de.kopten.gymfy/wear');

  /// Whether this platform has a watch companion at all.
  ///
  /// Checked rather than attempted: on iOS, desktop and in tests the channel
  /// has no handler, and every call would throw a MissingPluginException to
  /// be swallowed somewhere. Better to not call it.
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// The method commands arrive on, from the watch and from the buttons on
  /// the ongoing workout notification alike — one door, one handler.
  static const commandMethod = 'watchCommand';

  /// Commands the watch can send back.
  ///
  /// A closed set of strings rather than anything structured, and kept
  /// small on purpose: every one of these is a thing the wrist can do to
  /// the phone without looking at it, so the cost of getting one wrong is a
  /// rest that silently ends. Both sides read the same names — pinned by
  /// `wear_bridge_test.dart`.
  static const commandAddThirty = 'rest.add30';
  static const commandSkipRest = 'rest.skip';

  /// Log another set identical to the last one.
  ///
  /// Carries a caller-generated id after a colon, and that id is the whole
  /// safety story: a double tap on a small screen is normal, and without it
  /// the second tap is an extra set in your history that you did not do.
  static const commandRepeatSet = 'set.repeat';

  /// Log one set with the numbers given.
  ///
  /// `set.log:` followed by a JSON object with the keys below: an id, the
  /// exercise, the weight and its unit, and exactly one of reps or seconds.
  /// JSON rather than more colons because an exercise id is the user's own
  /// text for a custom exercise, and a separator inside it would be read as
  /// a field boundary.
  ///
  /// The id does what it does for [commandRepeatSet]: it is applied at most
  /// once, so a double tap is one set.
  static const commandLogSet = 'set.log';

  static const logFieldId = 'id';
  static const logFieldExercise = 'exerciseId';
  static const logFieldWeight = 'weight';
  static const logFieldUnit = 'unit';
  static const logFieldReps = 'reps';
  static const logFieldSeconds = 'seconds';

  /// The [commandLogSet] command for one set. The watch builds the same
  /// string in Kotlin; the notification's "Log set" button carries this one.
  static String logSetCommand({
    required String id,
    required String exerciseId,
    required double weight,
    required WeightUnit unit,
    int? reps,
    int? seconds,
  }) {
    return '$commandLogSet:${jsonEncode({logFieldId: id, logFieldExercise: exerciseId, logFieldWeight: weight, logFieldUnit: unit.name, if (seconds != null) logFieldSeconds: seconds else logFieldReps: reps})}';
  }

  /// Reads the part of a [commandLogSet] command after the colon.
  ///
  /// Null for anything malformed — not JSON, a key missing or of the wrong
  /// type, an unknown unit, both or neither of reps and seconds. Malformed
  /// means a watch on a build that disagrees with this one, and the answer
  /// to that is to do nothing: a guessed set is worse than a missing one.
  ///
  /// Only the shape is checked here. Whether the numbers make sense for the
  /// exercise is the receiver's call, because only it knows the exercise.
  static RemoteSetRequest? parseLogSet(String argument) {
    final Object? decoded;
    try {
      decoded = jsonDecode(argument);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, Object?>) return null;

    final id = decoded[logFieldId];
    final exerciseId = decoded[logFieldExercise];
    final weight = decoded[logFieldWeight];
    final unitName = decoded[logFieldUnit];
    final reps = decoded[logFieldReps];
    final seconds = decoded[logFieldSeconds];

    if (id is! String || id.isEmpty) return null;
    if (exerciseId is! String || exerciseId.isEmpty) return null;
    if (weight is! num) return null;
    // Looked up by name rather than through WeightUnit.parse, which falls
    // back to kilograms: a unit nobody recognises read as kg would store a
    // pound weight 2.2 times too heavy.
    final unit = WeightUnit.values.where((u) => u.name == unitName).firstOrNull;
    if (unit == null) return null;
    if (reps != null && reps is! int) return null;
    if (seconds != null && seconds is! int) return null;
    if ((reps == null) == (seconds == null)) return null;

    return (
      id: id,
      exerciseId: exerciseId,
      weight: weight.toDouble(),
      unit: unit,
      reps: reps as int?,
      seconds: seconds as int?,
    );
  }

  /// Routes commands arriving from the watch (and the notification) to
  /// [onCommand].
  ///
  /// The returned future is awaited before the call is answered, and the
  /// Kotlin side holds the notification button's broadcast open until then:
  /// a tap that arrives while the app is frozen in the background only has
  /// the process for as long as that broadcast lasts, so it must not end
  /// before the set is written.
  ///
  /// Passing null clears the handler.
  void listen(Future<void> Function(String command)? onCommand) {
    if (!supported) return;
    if (onCommand == null) {
      _channel.setMethodCallHandler(null);
      return;
    }
    _channel.setMethodCallHandler((call) async {
      if (call.method == commandMethod) {
        final command = call.arguments;
        if (command is String) await onCommand(command);
      }
    });
  }

  /// Pushes [workout] to the watch.
  ///
  /// Never throws. A watch that is unpaired, switched off or out of range is
  /// the normal case, not an error — nothing on the phone should fail, or
  /// even show a message, because a wrist is missing.
  Future<void> push(WearWorkout workout) async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>('pushWorkout', {
        'active': workout.active,
        'workout': workout.workout,
        'exercise': workout.exercise,
        'sets': workout.sets,
        'restEndsAtMs': workout.restEndsAtMs,
        'restTotalSeconds': workout.restTotalSeconds,
        'lastSet': workout.lastSet,
        'nextExercise': workout.nextExercise,
        'nextExerciseId': workout.nextExerciseId,
        'nextSet': workout.nextSet,
        'nextWeight': workout.nextWeight,
        'nextReps': workout.nextReps,
        'nextTimed': workout.nextTimed,
        'weightUnit': workout.weightUnit,
        'weightStep': workout.weightStep,
        'decimalSeparator': workout.decimalSeparator,
        // So the watch can tell how old this is and say so, rather than
        // presenting a three-hour-old rest timer as live.
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      });
    } on PlatformException {
      // Delivery is best effort by design.
    } on MissingPluginException {
      // No host implementation — a test, or a platform without the bridge.
    }
  }
}

@Riverpod(keepAlive: true)
WearBridge wearBridge(Ref ref) => const WearBridge(WearBridge.channel);
