import 'dart:convert';

import 'package:drift/drift.dart';

import 'exercise_category.dart';

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

  /// Path to the preview GIF asset, e.g.
  /// "assets/exercises/barbell_bench_press.gif". Nullable — not every exercise
  /// has a GIF yet.
  TextColumn get gifPath => text().nullable()();

  /// Movement-pattern grouping, stored as its enum name (push/pull/legs/core).
  TextColumn get category => textEnum<ExerciseCategory>()();

  @override
  Set<Column> get primaryKey => {id};
}
