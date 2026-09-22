// Writing an imported history into the database.
//
// Two decisions carry this file.
//
// The first is that an import must be *repeatable*. People export, import,
// realise they picked the wrong unit, and import again — and the obvious
// implementation turns that into two copies of a year's training, with no way
// back short of wiping the app. So a session already on the device is skipped,
// matched on when it started, and the result says how many were skipped.
//
// The second is that an unrecognised exercise name is created rather than
// dropped. A history where a third of the sets silently vanished because the
// other app called it "Barbell Bench Press (Flat)" is worse than useless: it
// looks complete.

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../exercises/data/exercise_repository.dart';
import '../../workout/data/workout_repository.dart';
import 'import_format.dart';
import 'import_plan.dart';

part 'import_repository.g.dart';

/// What an import actually did.
class ImportOutcome {
  const ImportOutcome({
    required this.sessionsAdded,
    required this.sessionsSkipped,
    required this.setsAdded,
    required this.exercisesCreated,
  });

  final int sessionsAdded;

  /// Already on the device, matched on start time. The number is the whole
  /// point of importing twice being safe.
  final int sessionsSkipped;

  final int setsAdded;

  /// Names the library had never heard of, now custom exercises.
  final List<String> exercisesCreated;
}

/// What building a split out of an import did.
class PlanOutcome {
  const PlanOutcome({
    required this.splitId,
    required this.splitName,
    required this.days,
    required this.exercises,
  });

  final int splitId;

  /// As stored — which may be shorter than what was asked for, since the
  /// column takes 60 characters.
  final String splitName;

  final int days;

  /// Planned exercise slots written across all of those days.
  final int exercises;
}

