import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
});

/// No workout — what the watch shows when nothing is happening.
const idleWearWorkout = (
  active: false,
  workout: '',
  exercise: '',
  sets: '',
  restEndsAtMs: 0,
  restTotalSeconds: 0,
);

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
