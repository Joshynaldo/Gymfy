import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/dates.dart';

/// Today's date, at midnight — for what changes with the calendar rather than
/// with the data: the week a weekly goal counts, the days left to a deadline.
///
/// Nothing in the database moves at midnight, so a provider kept alive for
/// the app's lifetime that only watched the data would go on answering for
/// the day it was built on. Watching this makes it answer again on a new day.
///
/// Moved on by [currentDayWatcherProvider] when the app comes back to the
/// foreground. No timer to midnight: the case that matters is Gymfy left in
/// the background overnight, which comes back through a resume, and a timer
/// hours long in a provider kept for the app's life would still be pending
/// at the end of every widget test that boots the app. An app left open on
/// screen across midnight catches up at its next resume.
final currentDayProvider = NotifierProvider<CurrentDay, DateTime>(
  CurrentDay.new,
);

/// Holds [currentDayProvider]'s date.
class CurrentDay extends Notifier<DateTime> {
  @override
  DateTime build() => dateOnly(clock.now());

  /// Moves on to today, if the date has changed since it was last read.
  /// Telling no one when it has not, so a resume between sets — phone down,
  /// phone up — rebuilds nothing.
  void check() {
    final today = dateOnly(clock.now());
    if (today != state) state = today;
  }
}

/// Checks [currentDayProvider] each time the app comes back to the
/// foreground.
///
/// Watched from the app root, like the other watchers there, and kept apart
/// from the date itself because listening needs the widgets binding, which
/// the code reading the date (and its tests) has no need of.
final currentDayWatcherProvider = Provider<void>((ref) {
  final listener = AppLifecycleListener(
    onResume: () => ref.read(currentDayProvider.notifier).check(),
  );
  ref.onDispose(listener.dispose);
});
