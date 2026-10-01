import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/utils/dates.dart';
import '../../../shared/utils/session_length.dart';

part 'calendar_repository.g.dart';

/// One finished workout, as the calendar lists it under its day.
typedef CalendarSession = ({
  int id,
  String name,

  /// The day it counts on: when it finished, like the streak, the year grid
  /// and the recap.
  DateTime day,
  DateTime finishedAt,

  /// Null when not known — see [sessionLength].
  Duration? length,
  int sets,

  /// Started from no planned day.
  bool free,
});

/// Reads finished workouts a month at a time, for the training calendar.
class CalendarRepository {
  CalendarRepository(this._db);

  final AppDatabase _db;

  /// Every workout finished in the month starting [month], oldest first, with
  /// how many sets each one logged.
  ///
  /// Any finished session counts, with or without sets, matching the year
  /// grid beside it: "completed means trained" is the rule the streak uses
  /// too, and a day the grid shades must not be blank here.
  Stream<List<CalendarSession>> watchMonth(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);

    final query =
        _db.select(_db.workoutSessions).join([
            leftOuterJoin(
              _db.loggedSets,
              _db.loggedSets.sessionId.equalsExp(_db.workoutSessions.id),
            ),
          ])
          ..where(
            _db.workoutSessions.completedAt.isBiggerOrEqualValue(start) &
                _db.workoutSessions.completedAt.isSmallerThanValue(end),
          )
          ..orderBy([
            OrderingTerm(expression: _db.workoutSessions.completedAt),
            OrderingTerm(expression: _db.workoutSessions.id),
          ]);

    return query.watch().map((rows) {
      final sessions = <int, WorkoutSession>{};
      final sets = <int, int>{};
      for (final row in rows) {
        final session = row.readTable(_db.workoutSessions);
        sessions[session.id] = session;
        final set = row.readTableOrNull(_db.loggedSets);
        sets[session.id] = (sets[session.id] ?? 0) + (set == null ? 0 : 1);
      }
      return [
        for (final session in sessions.values)
          (
            id: session.id,
            name: session.name,
            day: dateOnly(session.completedAt!),
            finishedAt: session.completedAt!,
            length: sessionLength(session.startedAt, session.completedAt),
            sets: sets[session.id] ?? 0,
            free: session.dayId == null,
          ),
      ];
    });
  }
}

/// App-wide access to the [CalendarRepository].
@Riverpod(keepAlive: true)
CalendarRepository calendarRepository(Ref ref) {
  return CalendarRepository(ref.watch(appDatabaseProvider));
}

/// The workouts finished in one month, keyed by the month's first day.
///
/// Auto-disposed: paging back through a year would otherwise leave twelve
/// month queries open, each re-running on every set logged.
final calendarMonthProvider = StreamProvider.autoDispose
    .family<List<CalendarSession>, DateTime>((ref, month) {
      return ref.watch(calendarRepositoryProvider).watchMonth(month);
    });
