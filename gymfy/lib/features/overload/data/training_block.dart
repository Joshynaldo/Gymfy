// Training blocks: a split run for a set number of weeks, then a deload week,
// then round again.
//
// The planned counterpart to the overload deload in overload_math.dart, which
// *reacts* to a run of increases. A block deloads on the calendar instead — the
// way most written programmes do — so it is stored on the split itself
// (`block_weeks`, `deload_percent`, `block_started_at`) rather than in the
// app-wide overload settings.

import '../../../shared/database/app_database.dart';

/// The deload load when a split doesn't name one: 90 % of the working weight,
/// the same 10 % off the overload deload suggests.
const defaultDeloadPercent = 90.0;

/// Where a given day falls in a split's block.
class TrainingBlockWeek {
  const TrainingBlockWeek({
    required this.week,
    required this.blockWeeks,
    required this.cycle,
  });

  /// 1-based week within the current cycle: 1 … [blockWeeks] are training
  /// weeks, [blockWeeks] + 1 is the deload week.
  final int week;

  /// Training weeks per block (excluding the deload).
  final int blockWeeks;

  /// 1-based count of the cycle this week belongs to — the first block is
  /// cycle 1, the block after the first deload is cycle 2.
  final int cycle;

  bool get isDeload => week > blockWeeks;
}

/// Works out which week of the block [on] falls in.
///
/// Null when the split has no block ([blockWeeks] null or below 1), the block
/// hasn't been started ([startedAt] null), or [on] is before it began. Counted
/// in calendar days, so the time of day the block was started doesn't matter
/// and a daylight-saving change can't shift a week boundary.
TrainingBlockWeek? trainingBlockWeek({
  required int? blockWeeks,
  required DateTime? startedAt,
  required DateTime on,
}) {
  if (blockWeeks == null || blockWeeks < 1 || startedAt == null) return null;

  // UTC dates rather than local ones: a local day can be 23 or 25 hours long,
  // and `inDays` on that would occasionally come out one short.
  final start = DateTime.utc(startedAt.year, startedAt.month, startedAt.day);
  final day = DateTime.utc(on.year, on.month, on.day);
  final days = day.difference(start).inDays;
  if (days < 0) return null;

  final weeksIn = days ~/ 7;
  final cycleLength = blockWeeks + 1;
  return TrainingBlockWeek(
    week: weeksIn % cycleLength + 1,
    blockWeeks: blockWeeks,
    cycle: weeksIn ~/ cycleLength + 1,
  );
}

/// [trainingBlockWeek] for a split's stored block fields.
TrainingBlockWeek? trainingBlockWeekForSplit(Split split, DateTime on) {
  return trainingBlockWeek(
    blockWeeks: split.blockWeeks,
    startedAt: split.blockStartedAt,
    on: on,
  );
}

/// The deload week's load for [split], as a 0–100 percentage of the working
/// weight. Falls back to [defaultDeloadPercent] when the split names none, or
/// names something outside (0, 100] that no deload could mean.
double deloadPercentFor(Split split) {
  final stored = split.deloadPercent;
  if (stored == null || stored <= 0 || stored > 100) {
    return defaultDeloadPercent;
  }
  return stored;
}
