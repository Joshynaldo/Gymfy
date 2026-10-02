import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/l10n.dart';
import '../models/muscle_ids.dart';

/// Small helpers for turning exercise data into things we can show on screen.
/// Shared by the exercise list and detail screens.

/// Turns a muscle id like `front_deltoid` into a label like `Front Deltoid`.
///
/// Pass [l10n] (`context.l10n`) for the muscle's name in the app's language —
/// `Vordere Schulter` in German. Without it, or for an id the app doesn't
/// know, the id itself is title-cased, which is the English name for every
/// muscle in [MuscleId.all].
String muscleLabel(String id, {AppLocalizations? l10n}) {
  if (l10n != null) {
    final name = _muscleName(id, l10n);
    if (name != null) return name;
  }
  return id
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

String? _muscleName(String id, AppLocalizations l10n) => switch (id) {
  MuscleId.chest => l10n.muscleChest,
  MuscleId.frontDeltoid => l10n.muscleFrontDeltoid,
  MuscleId.sideDeltoid => l10n.muscleSideDeltoid,
  MuscleId.biceps => l10n.muscleBiceps,
  MuscleId.forearms => l10n.muscleForearms,
  MuscleId.abs => l10n.muscleAbs,
  MuscleId.obliques => l10n.muscleObliques,
  MuscleId.quads => l10n.muscleQuads,
  MuscleId.adductors => l10n.muscleAdductors,
  MuscleId.trapezius => l10n.muscleTrapezius,
  MuscleId.rearDeltoid => l10n.muscleRearDeltoid,
  MuscleId.lats => l10n.muscleLats,
  MuscleId.lowerBack => l10n.muscleLowerBack,
  MuscleId.triceps => l10n.muscleTriceps,
  MuscleId.glutes => l10n.muscleGlutes,
  MuscleId.hamstrings => l10n.muscleHamstrings,
  MuscleId.calves => l10n.muscleCalves,
  MuscleId.neck => l10n.muscleNeck,
  _ => null,
};

/// The icon shown next to any exercise.
///
/// One icon for everything, on purpose: exercises are grouped by the muscles
/// they train, and a per-exercise icon would have to invent some other
/// classification to vary on. The muscle names sit right there in the subtitle
/// and say more than a glyph could.
const IconData exerciseIcon = LucideIcons.dumbbell;
