// Turning an imported history into a split you can actually train from.
//
// Importing a file gives you your past — the year activity fills in, the
// charts have data, the personal records are right. What it does not give you
// is your *programme*: Gymfy plans training as a Split of WorkoutDays, and a
// CSV of performed sets contains no such thing. So after importing, the app
// knew everything about your training except what to do on Monday, and the
// only way to get there was to retype eight days of exercises by hand.
//
// This file reads the plan back out of the history. Every workout name in the
// file becomes a day; the exercises that day is actually built from become its
// planned exercises, with the set and rep targets they were actually trained
// at.
//
// Two rules do most of the work, and both exist to keep one-off sessions out
// of the plan:
//
//   - Only the most recent [recentSessions] of each day are read. A day
//     trained forty times over two years has almost certainly changed, and the
//     plan should be what you are doing now, not the average of everything you
//     have ever done.
//   - An exercise has to appear in at least half of those to make the cut. The
//     machine you used once because your bench was taken is not part of your
//     programme.
//
// Nothing here touches the database, so all of it is testable as plain
// functions — which matters, because "is this the right plan?" is a question
// about arithmetic, not about drift.

import 'import_format.dart';

/// The longest a [Splits] or [WorkoutDays] name may be — both columns are
/// `text().withLength(min: 1, max: 60)`, and drift raises on the way in rather
/// than truncating. A workout name out of somebody else's app is not bound by
/// that, so everything built here is cut to fit.
const planNameLimit = 60;

/// How many of a day's most recent sessions are read.
///
/// Eight is roughly two months of a twice-weekly day: long enough that one
/// improvised session cannot carry a vote, short enough that a programme
/// changed in the spring does not still show through in the autumn.
const defaultRecentSessions = 8;

/// What to call a split built out of an import.
///
/// Names the app it came from when the header said so, because "Hevy import"
/// sitting in the split list a month later still explains itself, and "My
/// split 2" does not. [source] is [WorkoutImport.source].
String defaultSplitName(String? source) =>
    source == null ? 'Imported split' : '$source import';

/// One planned exercise, with the targets its history suggests.
class PlannedSlot {
  const PlannedSlot({
    required this.exerciseName,
    required this.sets,
    required this.warmupSets,
    required this.reps,
  });

  /// As the file spelled it. Matched against the library by the caller, using
  /// the same name matching the rest of the import uses.
  final String exerciseName;

  /// Working sets, the typical number for this exercise on this day.
  final int sets;

  /// Ramp-up sets, likewise. Zero unless the file marked warm-ups — most do
  /// not, and inventing them would put "Warm-up 1 of 3" in front of a cable
  /// curl.
  final int warmupSets;

  /// The target reps, the middle of what was actually performed.
  ///
  /// No rep *range* is derived. The scatter of a real exercise across eight
  /// sessions is 6–14 as often as it is 8–12, and a range read off that is
  /// noise wearing the costume of a plan. One number is honest, and the day
  /// screen sets a range for the whole day in two taps.
  final int reps;
}

/// One day of a plan built from an imported history.
class PlannedDay {
  const PlannedDay({
    required this.name,
    required this.sessionCount,
    required this.weekdays,
    required this.exercises,
  });

  /// The workout name from the file, cut to [planNameLimit].
  final String name;

  /// How many sessions in the file carried this name. Shown in the preview,
  /// because "Push — 21 workouts" is what tells someone the day is real — and
  /// "Saturday Evening: Machine Shoulder Press — 1 workout" is what tells them
  /// the next row is not.
  final int sessionCount;

  /// The weekdays this day is actually trained on, ISO-8601 (1 = Monday),
  /// strongest first. Empty when the history is too scattered to say.
  ///
  /// Derived rather than left blank because of what a blank costs: a split
  /// with no weekday scheduled anywhere is active but invisible, and the Home
  /// tab answers "Rest day — nothing scheduled" every day of the week, with no
  /// button on it. The history knows the answer — the real Hevy export trains
  /// "Upper Day (Freitags)" on a Friday eight times out of eight.
  final List<int> weekdays;

