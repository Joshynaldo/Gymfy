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
import 'import_format.dart';

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

class ImportRepository {
  ImportRepository(this._db, this._exercises);

  final AppDatabase _db;
  final ExerciseRepository _exercises;

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

      // The library, indexed by matchable name. Archived rows included: a
      // custom exercise the user deleted still owns its history, and creating
      // a second one under the same name would split it in two.
      // Indexed under every spelling each library name answers to, so a Hevy
      // `Bench Press (Barbell)` finds the built-in `Barbell Bench Press`.
      // `putIfAbsent`, so a library name's own plain spelling always wins over
      // another one's rearranged form.
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
          final keys = matchKeys(set.exerciseName);
          String? exerciseId;
          for (final key in keys) {
            exerciseId = idByName[key];
            if (exerciseId != null) break;
          }

          if (exerciseId == null) {
            exerciseId = await _exercises.createCustom(
              name: set.exerciseName,
              // No muscles: the file does not say, and a guess would paint
              // the muscle map with work that may never have happened. The
              // UI says how many of these were created so they can be filled
              // in — an empty list is visibly incomplete, an invented one is
              // not.
              muscleIds: const [],
              // Unknowable from a CSV, and false is the harmless answer: it
              // only decides whether the log sheet offers the plate stacker.
              isPlateLoaded: false,
            );
            // Registered under every spelling, so the same lift written two
            // ways inside one file creates one exercise rather than two.
            for (final key in keys) {
              idByName.putIfAbsent(key, () => exerciseId!);
            }
            created.add(set.exerciseName);
          }

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
}

@Riverpod(keepAlive: true)
ImportRepository importRepository(Ref ref) {
  return ImportRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(exerciseRepositoryProvider),
  );
}