/// A name reduced to what it is, for matching across apps.
///
/// Case, punctuation and spacing all differ between exporters — "Bench Press
/// (Barbell)", "bench press - barbell" and "Barbell Bench Press" are three
/// spellings of one lift. This collapses the first two kinds of difference.
/// Word *order* is deliberately not normalised: "Front Squat" and "Squat
/// Front" would collapse together, and so would a pair of genuinely different
/// lifts often enough to matter.
String matchableName(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// Every spelling one exercise name should be recognised under.
///
/// The plain name, plus — when the name ends in a bracketed qualifier — the
/// same name with that qualifier moved to the front.
///
/// This exists because Hevy names its exercises `Bench Press (Barbell)` and
/// `Chest Fly (Machine)`, while this library (and Strong, and StrengthLog)
/// write `Barbell Bench Press`. Matching on the plain name alone, a Hevy
/// import would recognise almost nothing and quietly build a second, parallel
/// library of duplicates — every chart then split in half, with no error
/// anywhere to explain it.
///
/// Deliberately narrow. Normalising word order *in general* would collapse
/// "Front Squat" and "Squat Front", and pairs like that are not reliably the
/// same lift. Moving a parenthesised qualifier is a specific transform that
/// only fires when there are brackets, which is exactly the case it is for.
Set<String> matchKeys(String name) {
  final keys = {matchableName(name)};

  final bracketed = RegExp(r'^(.*?)\s*\(([^)]+)\)\s*$').firstMatch(name);
  if (bracketed != null) {
    final base = bracketed.group(1)!;
    final qualifier = bracketed.group(2)!;
    if (base.trim().isNotEmpty && qualifier.trim().isNotEmpty) {
      keys.add(matchableName('$qualifier $base'));
    }
  }

  return keys;
}

/// The value two sessions are considered the same workout by.
///
/// Whole seconds, because that is all the database keeps: drift stores a
/// `DateTime` as a Unix timestamp in *seconds*, so the milliseconds are
/// dropped on the way in. Comparing at millisecond precision meant comparing
/// a parsed value against a truncated one, and they almost never matched —
/// so importing a file twice added it twice, which is the one thing the
/// skip-what-is-already-here rule exists to prevent.
///
/// Found by importing a real export whose timestamps carry milliseconds
/// (`1789740587220`). Every fixture written by hand had used whole seconds,
/// so every test passed.
int sessionKey(DateTime start) => start.millisecondsSinceEpoch ~/ 1000;

/// How close two workouts have to start to be worth warning about.
///
/// An hour. Two apps logging the same session disagree by the minute or two it
/// took to open the second one, never by more; two genuinely separate workouts
/// in one day are further apart than this.
const nearDuplicateWindow = Duration(hours: 1);

/// One day's claim on one weekday.
class _WeekdayClaim {
  const _WeekdayClaim(this.day, this.weekday, this.rank);

  final PlannedDay day;
  final int weekday;

  /// Where this weekday sits in the day's own ordering — 0 is the weekday it
  /// is trained on most.
  final int rank;
}

/// Which day gets which weekday, at most one day per weekday.
///
/// Two days of a split can legitimately want the same weekday: this history
/// alternates two rotations, and both land on Monday. But `watchDayForWeekday`
/// returns the *first* day scheduled on a weekday and Home shows only that, so
/// a second claim is a day the user would never see there. Rather than write
/// one and let it disappear, only the stronger claim is scheduled and the
/// other day is left visibly unscheduled, for the user to place.
///
/// Strength is the weekday's rank within the day first — a day trained on
/// Monday above all beats one for which Monday is its second weekday — and
/// then how much training the day has behind it. A single improvised session
/// must not take Monday off a day trained seventeen times.
List<_WeekdayClaim> _weekdayClaims(List<PlannedDay> days) {
  final claims =
      <_WeekdayClaim>[
        for (final day in days)
          for (var rank = 0; rank < day.weekdays.length; rank++)
            _WeekdayClaim(day, day.weekdays[rank], rank),
      ]..sort((a, b) {
        final byRank = a.rank.compareTo(b.rank);
        if (byRank != 0) return byRank;
        final byHistory = b.day.sessionCount.compareTo(a.day.sessionCount);
        if (byHistory != 0) return byHistory;
        // Whatever is left, decided by name, so the same file always produces the
        // same calendar rather than one that depends on map iteration order.
        return a.day.name.compareTo(b.day.name);
      });

  final taken = <int>{};
  return [
    for (final claim in claims)
      if (taken.add(claim.weekday)) claim,
  ];
}

class ImportRepository {
  ImportRepository(this._db, this._exercises, this._workouts);

  final AppDatabase _db;
  final ExerciseRepository _exercises;

  /// Used only when building a split out of an import, so that the rules about
  /// what a split is — the first one made becomes the active one — stay in the
  /// one place that already owns them.
  final WorkoutRepository _workouts;

  /// The library indexed by every spelling each of its names answers to.
  ///
  /// Archived rows included: a custom exercise the user deleted still owns its
  /// history, and creating a second one under the same name would split it in
  /// two. `putIfAbsent`, so a library name's own plain spelling always wins
  /// over another one's rearranged form.
  Future<Map<String, String>> _libraryIndex() async {
    final library = await _db.select(_db.exercises).get();
    final idByName = <String, String>{};

    for (final exercise in library) {
      idByName.putIfAbsent(matchableName(exercise.name), () => exercise.id);
    }
    for (final exercise in library) {
      for (final key in matchKeys(exercise.name)) {
        idByName.putIfAbsent(key, () => exercise.id);
      }
    }

    return idByName;
  }

  /// The library id for an imported exercise name, creating it if the library
  /// has never heard of it.
  ///
  /// [index] is updated in place, so the same lift written two ways inside one
  /// file creates one exercise rather than two. [created] collects the names
  /// that were new, for the outcome the screen reports.
  Future<String> _resolveExercise(
    String name,
    Map<String, String> index,
    List<String> created,
  ) async {
    final keys = matchKeys(name);
    for (final key in keys) {
      final existing = index[key];
      if (existing != null) return existing;
    }

    final id = await _exercises.createCustom(
      name: name,
      // No muscles: the file does not say, and a guess would paint the muscle
      // map with work that may never have happened. The UI says how many of
      // these were created so they can be filled in — an empty list is visibly
      // incomplete, an invented one is not.
      muscleIds: const [],
      // Unknowable from a CSV, and false is the harmless answer: it only
      // decides whether the log sheet offers the plate stacker.
      isPlateLoaded: false,
    );
    for (final key in keys) {
      index.putIfAbsent(key, () => id);
    }
    created.add(name);
    return id;
  }

  /// Writes [import] into the database.
  ///
  /// One transaction: a partly written history is the one outcome with no
  /// good recovery, since the user cannot tell which half arrived.
  Future<ImportOutcome> apply(WorkoutImport import) async {
    return _db.transaction(() async {
      // Existing start times, to skip what is already here. Read once rather
      // than queried per session — a two-year export is several hundred
      // sessions, and that is several hundred round trips on a phone.
      final existing = {
        for (final session in await _db.select(_db.workoutSessions).get())
          sessionKey(session.startedAt),
      };

      // The library, indexed under every spelling each of its names answers
      // to, so a Hevy `Bench Press (Barbell)` finds the built-in `Barbell
      // Bench Press`.
      final idByName = await _libraryIndex();

      final created = <String>[];
      var sessionsAdded = 0;
      var sessionsSkipped = 0;
      var setsAdded = 0;

      for (final session in import.sessions) {
        if (existing.contains(sessionKey(session.start))) {
          sessionsSkipped++;
          continue;
        }
        // Added as we go, so two sessions at the same instant inside one file
        // cannot both be written.
        existing.add(sessionKey(session.start));

        final sessionId = await _db
            .into(_db.workoutSessions)
            .insert(
              WorkoutSessionsCompanion.insert(
                name: session.name,
                startedAt: Value(session.start),
                // Completed, because it happened. A session left open would
                // show up as a workout in progress and the app would offer to
                // resume a workout from last March.
                completedAt: Value(session.end ?? session.start),
              ),
            );
        sessionsAdded++;

        // Numbered within its own phase, the way the logging screen does it,
        // so an imported session reads identically to one logged here.
        final numbers = <String, int>{};

        for (final set in session.sets) {
          final exerciseId = await _resolveExercise(
            set.exerciseName,
            idByName,
            created,
          );

          final phase = '$exerciseId|${set.isWarmup}';
          final number = (numbers[phase] ?? 0) + 1;
          numbers[phase] = number;

          await _db
              .into(_db.loggedSets)
              .insert(
                LoggedSetsCompanion.insert(
                  sessionId: sessionId,
                  exerciseId: exerciseId,
                  setNumber: number,
                  weight: Value(set.weightKg),
                  reps: Value(set.reps),
                  isWarmup: Value(set.isWarmup),
                  seconds: Value(set.seconds),
                ),
              );
          setsAdded++;
        }
      }

      return ImportOutcome(
        sessionsAdded: sessionsAdded,
        sessionsSkipped: sessionsSkipped,
        setsAdded: setsAdded,
        exercisesCreated: created,
      );
    });
  }

  /// Builds a split out of [import] — one day per workout name in the file,
  /// each holding the exercises that day is actually trained with.
  ///
  /// This is the other half of importing, and for a while it was missing. The
  /// history alone fills the year activity and the charts, but Gymfy trains
  /// from a Split of WorkoutDays, and a CSV has none — so an import left you
  /// looking at a year of your own training with nothing to press "start" on,
  /// and eight days to retype by hand. Both files that prompted this
  /// (a Hevy export and a StrengthLog one) carry their day names in every row;
  /// the plan was in there the whole time.
  ///
  /// Written from [import.sessions] in full rather than only what [apply]
  /// added, so re-importing a file you already have still gets you the split.
  /// Returns null when the file names no workouts at all, which is the one
  /// case where there is no plan to build.
  ///
  /// Separate from [apply], and a separate transaction, on purpose: a split
  /// that fails to build leaves a complete history and no split, which the
  /// user can see and ask for again. Rolling the history back with it would
  /// be the worse of the two.
  /// [only] names the days to build, as [PlannedDay.name] spells them. Null
  /// builds all of them. The screen passes a selection because a real export
  /// mixes a programme with its accidents: StrengthLog titles an untitled
  /// workout after the clock, so one file offered thirteen days of which eight
  /// were a single improvised session each.
  Future<PlanOutcome?> createSplitFrom(
    WorkoutImport import, {
    String? name,
    Set<String>? only,
    int recentSessions = defaultRecentSessions,
  }) async {
    final days = planForImport(
      import,
      recentSessions: recentSessions,
    ).where((day) => only == null || only.contains(day.name)).toList();
    if (days.isEmpty) return null;

    final requested = (name ?? '').trim();
    final splitName = fitPlanName(
      requested.isEmpty ? defaultSplitName(import.source) : requested,
    );

    return _db.transaction(() async {
      final idByName = await _libraryIndex();
      // Discarded: these are names [apply] has almost always created already,
      // and the screen has reported them once. Saying it twice would read as
      // though the split had invented exercises of its own.
      final created = <String>[];

      // Through the workout repository rather than a direct insert, so the
      // rule that the first split ever made becomes the active one lives in
      // one place. Drift nests this inside the transaction above as a
      // savepoint, so a failure further down still takes the split with it.
      final splitId = await _workouts.createSplit(splitName);
      var slots = 0;

      final dayIds = <PlannedDay, int>{};

      for (final day in days) {
        final dayId = await _workouts.createDay(splitId, day.name);
        dayIds[day] = dayId;

        // By resolved id, not by the name the file used. A history where one
        // lift was logged under two spellings — a rename part-way through,
        // or a Hevy name alongside a hand-typed one — would otherwise put two
        // cards for the same exercise in the day, and in a live session both
        // would read and write the same rows while showing different counts.
        final placed = <String>{};

        for (final slot in day.exercises) {
          final exerciseId = await _resolveExercise(
            slot.exerciseName,
            idByName,
            created,
          );
          if (!placed.add(exerciseId)) continue;

          await _workouts.addExerciseToDay(
            dayId,
            exerciseId,
            sets: slot.sets,
            reps: slot.reps,
            warmupSets: slot.warmupSets,
          );
          slots++;
        }
      }

      for (final claim in _weekdayClaims(days)) {
        await _workouts.assignWeekday(
          dayId: dayIds[claim.day]!,
          weekday: claim.weekday,
        );
      }

      return PlanOutcome(
        splitId: splitId,
        splitName: splitName,
        days: days.length,
        exercises: slots,
      );
    });
  }

  /// Whether a split of this name already exists.
  ///
  /// For the preview. Importing the same file twice is the documented normal
  /// case — you realise the unit was wrong and do it again — and the history
  /// half of that is safe, but the split half would quietly add a second
  /// identical "Hevy import" every time, indistinguishable from the first in
  /// the switcher. Asked before rather than deduplicated after, because a
  /// second split is a reasonable thing to want; being given one unasked is
  /// not.
  Future<bool> hasSplitNamed(String name) async {
    final rows = await (_db.select(
      _db.splits,
    )..where((t) => t.name.equals(name.trim()))).get();
    return rows.isNotEmpty;
  }

  /// How much of [import] is already on the device.
  ///
  /// Read-only, for the preview: the user should know they are about to add
  /// nothing before they tap Import, not after.
  Future<int> countAlreadyHere(WorkoutImport import) async {
    final existing = {
      for (final session in await _db.select(_db.workoutSessions).get())
        sessionKey(session.startedAt),
    };
    return import.sessions
        .where((s) => existing.contains(sessionKey(s.start)))
        .length;
  }

  /// Workouts in [import] that look like ones already on the device without
  /// being the same row — near misses the exact-start-time rule will not skip.
  ///
  /// Only a warning, never a skip. This exists because the same training gets
  /// logged in two apps at once while someone is switching: exporting both and
  /// importing both gives one workout twice, a minute or two apart, and
  /// [sessionKey] matches to the second so neither copy is recognised as the
  /// other. Two real exports from one person overlapped on twenty days like
  /// this.
  ///
  /// Not skipped automatically, because the same-looking pair is occasionally
  /// real — a short session and a second one an hour later is a normal way to
  /// train around a busy gym. Dropping someone's second workout of the day
  /// without asking is worse than telling them what is about to happen.
  Future<int> countNearDuplicates(WorkoutImport import) async {
    final existing = await _db.select(_db.workoutSessions).get();
    final exact = {for (final row in existing) sessionKey(row.startedAt)};
    final starts = existing.map((row) => row.startedAt).toList();

    var near = 0;
    for (final session in import.sessions) {
      if (exact.contains(sessionKey(session.start))) continue;
      final isNear = starts.any(
        (start) => start.difference(session.start).abs() < nearDuplicateWindow,
      );
      if (isNear) near++;
    }
    return near;
  }
}

@Riverpod(keepAlive: true)
ImportRepository importRepository(Ref ref) {
  return ImportRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(exerciseRepositoryProvider),
    ref.watch(workoutRepositoryProvider),
  );
}
