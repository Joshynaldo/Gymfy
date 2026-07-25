import 'package:drift/drift.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/models/exercise_category.dart';
import '../../../shared/models/muscle_ids.dart';

/// The built-in exercise library shipped with the app.
///
/// Each row is a Drift "companion" (a row-to-insert). `muscleIds` values MUST
/// come from [MuscleId] so they line up with the Phase 5 muscle map, and
/// `gifPath` follows the convention `assets/exercises/<id>.gif` (drop the GIF
/// files there later — they don't need to exist for this data to load).
///
/// This list is `const`, so adding, removing, or editing an entry is just a
/// text change; the repository's upsert keeps the database in sync on the next
/// launch.
const List<ExercisesCompanion> exerciseSeedData = [
  // ---------------- PUSH ----------------
  ExercisesCompanion(
    id: Value('barbell_bench_press'),
    name: Value('Barbell Bench Press'),
    muscleIds: Value([MuscleId.chest, MuscleId.frontDeltoid, MuscleId.triceps]),
    gifPath: Value('assets/exercises/barbell_bench_press.gif'),
    category: Value(ExerciseCategory.push),
  ),
  ExercisesCompanion(
    id: Value('incline_dumbbell_press'),
    name: Value('Incline Dumbbell Press'),
    muscleIds: Value([MuscleId.chest, MuscleId.frontDeltoid, MuscleId.triceps]),
    gifPath: Value('assets/exercises/incline_dumbbell_press.gif'),
    category: Value(ExerciseCategory.push),
  ),
  ExercisesCompanion(
    id: Value('push_up'),
    name: Value('Push-Up'),
    muscleIds: Value([MuscleId.chest, MuscleId.frontDeltoid, MuscleId.triceps]),
    gifPath: Value('assets/exercises/push_up.gif'),
    category: Value(ExerciseCategory.push),
  ),
  ExercisesCompanion(
    id: Value('overhead_barbell_press'),
    name: Value('Overhead Barbell Press'),
    muscleIds: Value([
      MuscleId.frontDeltoid,
      MuscleId.triceps,
      MuscleId.trapezius,
    ]),
    gifPath: Value('assets/exercises/overhead_barbell_press.gif'),
    category: Value(ExerciseCategory.push),
  ),
  ExercisesCompanion(
    id: Value('dumbbell_shoulder_press'),
    name: Value('Dumbbell Shoulder Press'),
    muscleIds: Value([MuscleId.frontDeltoid, MuscleId.triceps]),
    gifPath: Value('assets/exercises/dumbbell_shoulder_press.gif'),
    category: Value(ExerciseCategory.push),
  ),
  ExercisesCompanion(
    id: Value('dumbbell_lateral_raise'),
    name: Value('Dumbbell Lateral Raise'),
    muscleIds: Value([MuscleId.sideDeltoid]),
    gifPath: Value('assets/exercises/dumbbell_lateral_raise.gif'),
    category: Value(ExerciseCategory.push),
  ),
  ExercisesCompanion(
    id: Value('triceps_pushdown'),
    name: Value('Triceps Pushdown'),
    muscleIds: Value([MuscleId.triceps]),
    gifPath: Value('assets/exercises/triceps_pushdown.gif'),
    category: Value(ExerciseCategory.push),
  ),

  // ---------------- PULL ----------------
  ExercisesCompanion(
    id: Value('pull_up'),
    name: Value('Pull-Up'),
    muscleIds: Value([MuscleId.lats, MuscleId.biceps, MuscleId.rearDeltoid]),
    gifPath: Value('assets/exercises/pull_up.gif'),
    category: Value(ExerciseCategory.pull),
  ),
  ExercisesCompanion(
    id: Value('lat_pulldown'),
    name: Value('Lat Pulldown'),
    muscleIds: Value([MuscleId.lats, MuscleId.biceps]),
    gifPath: Value('assets/exercises/lat_pulldown.gif'),
    category: Value(ExerciseCategory.pull),
  ),
  ExercisesCompanion(
    id: Value('barbell_row'),
    name: Value('Barbell Row'),
    muscleIds: Value([
      MuscleId.lats,
      MuscleId.trapezius,
      MuscleId.rearDeltoid,
      MuscleId.biceps,
    ]),
    gifPath: Value('assets/exercises/barbell_row.gif'),
    category: Value(ExerciseCategory.pull),
  ),
  ExercisesCompanion(
    id: Value('seated_cable_row'),
    name: Value('Seated Cable Row'),
    muscleIds: Value([
      MuscleId.lats,
      MuscleId.trapezius,
      MuscleId.rearDeltoid,
      MuscleId.biceps,
    ]),
    gifPath: Value('assets/exercises/seated_cable_row.gif'),
    category: Value(ExerciseCategory.pull),
  ),
  ExercisesCompanion(
    id: Value('face_pull'),
    name: Value('Face Pull'),
    muscleIds: Value([MuscleId.rearDeltoid, MuscleId.trapezius]),
    gifPath: Value('assets/exercises/face_pull.gif'),
    category: Value(ExerciseCategory.pull),
  ),
  ExercisesCompanion(
    id: Value('deadlift'),
    name: Value('Deadlift'),
    muscleIds: Value([
      MuscleId.lowerBack,
      MuscleId.glutes,
      MuscleId.hamstrings,
      MuscleId.trapezius,
      MuscleId.lats,
    ]),
    gifPath: Value('assets/exercises/deadlift.gif'),
    category: Value(ExerciseCategory.pull),
  ),
  ExercisesCompanion(
    id: Value('barbell_biceps_curl'),
    name: Value('Barbell Biceps Curl'),
    muscleIds: Value([MuscleId.biceps, MuscleId.forearms]),
    gifPath: Value('assets/exercises/barbell_biceps_curl.gif'),
    category: Value(ExerciseCategory.pull),
  ),
  ExercisesCompanion(
    id: Value('dumbbell_hammer_curl'),
    name: Value('Dumbbell Hammer Curl'),
    muscleIds: Value([MuscleId.biceps, MuscleId.forearms]),
    gifPath: Value('assets/exercises/dumbbell_hammer_curl.gif'),
    category: Value(ExerciseCategory.pull),
  ),

  // ---------------- LEGS ----------------
  ExercisesCompanion(
    id: Value('barbell_back_squat'),
    name: Value('Barbell Back Squat'),
    muscleIds: Value([
      MuscleId.quads,
      MuscleId.glutes,
      MuscleId.hamstrings,
      MuscleId.lowerBack,
    ]),
    gifPath: Value('assets/exercises/barbell_back_squat.gif'),
    category: Value(ExerciseCategory.legs),
  ),
  ExercisesCompanion(
    id: Value('leg_press'),
    name: Value('Leg Press'),
    muscleIds: Value([MuscleId.quads, MuscleId.glutes, MuscleId.hamstrings]),
    gifPath: Value('assets/exercises/leg_press.gif'),
    category: Value(ExerciseCategory.legs),
  ),
  ExercisesCompanion(
    id: Value('romanian_deadlift'),
    name: Value('Romanian Deadlift'),
    muscleIds: Value([
      MuscleId.hamstrings,
      MuscleId.glutes,
      MuscleId.lowerBack,
    ]),
    gifPath: Value('assets/exercises/romanian_deadlift.gif'),
    category: Value(ExerciseCategory.legs),
  ),
  ExercisesCompanion(
    id: Value('walking_lunge'),
    name: Value('Walking Lunge'),
    muscleIds: Value([MuscleId.quads, MuscleId.glutes, MuscleId.hamstrings]),
    gifPath: Value('assets/exercises/walking_lunge.gif'),
    category: Value(ExerciseCategory.legs),
  ),
  ExercisesCompanion(
    id: Value('leg_extension'),
    name: Value('Leg Extension'),
    muscleIds: Value([MuscleId.quads]),
    gifPath: Value('assets/exercises/leg_extension.gif'),
    category: Value(ExerciseCategory.legs),
  ),
  ExercisesCompanion(
    id: Value('lying_leg_curl'),
    name: Value('Lying Leg Curl'),
    muscleIds: Value([MuscleId.hamstrings]),
    gifPath: Value('assets/exercises/lying_leg_curl.gif'),
    category: Value(ExerciseCategory.legs),
  ),
  ExercisesCompanion(
    id: Value('barbell_hip_thrust'),
    name: Value('Barbell Hip Thrust'),
    muscleIds: Value([MuscleId.glutes, MuscleId.hamstrings]),
    gifPath: Value('assets/exercises/barbell_hip_thrust.gif'),
    category: Value(ExerciseCategory.legs),
  ),
  ExercisesCompanion(
    id: Value('standing_calf_raise'),
    name: Value('Standing Calf Raise'),
    muscleIds: Value([MuscleId.calves]),
    gifPath: Value('assets/exercises/standing_calf_raise.gif'),
    category: Value(ExerciseCategory.legs),
  ),

  // ---------------- CORE ----------------
  ExercisesCompanion(
    id: Value('plank'),
    name: Value('Plank'),
    muscleIds: Value([MuscleId.abs, MuscleId.obliques]),
    gifPath: Value('assets/exercises/plank.gif'),
    category: Value(ExerciseCategory.core),
  ),
  ExercisesCompanion(
    id: Value('hanging_leg_raise'),
    name: Value('Hanging Leg Raise'),
    muscleIds: Value([MuscleId.abs, MuscleId.obliques]),
    gifPath: Value('assets/exercises/hanging_leg_raise.gif'),
    category: Value(ExerciseCategory.core),
  ),
  ExercisesCompanion(
    id: Value('cable_crunch'),
    name: Value('Cable Crunch'),
    muscleIds: Value([MuscleId.abs]),
    gifPath: Value('assets/exercises/cable_crunch.gif'),
    category: Value(ExerciseCategory.core),
  ),
  ExercisesCompanion(
    id: Value('russian_twist'),
    name: Value('Russian Twist'),
    muscleIds: Value([MuscleId.obliques, MuscleId.abs]),
    gifPath: Value('assets/exercises/russian_twist.gif'),
    category: Value(ExerciseCategory.core),
  ),
];
