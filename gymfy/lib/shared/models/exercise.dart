import 'dart:convert';

import 'package:drift/drift.dart';

/// Stores the `muscleIds` list as a JSON string, since SQLite has no native
/// list type. e.g. ["chest", "front_deltoid", "triceps"] <-> that same text.
class MuscleIdsConverter extends TypeConverter<List<String>, String> {
  const MuscleIdsConverter();

  @override
  List<String> fromSql(String fromDb) =>
      (json.decode(fromDb) as List<dynamic>).cast<String>();

  @override
  String toSql(List<String> value) => json.encode(value);
}

/// Drift table describing a single exercise in the library.
///
/// Drift generates an immutable `Exercise` row class from this definition —
/// that generated class IS our model (one source of truth for storage and the
/// in-memory object), which is why this entity doesn't use `freezed`.
class Exercises extends Table {
  /// Stable slug id, e.g. "barbell_bench_press". We assign these ourselves in
  /// the seed data, so it's a text primary key (not an autoincrement int).
  TextColumn get id => text()();

  /// Display name, e.g. "Barbell Bench Press".
  TextColumn get name => text()();

  /// Muscles this exercise trains. Values must come from `MuscleId`
  /// (muscle_ids.dart); stored as a JSON array. Drives the muscle-map heatmap.
  TextColumn get muscleIds => text().map(const MuscleIdsConverter())();

  /// Where the preview image lives. Two shapes, told apart by the prefix:
  ///
  /// - `assets/exercises/<id>.gif` — a built-in GIF bundled with the app.
  /// - an absolute file path — a picture the user chose for a custom exercise,
  ///   copied into the app's own directory (see `ExerciseRepository.saveImage`).
  ///
  /// Nullable: most exercises have no image, which is a normal state and not an
  /// error. Use `isBundledAsset` to decide how to load it.
  TextColumn get gifPath => text().nullable()();

  /// True for exercises loaded by putting plates on a bar.
  ///
  /// Barbell and EZ-bar movements only. Plate-loaded *machines* (leg press,
  /// hack squat) are deliberately excluded: their sleds have an unlisted
  /// starting weight and a varying number of pegs, so "bar + 2 × plates" would
  /// quietly report a wrong number rather than a useful one.
  ///
  /// Drives how the log-set dialog opens — stacking plates for these, typing a
  /// number for everything else.
  BoolColumn get isPlateLoaded =>
      boolean().withDefault(const Constant(false))();

  /// What the empty bar or carriage weighs, in kilograms, or null to use the
  /// gym-wide default for the unit.
  ///
  /// Per exercise because "plate-loaded" does not mean "on a barbell". A
  /// T-bar row, a hack squat, a leg press: plates go on, but there is no 20 kg
  /// bar in the equation, and the calculator's total was wrong by exactly one
  /// bar every time. Zero is a legitimate value here and means what it says —
  /// nothing to add.
  ///
  /// Deliberately *not* set by [exerciseSeedData]. The seed upsert rewrites
  /// every built-in row on launch, but only the columns its companions carry,
  /// so leaving this one absent is what lets a value the user chose survive.
  /// `exercise_bar_test.dart` re-seeds and checks exactly that.
  RealColumn get barWeightKg => real().nullable()();

  /// True for exercises the user created themselves.
  ///
  /// This is what gates editing and deleting: the built-in library is upserted
  /// from [exerciseSeedData] on every launch, so "editing" a seed exercise would
  /// silently revert on the next start. Rather than let that happen, the UI only
  /// offers those actions on custom rows.
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  /// True once the user has deleted a custom exercise that already has history.
  ///
  /// Archived exercises vanish from the library and from every picker, but the
  /// row stays so past workouts keep their sets and their exercise *name*.
  /// Deleting a custom exercise that was never logged removes it outright — no
  /// history to protect, so no tombstone to leave behind.
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// What the movement needs: barbell, dumbbell, machine, cable, bodyweight
  /// or other. Stored as the [Equipment] slug.
  ///
  /// Carried by the seed companions, like [isTimed] and unlike [notes]: a
  /// bench press needs a barbell whoever is holding it, so the built-in
  /// library should keep asserting that on every launch.
  ///
  /// Defaults to `other` rather than being nullable. "Unclassified" and
  /// "something else" would show up identically on a filter bar, and a second
  /// state that renders the same as the first is a state nobody can act on.
  TextColumn get equipment =>
      text().withDefault(const Constant('other')).withLength(max: 20)();

  /// True for movements measured in time rather than reps — planks, hangs,
  /// wall sits, loaded carries, and cardio.
  ///
  /// On the exercise rather than on the set, because it is a fact about the
  /// movement: a plank is never counted in reps, on any day, in any
  /// programme. It decides which of the two the log sheet asks for, so a
  /// per-set flag would let you log a plank in reps by accident.
  ///
  /// Carried by the seed companions, unlike [notes] and [barWeightKg] — this
  /// is a property of the movement itself, not something the user chose, so
  /// the built-in library should keep telling the truth about it on every
  /// launch even if a past version got one wrong.
  BoolColumn get isTimed => boolean().withDefault(const Constant(false))();

  /// The user's own note about this exercise — seat height, pin position, grip
  /// width, which machine in the gym, a cue that makes the lift click.
  ///
  /// On the *exercise*, not on the planned entry or the session. A seat height
  /// is a fact about the machine, so it is the same on push day and pull day
  /// and in a programme written next year. Hanging it off the plan would mean
  /// retyping it for every day the lift appears in, and losing it when the
  /// plan is rewritten.
  ///
  /// Null means "never written", which is not the same as an empty note — an
  /// empty string would still draw a heading with nothing under it. Clearing
  /// the text stores null again.
  ///
  /// Available on built-in exercises too, and that is the main case: the leg
  /// press is not something you invented. Like [barWeightKg] this is
  /// deliberately absent from [exerciseSeedData], so the launch upsert — which
  /// rewrites every built-in row but only the columns its companions carry —
  /// cannot wipe what you wrote. `exercise_notes_test.dart` re-seeds and
  /// checks exactly that.
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Whether [gifPath] points at a GIF bundled in the app (as opposed to a file
/// the user picked from their gallery). Decides `Image.asset` vs `Image.file`.
bool isBundledAsset(String path) => path.startsWith('assets/');