  final List<PlannedSlot> exercises;
}

/// The share of a day's sessions a weekday needs before it counts as that
/// day's slot.
///
/// Two fifths, so that a day genuinely trained twice a week — Push on Monday
/// and Thursday, which is what a six-day split does — keeps both, while a
/// single session that landed on a Sunday because of a holiday keeps none.
const weekdayShare = 0.4;

/// The plan a whole import would make, or nothing when it would make none.
///
/// The gate is [WorkoutImport.namesWorkouts]: a file with no workout-name
/// column labels every session "Imported workout", and a split built from that
/// would be one day holding every lift the person has ever done. Asked here so
/// the preview, the button and the writer all agree about whether there is a
/// split to build.
List<PlannedDay> planForImport(
  WorkoutImport import, {
  int recentSessions = defaultRecentSessions,
}) {
  if (!import.namesWorkouts) return const [];
  return planFromSessions(import.sessions, recentSessions: recentSessions);
}

/// Reads a plan out of imported sessions.
///
/// Returns one [PlannedDay] per distinct workout name, ordered by how recently
/// that day was last trained — newest first, so the day you did yesterday is
/// at the top of the split rather than buried under one you dropped in March.
///
/// Days that yield no exercises at all are left out rather than created empty:
/// an empty day in a split is a dead end the user has to notice and delete.
List<PlannedDay> planFromSessions(
  List<ImportedSession> sessions, {
  int recentSessions = defaultRecentSessions,
}) {
  // Grouped by name. Case and surrounding space are ignored, because "Push "
  // and "push" out of the same file are one day and splitting them would give
  // the user two half-populated ones.
  final byName = <String, List<ImportedSession>>{};
  final spelling = <String, String>{};

  for (final session in sessions) {
    final name = session.name.trim();
    if (name.isEmpty) continue;

    final key = name.toLowerCase();
    // The first spelling seen wins, which — since sessions arrive oldest
    // first — is the one they have been using longest.
    spelling.putIfAbsent(key, () => name);
    byName.putIfAbsent(key, () => []).add(session);
  }

  final days = <PlannedDay>[];

  for (final entry in byName.entries) {
    final all = entry.value..sort((a, b) => a.start.compareTo(b.start));
    final recent = all.length <= recentSessions
        ? all
        : all.sublist(all.length - recentSessions);

    final exercises = _slotsFor(recent);
    if (exercises.isEmpty) continue;

    days.add(
      PlannedDay(
        name: fitPlanName(spelling[entry.key]!),
        sessionCount: all.length,
        weekdays: _weekdaysFor(recent),
        exercises: exercises,
      ),
    );
  }

  // Newest-trained day first. Ties broken by name so the result is stable —
  // two days last trained in the same session would otherwise come out in
  // whatever order the map iterated.
  final lastTrained = {
    for (final entry in byName.entries)
      fitPlanName(spelling[entry.key]!): entry.value
          .map((s) => s.start)
          .reduce((a, b) => a.isAfter(b) ? a : b),
  };
  days.sort((a, b) {
    final byDate = lastTrained[b.name]!.compareTo(lastTrained[a.name]!);
    return byDate != 0 ? byDate : a.name.compareTo(b.name);
  });

  return days;
}

/// The weekdays a day is actually trained on, strongest claim first.
List<int> _weekdaysFor(List<ImportedSession> sessions) {
  final counts = <int, int>{};
  for (final session in sessions) {
    counts[session.start.weekday] = (counts[session.start.weekday] ?? 0) + 1;
  }

  final needed = sessions.length * weekdayShare;
  final kept = counts.entries.where((e) => e.value >= needed).toList()
    // Strongest first, and the earlier weekday wins a tie so the result does
    // not depend on which order the map happened to iterate in.
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });

  // Three at most. A "day" claiming four weekdays is not a schedule, it is a
  // history that never settled — and filling the calendar with it would bury
  // every other day of the split.
  return [for (final entry in kept.take(3)) entry.key];
}

