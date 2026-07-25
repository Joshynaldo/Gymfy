/// Canonical muscle identifiers used across the whole app.
///
/// These strings are the SINGLE SOURCE OF TRUTH shared by:
/// - each Exercise's `muscleIds` list (see [Exercises] in exercise.dart), and
/// - the SVG body-map path IDs we build in Phase 5.
///
/// Keep the two in sync: a typo here won't be caught by the compiler, it will
/// just silently fail to light up a muscle on the heatmap later.
class MuscleId {
  const MuscleId._();

  // --- Front of body ---
  static const String chest = 'chest';
  static const String frontDeltoid = 'front_deltoid';
  static const String sideDeltoid = 'side_deltoid';
  static const String biceps = 'biceps';
  static const String forearms = 'forearms';
  static const String abs = 'abs';
  static const String obliques = 'obliques';
  static const String quads = 'quads';
  static const String adductors = 'adductors';

  // --- Back of body ---
  static const String trapezius = 'trapezius';
  static const String rearDeltoid = 'rear_deltoid';
  static const String lats = 'lats';
  static const String lowerBack = 'lower_back';
  static const String triceps = 'triceps';
  static const String glutes = 'glutes';
  static const String hamstrings = 'hamstrings';
  static const String calves = 'calves';

  // --- Neutral / either side ---
  static const String neck = 'neck';

  /// Every known muscle id — handy for validating seed data and for building
  /// the Phase 5 muscle map.
  static const List<String> all = [
    chest,
    frontDeltoid,
    sideDeltoid,
    biceps,
    forearms,
    abs,
    obliques,
    quads,
    adductors,
    trapezius,
    rearDeltoid,
    lats,
    lowerBack,
    triceps,
    glutes,
    hamstrings,
    calves,
    neck,
  ];
}
