import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/models/exercise.dart' show isBundledAsset;
import 'exercise_seed_data.dart';

part 'exercise_repository.g.dart';

/// Directory holding images the user picked for their own exercises.
///
/// Kept inside the app's own documents directory so it is backed up with the
/// app and removed when the app is uninstalled — the gallery original is never
/// touched, and the app never depends on it still being there.
Future<Directory> exerciseImageDir() async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory('${base.path}/exercise_images');
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// Turns a display name into a stable id, e.g. "Cable Fly (Low)" -> "cable_fly_low".
///
/// Custom ids are prefixed so they can never collide with a built-in exercise —
/// if they did, the seed upsert would overwrite the user's exercise on the next
/// launch.
String slugifyExerciseName(String name) {
  final slug = name
      .toLowerCase()
      // Apostrophes are dropped, not turned into a separator: "Farmer's Walk"
      // should be `farmers_walk`, not `farmer_s_walk`. Straight and curly both,
      // since phone keyboards produce the curly one.
      .replaceAll(RegExp("['’]"), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return 'custom_${slug.isEmpty ? 'exercise' : slug}';
}

/// All database access for exercises lives here.
class ExerciseRepository {
  ExerciseRepository(this._db);

  final AppDatabase _db;

  /// Sets (or clears) the bar weight for one exercise, in kilograms.
  ///
  /// Null means "use the gym-wide default"; zero means there is no bar at all,
  /// which is the honest answer for a leg press or a hack squat.
  Future<void> setBarWeight(String exerciseId, double? barWeightKg) {
    return (_db.update(_db.exercises)..where((t) => t.id.equals(exerciseId)))
        .write(ExercisesCompanion(barWeightKg: Value(barWeightKg)));
  }

  /// Loads the built-in [exerciseSeedData] into the database.
  ///
  /// Idempotent: this is an upsert keyed on each exercise's `id`, so running
  /// it on every launch never creates duplicates, and editing the seed list
  /// updates the stored rows on the next launch. Cheap enough (~78 rows in a
  /// single batched transaction) to run at startup even on older phones — it's
  /// one round trip, not one per exercise. Worth re-checking if the library
  /// ever grows into the hundreds.
  ///
  /// Custom exercises are untouched by this: their ids carry a `custom_` prefix
  /// that no seed row uses, so there is nothing for the upsert to conflict with.
  Future<void> seed() async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.exercises, exerciseSeedData);
    });
  }

  /// Streams the exercises a user should be offered — everything except the
  /// archived ones — ordered by name.
  ///
  /// The stream automatically re-emits whenever the exercises table changes, so
  /// any UI watching it updates itself with no manual refresh.
  Stream<List<Exercise>> watchActiveExercises() {
    final query = _db.select(_db.exercises)
      ..where((t) => t.isArchived.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return query.watch();
  }

  /// Streams every exercise, archived ones included.
  ///
  /// Only for looking up the *name* behind an id in historical data. A workout
  /// logged last month must still say "Cable Fly" after that exercise has been
  /// deleted, which is the whole reason archiving exists.
  Stream<List<Exercise>> watchEveryExercise() {
    final query = _db.select(_db.exercises)
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return query.watch();
  }

  /// Streams a single exercise by its id (null if it doesn't exist), updating
  /// automatically if that row changes.
  Stream<Exercise?> watchExercise(String id) {
    final query = _db.select(_db.exercises)..where((t) => t.id.equals(id));
    return query.watchSingleOrNull();
  }

  /// Copies a picked image into the app's own storage and returns its path.
  ///
  /// The gallery path we get from the picker is a temporary or external one:
  /// storing it directly would leave a broken image the moment the user tidies
  /// up their photos.
  Future<String> saveImage(File source, {required String exerciseId}) async {
    final dir = await exerciseImageDir();
    final extension = source.path.split('.').last.toLowerCase();
    final target = '${dir.path}/$exerciseId.$extension';
    await source.copy(target);
    return target;
  }

  /// Creates a custom exercise and returns its new id.
  ///
  /// The id is derived from the name, with a numeric suffix if that slug is
  /// already taken — two exercises may legitimately share a name (a "Cable Fly"
  /// on two different machines), and refusing the second would be more annoying
  /// than helpful.
  Future<String> createCustom({
    required String name,
    required bool isPlateLoaded,
    required List<String> muscleIds,
    String? imagePath,
  }) async {
    final id = await _uniqueId(slugifyExerciseName(name));

    await _db
        .into(_db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: id,
            name: name,
            muscleIds: muscleIds,
            gifPath: Value(imagePath),
            isPlateLoaded: Value(isPlateLoaded),
            isCustom: const Value(true),
          ),
        );
    return id;
  }

  /// Applies edits to an existing custom exercise.
  ///
  /// The id deliberately does NOT follow a rename: it's referenced by every set
  /// ever logged, so changing it would orphan that history. The displayed name
  /// updates everywhere on its own, which is what the user actually wanted.
  Future<void> updateCustom({
    required String id,
    required String name,
    required bool isPlateLoaded,
    required List<String> muscleIds,
    required String? imagePath,
  }) async {
    await (_db.update(_db.exercises)..where((t) => t.id.equals(id))).write(
      ExercisesCompanion(
        name: Value(name),
        muscleIds: Value(muscleIds),
        isPlateLoaded: Value(isPlateLoaded),
        gifPath: Value(imagePath),
      ),
    );
  }

  /// Whether this exercise appears in any logged set or any planned split day.
  Future<bool> hasHistory(String id) async {
    final logged =
        await (_db.select(_db.loggedSets)
              ..where((t) => t.exerciseId.equals(id))
              ..limit(1))
            .get();
    if (logged.isNotEmpty) return true;

    final planned =
        await (_db.select(_db.workoutExercises)
              ..where((t) => t.exerciseId.equals(id))
              ..limit(1))
            .get();
    return planned.isNotEmpty;
  }

  /// Removes a custom exercise, keeping any history it is part of.
  ///
  /// Returns true if the row was archived rather than deleted, so the UI can
  /// say which one happened instead of guessing.
  ///
  /// An exercise that has been logged or planned can't simply be deleted: past
  /// sessions reference it, and the database would reject the delete anyway.
  /// Archiving hides it everywhere a user picks an exercise while leaving the
  /// row intact for name lookups.
  Future<bool> deleteCustom(Exercise exercise) async {
    if (await hasHistory(exercise.id)) {
      await (_db.update(_db.exercises)..where((t) => t.id.equals(exercise.id)))
          .write(const ExercisesCompanion(isArchived: Value(true)));
      return true;
    }

    // Never used, so nothing to preserve. The row goes first; its image is
    // cleanup that must not block the delete if it fails.
    await (_db.delete(
      _db.exercises,
    )..where((t) => t.id.equals(exercise.id))).go();
    await _deleteImage(exercise.gifPath);
    return false;
  }

  Future<void> _deleteImage(String? path) async {
    if (path == null || isBundledAsset(path)) return;
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Finds a free id, appending `_2`, `_3`, … until one is unused.
  Future<String> _uniqueId(String base) async {
    var candidate = base;
    var suffix = 1;
    while (true) {
      final existing = await (_db.select(
        _db.exercises,
      )..where((t) => t.id.equals(candidate))).getSingleOrNull();
      if (existing == null) return candidate;
      suffix++;
      candidate = '${base}_$suffix';
    }
  }
}

