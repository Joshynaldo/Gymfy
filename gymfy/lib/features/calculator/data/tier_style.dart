import 'package:flutter/painting.dart' show Color;

import 'strength_standards.dart';

/// The colour and mark for each rank tier.
///
/// Fixed colours rather than theme ones, and one of only two places in the app
/// where that is right — the other being competition plates. A tier is a medal:
/// bronze, silver, gold and platinum mean something before you read the label,
/// and the ladder has to be legible at a glance across five emblems on one
/// screen. Tinting them with the accent would make all five the same hue and
/// throw away the only thing they are for.
///
/// Beginner is deliberately not a medal. It is where everyone starts, so it
/// gets neutral slate — earning bronze should feel like the first step up, not
/// like being demoted from a colour you already had.
const _tierColors = <StrengthTier, Color>{
  StrengthTier.beginner: Color(0xFF78849A),
  StrengthTier.novice: Color(0xFFC9803E),
  StrengthTier.intermediate: Color(0xFFAEB8C7),
  StrengthTier.advanced: Color(0xFFE3B44E),
  StrengthTier.elite: Color(0xFF7ED9F0),
};

/// The medal colour for [tier].
Color tierColor(StrengthTier tier) => _tierColors[tier]!;

/// How many pips an emblem shows: one for Beginner through five for Elite.
///
/// The colours alone carry the order for anyone who knows medals, but "is
/// platinum above gold?" is a real question and the count answers it without
/// needing a legend.
int tierPips(StrengthTier tier) => tier.index + 1;
