import 'package:drift/drift.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/models/muscle_ids.dart';

/// The built-in exercise library shipped with the app.
///
/// Each row is a Drift "companion" (a row-to-insert). `muscleIds` values MUST
/// come from [MuscleId] so they line up with the muscle map, and `gifPath`
/// follows the convention `assets/exercises/<id>.gif` (drop the GIF files there
/// later — they don't need to exist for this data to load).
///
/// The headings below are only there to make the file navigable while adding
/// entries. They are NOT stored and NOT shown anywhere: an exercise is defined
/// by the muscles it trains, and nothing else. Where a lift belongs under two
/// headings (a deadlift is back and legs), pick either — `muscleIds` is what
/// actually decides how it behaves.
///
/// Ordering within `muscleIds` matters for readability only (the subtitle in
/// the library lists them in this order), so put the prime mover first and the
/// assisting muscles after it.
///
/// This list is `const`, so adding, removing, or editing an entry is just a
/// text change; the repository's upsert keeps the database in sync on the next
/// launch. See `exercise_seed_data_test.dart` for the rules an entry has to
/// satisfy — a typo'd muscle id fails there rather than silently failing to
/// light up the heatmap.
const List<ExercisesCompanion> exerciseSeedData = [
  // ---------------- CHEST ----------------
  ExercisesCompanion(
    id: Value('barbell_bench_press'),
    name: Value('Barbell Bench Press'),
    muscleIds: Value([MuscleId.chest, MuscleId.frontDeltoid, MuscleId.triceps]),
    gifPath: Value('assets/exercises/barbell_bench_press.gif'),
    isPlateLoaded: Value(true),
  ),
  ExercisesCompanion(
    id: Value('dumbbell_bench_press'),
    name: Value('Dumbbell Bench Press'),
    muscleIds: Value([MuscleId.chest, MuscleId.frontDeltoid, MuscleId.triceps]),
    gifPath: Value('assets/exercises/dumbbell_bench_press.gif'),
  ),
  ExercisesCompanion(
    id: Value('incline_barbell_press'),
    name: Value('Incline Barbell Press'),
    muscleIds: Value([MuscleId.chest, MuscleId.frontDeltoid, MuscleId.triceps]),
    gifPath: Value('assets/exercises/incline_barbell_press.gif'),
    isPlateLoaded: Value(true),
  ),
  ExercisesCompanion(
    id: Value('incline_dumbbell_press'),
    name: Value('Incline Dumbbell Press'),
    muscleIds: Value([MuscleId.chest, MuscleId.frontDeltoid, MuscleId.triceps]),
    gifPath: Value('assets/exercises/incline_dumbbell_press.gif'),
  ),
  ExercisesCompanion(
    id: Value('decline_barbell_press'),
    name: Value('Decline Barbell Press'),
    muscleIds: Value([MuscleId.chest, MuscleId.triceps]),
    gifPath: Value('assets/exercises/decline_barbell_press.gif'),
    isPlateLoaded: Value(true),
  ),
  ExercisesCompanion(
    id: Value('push_up'),
    name: Value('Push-Up'),
    muscleIds: Value([MuscleId.chest, MuscleId.frontDeltoid, MuscleId.triceps]),
    gifPath: Value('assets/exercises/push_up.gif'),
  ),
  ExercisesCompanion(
    id: Value('chest_dip'),
    name: Value('Chest Dip'),
    muscleIds: Value([MuscleId.chest, MuscleId.triceps, MuscleId.frontDeltoid]),
    gifPath: Value('assets/exercises/chest_dip.gif'),
  ),
  ExercisesCompanion(
    id: Value('cable_fly'),
    name: Value('Cable Fly'),
    muscleIds: Value([MuscleId.chest, MuscleId.frontDeltoid]),
    gifPath: Value('assets/exercises/cable_fly.gif'),
  ),
  ExercisesCompanion(
    id: Value('dumbbell_fly'),
    name: Value('Dumbbell Fly'),
    muscleIds: Value([MuscleId.chest, MuscleId.frontDeltoid]),
    gifPath: Value('assets/exercises/dumbbell_fly.gif'),
  ),
  ExercisesCompanion(
    id: Value('pec_deck'),
    name: Value('Pec Deck'),
    muscleIds: Value([MuscleId.chest]),
    gifPath: Value('assets/exercises/pec_deck.gif'),
  ),

  // ---------------- BACK ----------------
  ExercisesCompanion(
    id: Value('pull_up'),
    name: Value('Pull-Up'),
    muscleIds: Value([MuscleId.lats, MuscleId.biceps, MuscleId.rearDeltoid]),
    gifPath: Value('assets/exercises/pull_up.gif'),
  ),
  ExercisesCompanion(
    id: Value('chin_up'),
    name: Value('Chin-Up'),
    muscleIds: Value([MuscleId.lats, MuscleId.biceps]),
    gifPath: Value('assets/exercises/chin_up.gif'),
  ),
  ExercisesCompanion(
    id: Value('lat_pulldown'),
    name: Value('Lat Pulldown'),
    muscleIds: Value([MuscleId.lats, MuscleId.biceps]),
    gifPath: Value('assets/exercises/lat_pulldown.gif'),
  ),
  ExercisesCompanion(
    id: Value('straight_arm_pulldown'),
    name: Value('Straight-Arm Pulldown'),
    muscleIds: Value([MuscleId.lats, MuscleId.triceps]),
    gifPath: Value('assets/exercises/straight_arm_pulldown.gif'),
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
    isPlateLoaded: Value(true),
  ),
  ExercisesCompanion(
    id: Value('dumbbell_row'),
    name: Value('Dumbbell Row'),
    muscleIds: Value([MuscleId.lats, MuscleId.trapezius, MuscleId.biceps]),
    gifPath: Value('assets/exercises/dumbbell_row.gif'),
  ),
  ExercisesCompanion(
    id: Value('t_bar_row'),
    name: Value('T-Bar Row'),
    muscleIds: Value([
      MuscleId.lats,
      MuscleId.trapezius,
      MuscleId.rearDeltoid,
      MuscleId.biceps,
    ]),
    gifPath: Value('assets/exercises/t_bar_row.gif'),
    isPlateLoaded: Value(true),
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
  ),
  ExercisesCompanion(
    id: Value('inverted_row'),
    name: Value('Inverted Row'),
    muscleIds: Value([MuscleId.lats, MuscleId.trapezius, MuscleId.biceps]),
    gifPath: Value('assets/exercises/inverted_row.gif'),
  ),
  ExercisesCompanion(
    id: Value('lat_pullover'),
    name: Value('Lat Pullover'),
    muscleIds: Value([MuscleId.lats, MuscleId.chest, MuscleId.triceps]),
    gifPath: Value('assets/exercises/lat_pullover.gif'),
  ),
  ExercisesCompanion(
    id: Value('barbell_shrug'),
    name: Value('Barbell Shrug'),
    muscleIds: Value([MuscleId.trapezius, MuscleId.forearms]),
    gifPath: Value('assets/exercises/barbell_shrug.gif'),
    isPlateLoaded: Value(true),
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
    isPlateLoaded: Value(true),
  ),
  ExercisesCompanion(
    id: Value('good_morning'),
    name: Value('Good Morning'),
    muscleIds: Value([
      MuscleId.lowerBack,
      MuscleId.hamstrings,
      MuscleId.glutes,
    ]),
    gifPath: Value('assets/exercises/good_morning.gif'),
    isPlateLoaded: Value(true),
  ),
  ExercisesCompanion(
    id: Value('back_extension'),
    name: Value('Back Extension'),
    muscleIds: Value([
      MuscleId.lowerBack,
      MuscleId.glutes,
      MuscleId.hamstrings,
    ]),
    gifPath: Value('assets/exercises/back_extension.gif'),
  ),

  // ---------------- SHOULDERS ----------------
  ExercisesCompanion(
    id: Value('overhead_barbell_press'),
    name: Value('Overhead Barbell Press'),
    muscleIds: Value([
      MuscleId.frontDeltoid,
      MuscleId.triceps,
      MuscleId.trapezius,
    ]),
    gifPath: Value('assets/exercises/overhead_barbell_press.gif'),
    isPlateLoaded: Value(true),
  ),
  ExercisesCompanion(
    id: Value('dumbbell_shoulder_press'),
    name: Value('Dumbbell Shoulder Press'),
    muscleIds: Value([MuscleId.frontDeltoid, MuscleId.triceps]),
    gifPath: Value('assets/exercises/dumbbell_shoulder_press.gif'),
  ),
  ExercisesCompanion(
    id: Value('machine_shoulder_press'),
    name: Value('Machine Shoulder Press'),
    muscleIds: Value([MuscleId.frontDeltoid, MuscleId.triceps]),
    gifPath: Value('assets/exercises/machine_shoulder_press.gif'),
  ),
  ExercisesCompanion(
    id: Value('arnold_press'),
    name: Value('Arnold Press'),
    muscleIds: Value([
      MuscleId.frontDeltoid,
      MuscleId.sideDeltoid,
      MuscleId.triceps,
    ]),
    gifPath: Value('assets/exercises/arnold_press.gif'),
  ),
  ExercisesCompanion(
    id: Value('dumbbell_lateral_raise'),
    name: Value('Dumbbell Lateral Raise'),
    muscleIds: Value([MuscleId.sideDeltoid]),
    gifPath: Value('assets/exercises/dumbbell_lateral_raise.gif'),
  ),
  ExercisesCompanion(
    id: Value('cable_lateral_raise'),
    name: Value('Cable Lateral Raise'),
    muscleIds: Value([MuscleId.sideDeltoid]),
    gifPath: Value('assets/exercises/cable_lateral_raise.gif'),
  ),
  ExercisesCompanion(
    id: Value('front_raise'),
    name: Value('Front Raise'),
    muscleIds: Value([MuscleId.frontDeltoid]),
    gifPath: Value('assets/exercises/front_raise.gif'),
  ),
  ExercisesCompanion(
    id: Value('rear_delt_fly'),
    name: Value('Rear Delt Fly'),
    muscleIds: Value([MuscleId.rearDeltoid, MuscleId.trapezius]),
    gifPath: Value('assets/exercises/rear_delt_fly.gif'),
  ),
  ExercisesCompanion(
    id: Value('face_pull'),
    name: Value('Face Pull'),
    muscleIds: Value([MuscleId.rearDeltoid, MuscleId.trapezius]),
    gifPath: Value('assets/exercises/face_pull.gif'),
  ),
  ExercisesCompanion(
    id: Value('upright_row'),
    name: Value('Upright Row'),
    muscleIds: Value([
      MuscleId.sideDeltoid,
      MuscleId.trapezius,
      MuscleId.biceps,
    ]),
    gifPath: Value('assets/exercises/upright_row.gif'),
    isPlateLoaded: Value(true),
  ),

  // ---------------- ARMS ----------------
  ExercisesCompanion(
    id: Value('barbell_biceps_curl'),
    name: Value('Barbell Biceps Curl'),
    muscleIds: Value([MuscleId.biceps, MuscleId.forearms]),
    gifPath: Value('assets/exercises/barbell_biceps_curl.gif'),
    isPlateLoaded: Value(true),
  ),
  ExercisesCompanion(
    id: Value('dumbbell_hammer_curl'),
    name: Value('Dumbbell Hammer Curl'),
    muscleIds: Value([MuscleId.biceps, MuscleId.forearms]),
    gifPath: Value('assets/exercises/dumbbell_hammer_curl.gif'),
  ),
  ExercisesCompanion(
    id: Value('incline_dumbbell_curl'),
    name: Value('Incline Dumbbell Curl'),
    muscleIds: Value([MuscleId.biceps]),
    gifPath: Value('assets/exercises/incline_dumbbell_curl.gif'),
  ),
  ExercisesCompanion(
    id: Value('preacher_curl'),
    name: Value('Preacher Curl'),
    muscleIds: Value([MuscleId.biceps]),
    gifPath: Value('assets/exercises/preacher_curl.gif'),
    isPlateLoaded: Value(true),
  ),
  ExercisesCompanion(
    id: Value('cable_curl'),
    name: Value('Cable Curl'),
    muscleIds: Value([MuscleId.biceps, MuscleId.forearms]),
    gifPath: Value('assets/exercises/cable_curl.gif'),
  ),
  ExercisesCompanion(
    id: Value('concentration_curl'),
    name: Value('Concentration Curl'),
    muscleIds: Value([MuscleId.biceps]),
    gifPath: Value('assets/exercises/concentration_curl.gif'),
  ),
  ExercisesCompanion(
    id: Value('reverse_curl'),
    name: Value('Reverse Curl'),
    muscleIds: Value([MuscleId.forearms, MuscleId.biceps]),
    gifPath: Value('assets/exercises/reverse_curl.gif'),
    isPlateLoaded: Value(true),
  ),
  ExercisesCompanion(
    id: Value('wrist_curl'),
    name: Value('Wrist Curl'),
    muscleIds: Value([MuscleId.forearms]),
    gifPath: Value('assets/exercises/wrist_curl.gif'),
    isPlateLoaded: Value(true),
  ),
  ExercisesCompanion(
    id: Value('triceps_pushdown'),
    name: Value('Triceps Pushdown'),
    muscleIds: Value([MuscleId.triceps]),
    gifPath: Value('assets/exercises/triceps_pushdown.gif'),
  ),
  ExercisesCompanion(
    id: Value('overhead_triceps_extension'),
    name: Value('Overhead Triceps Extension'),
    muscleIds: Value([MuscleId.triceps]),
    gifPath: Value('assets/exercises/overhead_triceps_extension.gif'),
  ),
  ExercisesCompanion(
    id: Value('skull_crusher'),
    name: Value('Skull Crusher'),
    muscleIds: Value([MuscleId.triceps]),
    gifPath: Value('assets/exercises/skull_crusher.gif'),
    isPlateLoaded: Value(true),
  ),
  ExercisesCompanion(
    id: Value('close_grip_bench_press'),
    name: Value('Close-Grip Bench Press'),
    muscleIds: Value([MuscleId.triceps, MuscleId.chest, MuscleId.frontDeltoid]),
    gifPath: Value('assets/exercises/close_grip_bench_press.gif'),
    isPlateLoaded: Value(true),
  ),
  ExercisesCompanion(
    id: Value('bench_dip'),
    name: Value('Bench Dip'),
    muscleIds: Value([MuscleId.triceps, MuscleId.frontDeltoid]),
    gifPath: Value('assets/exercises/bench_dip.gif'),
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
    isPlateLoaded: Value(true),
  ),
  ExercisesCompanion(
    id: Value('front_squat'),
    name: Value('Front Squat'),
    muscleIds: Value([MuscleId.quads, MuscleId.glutes, MuscleId.abs]),
    gifPath: Value('assets/exercises/front_squat.gif'),
    isPlateLoaded: Value(true),
  ),
  ExercisesCompanion(
    id: Value('goblet_squat'),
    name: Value('Goblet Squat'),
    muscleIds: Value([MuscleId.quads, MuscleId.glutes]),
    gifPath: Value('assets/exercises/goblet_squat.gif'),
  ),
  ExercisesCompanion(
    id: Value('hack_squat'),
    name: Value('Hack Squat'),
    muscleIds: Value([MuscleId.quads, MuscleId.glutes]),
    gifPath: Value('assets/exercises/hack_squat.gif'),
  ),
  ExercisesCompanion(
    id: Value('leg_press'),
    name: Value('Leg Press'),
    muscleIds: Value([MuscleId.quads, MuscleId.glutes, MuscleId.hamstrings]),
    gifPath: Value('assets/exercises/leg_press.gif'),
  ),
  ExercisesCompanion(
    id: Value('sumo_deadlift'),
    name: Value('Sumo Deadlift'),
    muscleIds: Value([
      MuscleId.glutes,
      MuscleId.quads,
      MuscleId.adductors,
      MuscleId.lowerBack,
    ]),
    gifPath: Value('assets/exercises/sumo_deadlift.gif'),
    isPlateLoaded: Value(true),
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
    isPlateLoaded: Value(true),
  ),
  ExercisesCompanion(
    id: Value('walking_lunge'),
    name: Value('Walking Lunge'),
    muscleIds: Value([MuscleId.quads, MuscleId.glutes, MuscleId.hamstrings]),
    gifPath: Value('assets/exercises/walking_lunge.gif'),
  ),
  ExercisesCompanion(
    id: Value('bulgarian_split_squat'),
    name: Value('Bulgarian Split Squat'),
    muscleIds: Value([MuscleId.quads, MuscleId.glutes, MuscleId.hamstrings]),
    gifPath: Value('assets/exercises/bulgarian_split_squat.gif'),
  ),
  ExercisesCompanion(
    id: Value('step_up'),
    name: Value('Step-Up'),
    muscleIds: Value([MuscleId.quads, MuscleId.glutes]),
    gifPath: Value('assets/exercises/step_up.gif'),
  ),
  ExercisesCompanion(
    id: Value('leg_extension'),
    name: Value('Leg Extension'),
    muscleIds: Value([MuscleId.quads]),
    gifPath: Value('assets/exercises/leg_extension.gif'),
  ),
  ExercisesCompanion(
    id: Value('lying_leg_curl'),
    name: Value('Lying Leg Curl'),
    muscleIds: Value([MuscleId.hamstrings]),
    gifPath: Value('assets/exercises/lying_leg_curl.gif'),
  ),
  ExercisesCompanion(
    id: Value('seated_leg_curl'),
    name: Value('Seated Leg Curl'),
    muscleIds: Value([MuscleId.hamstrings]),
    gifPath: Value('assets/exercises/seated_leg_curl.gif'),
  ),
  ExercisesCompanion(
    id: Value('barbell_hip_thrust'),
    name: Value('Barbell Hip Thrust'),
    muscleIds: Value([MuscleId.glutes, MuscleId.hamstrings]),
    gifPath: Value('assets/exercises/barbell_hip_thrust.gif'),
    isPlateLoaded: Value(true),
  ),
  ExercisesCompanion(
    id: Value('glute_bridge'),
    name: Value('Glute Bridge'),
    muscleIds: Value([MuscleId.glutes, MuscleId.hamstrings]),
    gifPath: Value('assets/exercises/glute_bridge.gif'),
  ),
  ExercisesCompanion(
    id: Value('hip_adduction'),
    name: Value('Hip Adduction'),
    muscleIds: Value([MuscleId.adductors]),
    gifPath: Value('assets/exercises/hip_adduction.gif'),
  ),
  ExercisesCompanion(
    id: Value('standing_calf_raise'),
    name: Value('Standing Calf Raise'),
    muscleIds: Value([MuscleId.calves]),
    gifPath: Value('assets/exercises/standing_calf_raise.gif'),
  ),
  ExercisesCompanion(
    id: Value('seated_calf_raise'),
    name: Value('Seated Calf Raise'),
    muscleIds: Value([MuscleId.calves]),
    gifPath: Value('assets/exercises/seated_calf_raise.gif'),
  ),

  // ---------------- CORE ----------------
  ExercisesCompanion(
    id: Value('plank'),
    name: Value('Plank'),
    muscleIds: Value([MuscleId.abs, MuscleId.obliques]),
    gifPath: Value('assets/exercises/plank.gif'),
  ),
  ExercisesCompanion(
    id: Value('side_plank'),
    name: Value('Side Plank'),
    muscleIds: Value([MuscleId.obliques, MuscleId.abs]),
    gifPath: Value('assets/exercises/side_plank.gif'),
  ),
  ExercisesCompanion(
    id: Value('crunch'),
    name: Value('Crunch'),
    muscleIds: Value([MuscleId.abs]),
    gifPath: Value('assets/exercises/crunch.gif'),
  ),
  ExercisesCompanion(
    id: Value('cable_crunch'),
    name: Value('Cable Crunch'),
    muscleIds: Value([MuscleId.abs]),
    gifPath: Value('assets/exercises/cable_crunch.gif'),
  ),
  ExercisesCompanion(
    id: Value('hanging_leg_raise'),
    name: Value('Hanging Leg Raise'),
    muscleIds: Value([MuscleId.abs, MuscleId.obliques]),
    gifPath: Value('assets/exercises/hanging_leg_raise.gif'),
  ),
  ExercisesCompanion(
    id: Value('ab_wheel_rollout'),
    name: Value('Ab Wheel Rollout'),
    muscleIds: Value([MuscleId.abs, MuscleId.obliques, MuscleId.lats]),
    gifPath: Value('assets/exercises/ab_wheel_rollout.gif'),
  ),
  ExercisesCompanion(
    id: Value('russian_twist'),
    name: Value('Russian Twist'),
    muscleIds: Value([MuscleId.obliques, MuscleId.abs]),
    gifPath: Value('assets/exercises/russian_twist.gif'),
  ),
  ExercisesCompanion(
    id: Value('bicycle_crunch'),
    name: Value('Bicycle Crunch'),
    muscleIds: Value([MuscleId.obliques, MuscleId.abs]),
    gifPath: Value('assets/exercises/bicycle_crunch.gif'),
  ),
  ExercisesCompanion(
    id: Value('mountain_climber'),
    name: Value('Mountain Climber'),
    muscleIds: Value([MuscleId.abs, MuscleId.obliques, MuscleId.quads]),
    gifPath: Value('assets/exercises/mountain_climber.gif'),
  ),

  // ---------------- FULL BODY ----------------
  ExercisesCompanion(
    id: Value('power_clean'),
    name: Value('Power Clean'),
    muscleIds: Value([
      MuscleId.trapezius,
      MuscleId.glutes,
      MuscleId.hamstrings,
      MuscleId.quads,
      MuscleId.lowerBack,
    ]),
    gifPath: Value('assets/exercises/power_clean.gif'),
    isPlateLoaded: Value(true),
  ),
  ExercisesCompanion(
    id: Value('push_press'),
    name: Value('Push Press'),
    muscleIds: Value([
      MuscleId.frontDeltoid,
      MuscleId.triceps,
      MuscleId.quads,
      MuscleId.trapezius,
    ]),
    gifPath: Value('assets/exercises/push_press.gif'),
    isPlateLoaded: Value(true),
  ),
  ExercisesCompanion(
    id: Value('kettlebell_swing'),
    name: Value('Kettlebell Swing'),
    muscleIds: Value([
      MuscleId.glutes,
      MuscleId.hamstrings,
      MuscleId.lowerBack,
    ]),
    gifPath: Value('assets/exercises/kettlebell_swing.gif'),
  ),
  ExercisesCompanion(
    id: Value('farmers_walk'),
    name: Value("Farmer's Walk"),
    muscleIds: Value([
      MuscleId.forearms,
      MuscleId.trapezius,
      MuscleId.abs,
      MuscleId.quads,
    ]),
    gifPath: Value('assets/exercises/farmers_walk.gif'),
  ),
];