/// App-wide access to the [ExerciseRepository].
@Riverpod(keepAlive: true)
ExerciseRepository exerciseRepository(Ref ref) {
  return ExerciseRepository(ref.watch(appDatabaseProvider));
}

/// The live list of pickable exercises (archived ones excluded), as an
/// `AsyncValue` (loading / error / data) the UI can react to.
///
/// Written as a manual `StreamProvider` (not code-generated) because its type
/// is Drift's generated `Exercise` class, which the Riverpod generator can't
/// emit in generated code.
final exerciseListProvider = StreamProvider<List<Exercise>>((ref) {
  return ref.watch(exerciseRepositoryProvider).watchActiveExercises();
});

/// Every exercise including archived ones — for resolving an id to a name in
/// historical data. Anywhere the user *chooses* an exercise wants
/// [exerciseListProvider] instead.
final allExercisesProvider = StreamProvider<List<Exercise>>((ref) {
  return ref.watch(exerciseRepositoryProvider).watchEveryExercise();
});

/// The live single exercise for a given id, as an `AsyncValue` (loading /
/// error / data), where the data can be null if no exercise has that id.
///
/// A `.family` provider so the detail screen can request one exercise by id.
/// Hand-written (not code-generated) for the same reason as
/// [exerciseListProvider]: it exposes Drift's generated `Exercise` type.
final exerciseProvider = StreamProvider.family<Exercise?, String>((ref, id) {
  return ref.watch(exerciseRepositoryProvider).watchExercise(id);
});
