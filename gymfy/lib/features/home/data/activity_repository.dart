import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/utils/dates.dart';

part 'activity_repository.g.dart';

/// One finished workout, reduced to when it ended and how long it took.
typedef ActivitySession = ({DateTime endedAt, Duration length});

/// How many weeks the heatmap shows. 53 so that a full year is always covered
/// even when the first column is a part-week.
const activityWeeks = 53;

/// Shade thresholds, in minutes trained on one day.
///
/// Fixed rather than scaled to your own best day, for the same reason the
/// fatigue map isn't normalized: on a quiet year, relative shading would paint
/// a twenty-minute session the same dark green as a two-hour one and tell you
/// nothing. These are minutes, and they mean minutes.
const activityLevelMinutes = [30, 60, 90];

/// Reads finished workouts for the Home tab's activity heatmap.
class ActivityRepository {
  ActivityRepository(this._db);

  final AppDatabase _db;

  /// Streams every completed session that could land on the grid ending [today].
  Stream<Map<DateTime, int>> watchMinutesByDay(DateTime today) {
    final firstDay = activityGridStart(today);

    final query = _db.select(_db.workoutSessions)
      ..where(
        (t) =>
            t.completedAt.isNotNull() &
            t.completedAt.isBiggerOrEqualValue(firstDay),
      );

    return query.watch().map((rows) {
      return minutesByDay([
        for (final row in rows)
          (
            // Dated by when it finished, matching the streak and the recap: a
            // session that ran past midnight counts once, on the day it ended.
            endedAt: row.completedAt!,
            length: row.completedAt!.difference(row.startedAt),
          ),
      ]);
    });
  }
}

/// Midnight of the Monday that opens the heatmap ending on [today].
///
/// Aligned to a Monday so every column is a whole week and the weekday rows
/// line up — a grid that started on an arbitrary day would put Tuesdays in the
/// Monday row for the first column only.
DateTime activityGridStart(DateTime today) {
  final end = dateOnly(today);
  // Back to this week's Monday (weekday 1), then back the remaining weeks.
  final thisMonday = end.subtract(Duration(days: end.weekday - 1));
  return DateTime(
    thisMonday.year,
    thisMonday.month,
    thisMonday.day - (activityWeeks - 1) * 7,
  );
}

/// Total minutes trained per calendar day.
///
/// Two sessions on one day add up — training twice is one busier day, not two
/// half-days, and the grid has one cell to say so.
///
/// **A finished session always counts, however short.** It is rounded up to a
/// minute rather than dropped: `inMinutes` truncates, so a workout wrapped up
/// in forty seconds came out as zero and vanished from the grid entirely. That
/// is exactly what a first workout on a fresh install looks like, which made
/// the whole feature appear broken to anyone trying it for the first time.
/// "Completed means trained" is also the rule the streak already uses, and the
/// two disagreeing would be worse than either being wrong.
///
/// Only a negative length is dropped, which means the clock moved rather than
/// that any training happened.
Map<DateTime, int> minutesByDay(Iterable<ActivitySession> sessions) {
  final totals = <DateTime, int>{};
  for (final session in sessions) {
    if (session.length.isNegative) continue;
    final minutes = session.length.inMinutes < 1 ? 1 : session.length.inMinutes;
    final day = dateOnly(session.endedAt);
    totals[day] = (totals[day] ?? 0) + minutes;
  }
  return totals;
}

/// Number of distinct shades, counting "untrained" as one of them.
///
/// Written out rather than derived from [activityLevelMinutes.length]: a list's
/// length isn't a constant expression, and the palette this sizes has to be
/// checked against it in a test anyway.
const activityShades = 5;

/// Which shade a day gets.
///
/// 0 is untrained; 1 is any training at all below the first threshold, then one
/// step per threshold passed. With the default thresholds: 1–29 min, 30–59,
/// 60–89, 90+. The lowest shade is deliberately reachable by a single short
/// session — "I turned up" is the distinction the grid is most often asked to
/// make.
int activityLevel(int minutes) {
  if (minutes <= 0) return 0;
  var level = 1;
  for (final threshold in activityLevelMinutes) {
    if (minutes >= threshold) level++;
  }
  return level;
}

/// App-wide access to the [ActivityRepository].
@Riverpod(keepAlive: true)
ActivityRepository activityRepository(Ref ref) {
  return ActivityRepository(ref.watch(appDatabaseProvider));
}

/// Minutes trained per day over the last year.
///
/// Reads the clock once per watch. The grid only changes shape at midnight, and
/// a provider that ticked to catch that would rebuild the Home tab all day to
/// redraw the same squares.
final activityMinutesProvider = StreamProvider<Map<DateTime, int>>((ref) {
  return ref.watch(activityRepositoryProvider).watchMinutesByDay(
    DateTime.now(),
  );
});
