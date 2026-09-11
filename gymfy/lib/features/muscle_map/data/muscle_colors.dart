import 'package:flutter/material.dart';

import '../../../shared/models/muscle_ids.dart';

/// How the body diagram is coloured.
enum MuscleMapMode {
  /// One hue — the accent — with intensity carrying the information. Reads as a
  /// single picture of "how hard did I train", but neighbouring muscles at
  /// similar volumes are hard to tell apart.
  heatmap,

  /// A distinct hue per muscle group, still dimmed by intensity. Same data,
  /// but chest at 0.8 and front deltoid at 0.7 stop looking identical.
  contrast,
}

/// The heat colour for the fatigue reading.
///
/// Fixed red rather than the accent, and for once that is the point. Volume and
/// fatigue share one body diagram, so on a screen where you flip between them
/// the *colour* has to carry which one you are looking at — in the accent they
/// were the same picture twice, and a glance could not tell "I trained this
/// hard" from "this is not recovered". Red is also the one hue nobody has to be
/// taught here: it means sore, not ready, back off.
///
/// None of the six accent options is red, so for most users this reads as a
/// clearly different colour. It is not guaranteed: pink and orange are the
/// nearest neighbours, and a theme may suggest an accent of its own. Someone on
/// pink gets two warm hues rather than two identical ones — worth accepting,
/// because the alternative is denying them an accent they chose.
const fatigueColor = Color(0xFFE04B4B);

/// A distinct colour per muscle group, for [MuscleMapMode.contrast].
///
/// Chosen to be far apart from each other rather than anatomically meaningful —
/// the job is telling two adjacent regions apart at a glance. Hardcoded hex is
/// deliberate here for the same reason as the plate colours: these ARE the
/// data, not styling, and re-tinting them to the accent would defeat the mode.
///
/// Neighbouring regions on the diagram are deliberately given distant hues:
/// the front and side deltoid sit next to each other, so one is blue and the
/// other yellow rather than two shades of the same thing.
const _muscleColors = <String, Color>{
  // --- Front ---
  MuscleId.chest: Color(0xFFE15759), // red
  MuscleId.frontDeltoid: Color(0xFF4E79A7), // blue
  MuscleId.sideDeltoid: Color(0xFFEDC948), // yellow
  MuscleId.biceps: Color(0xFFFF9DA7), // pink
  MuscleId.forearms: Color(0xFFA0CBE8), // light blue
  MuscleId.abs: Color(0xFF8CD17D), // light green
  MuscleId.obliques: Color(0xFFF28E2B), // orange
  MuscleId.quads: Color(0xFF17BECF), // cyan
  MuscleId.adductors: Color(0xFF9C755F), // brown
  // --- Back ---
  MuscleId.trapezius: Color(0xFFD4A6C8), // light purple
  MuscleId.rearDeltoid: Color(0xFF59A14F), // green
  MuscleId.lats: Color(0xFF76B7B2), // teal
  MuscleId.lowerBack: Color(0xFFB6992D), // dark yellow
  MuscleId.triceps: Color(0xFF6B4C9A), // deep violet
  MuscleId.glutes: Color(0xFFBAB0AC), // warm grey
  MuscleId.hamstrings: Color(0xFFD37295), // dark pink
  MuscleId.calves: Color(0xFFFFBE7D), // peach
  // --- Neutral ---
  // No exercise in the library trains the neck, so it gets the one colour that
  // recedes rather than competing for attention.
  MuscleId.neck: Color(0xFF444B54), // dark slate
};

/// The contrast colour for a muscle, or a neutral slate for anything the map
/// knows about but this table doesn't.
///
/// A fallback rather than an assertion: a new muscle id should show up as an
/// unremarkable grey region, not crash the tab.
Color muscleColor(String muscleId) =>
    _muscleColors[muscleId] ?? const Color(0xFF9AA5B1);

/// Every muscle that has a colour of its own, in [MuscleId.all] order.
List<String> get colouredMuscles =>
    MuscleId.all.where(_muscleColors.containsKey).toList();