/// The exercises a day is actually built from, in the order they are trained.
List<PlannedSlot> _slotsFor(List<ImportedSession> sessions) {
  // Per exercise: the sessions it appeared in, its working-set count and
  // warm-up count in each of them, every working rep, and where in the session
  // it sat. Keyed by the name as written — matching to the library happens
  // later, once, in the repository.
  final appearances = <String, int>{};
  final workingCounts = <String, List<int>>{};
  final warmupCounts = <String, List<int>>{};
  final reps = <String, List<int>>{};
  final positions = <String, List<int>>{};
  final order = <String>[];

  for (final session in sessions) {
    final seen = <String>[];

    for (final set in session.sets) {
      final name = set.exerciseName;
      if (!appearances.containsKey(name)) {
        appearances[name] = 0;
        workingCounts[name] = [];
        warmupCounts[name] = [];
        reps[name] = [];
        positions[name] = [];
        order.add(name);
      }
      if (!seen.contains(name)) {
        seen.add(name);
        appearances[name] = appearances[name]! + 1;
        // Where this exercise came in the session, counted in exercises
        // rather than sets so a lift with five sets does not push everything
        // after it down the order.
        positions[name]!.add(seen.length - 1);
        workingCounts[name]!.add(0);
        warmupCounts[name]!.add(0);
      }

      if (set.isWarmup) {
        warmupCounts[name]!.last += 1;
      } else {
        workingCounts[name]!.last += 1;
        // A set logged by time has no reps to average; it is still a working
        // set and still counts toward the set total.
        if (set.reps > 0) reps[name]!.add(set.reps);
      }
    }
  }

  // At least half the sessions, rounded up: with one session everything is
  // in, with eight an exercise needs four.
  final threshold = (sessions.length + 1) ~/ 2;

  final kept = order.where((name) => appearances[name]! >= threshold).toList();

  // Ordered by where each exercise typically sits in the session, so the day
  // reads the way it is trained rather than alphabetically. Ties keep the
  // order they were first seen in.
  kept.sort((a, b) {
    final byPosition = _median(positions[a]!).compareTo(_median(positions[b]!));
    return byPosition != 0
        ? byPosition
        : order.indexOf(a).compareTo(order.indexOf(b));
  });

  return [
    for (final name in kept)
      PlannedSlot(
        exerciseName: name,
        // Never zero: an exercise that reached this list was trained, and a
        // day planning "0 sets" of something is not a plan.
        sets: _median(workingCounts[name]!).clamp(1, 20),
        warmupSets: _median(warmupCounts[name]!).clamp(0, 10),
        // Ten is the app's own default, used when every set of this exercise
        // was logged by time and there are no reps to take a middle of.
        reps: reps[name]!.isEmpty ? 10 : _median(reps[name]!).clamp(1, 100),
      ),
  ];
}

/// The middle value, rounding a two-sided tie up.
///
/// A median rather than a mean, because one session where you were short of
/// time and did two sets instead of four should not drag the target to three.
int _median(List<int> values) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[middle];
  // Rounded up rather than down: between planning four sets and five for a
  // day that has done both, the higher one is the one you can cut short.
  return ((sorted[middle - 1] + sorted[middle]) / 2).ceil();
}

/// A name cut to what the column will accept.
///
/// Cut rather than rejected: a workout called something long is still that
/// workout, and refusing the whole import over a title is not a trade anyone
/// would choose. The ellipsis is there so a truncated name looks deliberate
/// rather than like a bug.
String fitPlanName(String name) {
  final trimmed = name.trim();
  if (trimmed.length <= planNameLimit) return trimmed;

  // Dart counts UTF-16 code units, and an emoji is two of them. Cutting
  // between the halves of a surrogate pair leaves a lone surrogate, which
  // renders as a replacement box — so back off one unit when the cut lands
  // inside a character.
  var cut = planNameLimit - 1;
  final unit = trimmed.codeUnitAt(cut - 1);
  if (unit >= 0xd800 && unit <= 0xdbff) cut -= 1;

  return '${trimmed.substring(0, cut).trimRight()}…';
}
