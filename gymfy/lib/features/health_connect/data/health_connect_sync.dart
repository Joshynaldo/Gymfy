import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/data/settings_repository.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/models/body_measurement.dart';
import '../../../shared/utils/dates.dart';
import '../../../shared/utils/session_length.dart';
import '../../progress/data/measurements_repository.dart';
import '../../settings/data/notification_preferences.dart';
import 'health_connect_bridge.dart';

part 'health_connect_sync.g.dart';

// Settings keys. Flags and sync state all live in the key-value table, so
// Health Connect needed no schema change (see FEATURE_PLAN.md, "Settings
// keys"). Spelled once, here.

/// On/off: write finished workouts to Health Connect. Off unless switched on.
const healthConnectWriteKey = 'health_connect_write_workouts';

/// When writing was last switched on, ISO-8601. Only workouts finished after
/// it are written on their own; older ones wait for the explicit backfill.
const healthConnectWriteSinceKey = 'health_connect_write_since';

/// Which workouts are in Health Connect, as JSON `{"sessionId": "clientRecordId"}`.
///
/// Kept so a workout deleted in Gymfy can be deleted there too: once its row
/// is gone, this is the only place its record id survives.
const healthConnectWrittenKey = 'health_connect_written_sessions';

/// On/off: import weigh-ins as bodyweight. Off unless switched on.
const healthConnectReadKey = 'health_connect_read_bodyweight';

/// Which weigh-in became which day's bodyweight, as JSON
/// `{"2026-09-30": {"id": "…", "kg": 80.4}}`. See [planWeightImport].
const healthConnectWeightImportsKey = 'health_connect_weight_imports';

/// When weigh-ins were last read, ISO-8601.
const healthConnectWeightCheckedKey = 'health_connect_weight_checked_at';

/// Why the last sync failed, or unset if it worked. Shown in Settings: a sync
/// that has been quietly failing for a month is worse than none, because you
/// think your workouts are there.
const healthConnectLastErrorKey = 'health_connect_last_error';

/// How often coming back to the app re-checks Health Connect.
///
/// Opening the app always checks. Resuming happens between nearly every set —
/// phone down, phone up — and reading a month of weigh-ins each time would be
/// IPC for nothing on exactly the hardware that has least to spare.
const healthConnectResumeInterval = Duration(minutes: 15);

/// How many records go to Health Connect per call. A backfill of years of
/// training is hundreds of workouts, and one call per hundred keeps each
/// round trip small and well inside Health Connect's rate limits.
const healthConnectChunk = 100;

// ── Writing workouts ────────────────────────────────────────────────────────

/// The id a workout is written to Health Connect under.
///
/// Derived from the session, never random, so writing the same workout twice
/// replaces the first copy instead of adding a second — that is what makes a
/// retry, or the backfill after a normal write, harmless.
///
/// The start second is part of it, and not only the session id: ids are
/// reused after a reinstall or a wiped database, and Health Connect keeps
/// what an app wrote even when the app is gone. With the id alone, the first
/// workout on a fresh install would silently overwrite last year's first
/// workout. A session's start never changes once it exists.
String clientRecordIdFor(WorkoutSession session) =>
    'gymfy-session-${session.id}-'
    '${session.startedAt.millisecondsSinceEpoch ~/ 1000}';

/// What Health Connect is told about [session], or null when it must not be
/// written.
///
/// **A workout whose length is unknown is not written at all.** That is what
/// [sessionLength] returns null for on a finished session: an import whose
/// file had no usable end time, or a start and finish in the same second.
/// Health Connect requires an end after the start, so the only way to write
/// one would be to invent a duration — and an invented hour of strength
/// training lands in other apps' activity minutes and calorie estimates as if
/// it were measured. The app makes the same call everywhere else: "0 min" was
/// replaced with a dash rather than a guess. The backfill reports how many
/// were left out.
HealthConnectSession? healthConnectSessionFor(WorkoutSession session) {
  final completedAt = session.completedAt;
  if (sessionLength(session.startedAt, completedAt) == null) return null;
  return (
    clientRecordId: clientRecordIdFor(session),
    title: session.name,
    start: session.startedAt,
    end: completedAt!,
  );
}

/// What a workout sync should do.
typedef WorkoutSyncPlan = ({
  /// Workouts to write, oldest first, with the session each one is for.
  List<({int sessionId, HealthConnectSession record})> write,

  /// Records to delete, by the session id they were written for.
  Map<int, String> delete,

  /// Workouts that would have been written but have no known length.
  int untimed,
});

/// Works out which workouts to write to Health Connect and which to delete.
///
/// [sessions] are the finished workouts in Gymfy (unfinished ones are
/// ignored); [written] is what is already in Health Connect.
///
/// Written: every finished workout not already there, but only if it was
/// finished after [writeSince] — switching the feature on is not a request
/// to copy two years of history — unless [backfill] says so.
///
/// Deleted: every record whose workout is gone from Gymfy. Also any record
/// whose session id now belongs to a *different* workout (a restored backup
/// can do that), since it no longer describes anything that happened.
WorkoutSyncPlan planWorkoutSync({
  required List<WorkoutSession> sessions,
  required Map<int, String> written,
  required DateTime? writeSince,
  bool backfill = false,
}) {
  final finished = {
    for (final session in sessions)
      if (session.completedAt != null) session.id: session,
  };

  final delete = <int, String>{};
  for (final MapEntry(key: id, value: recordId) in written.entries) {
    final session = finished[id];
    if (session == null || clientRecordIdFor(session) != recordId) {
      delete[id] = recordId;
    }
  }

  final write = <({int sessionId, HealthConnectSession record})>[];
  var untimed = 0;
  for (final session in finished.values) {
    if (written[session.id] == clientRecordIdFor(session)) continue;
    final due =
        backfill ||
        (writeSince != null && !session.completedAt!.isBefore(writeSince));
    if (!due) continue;
    final record = healthConnectSessionFor(session);
    if (record == null) {
      untimed++;
    } else {
      write.add((sessionId: session.id, record: record));
    }
  }
  write.sort((a, b) => a.record.start.compareTo(b.record.start));

  return (write: write, delete: delete, untimed: untimed);
}

/// Reads the written-workouts ledger. Junk reads as empty: rewriting is
/// harmless (the ids are stable), and guessing is not.
Map<int, String> decodeWrittenSessions(String? raw) {
  final decoded = _tryDecode(raw);
  if (decoded is! Map) return {};
  return {
    for (final MapEntry(:key, :value) in decoded.entries)
      if (int.tryParse('$key') case final id? when value is String) id: value,
  };
}

String encodeWrittenSessions(Map<int, String> written) =>
    jsonEncode({for (final e in written.entries) '${e.key}': e.value});

// ── Reading bodyweight ──────────────────────────────────────────────────────

/// One weigh-in Gymfy has made a day's bodyweight: which record, and the
/// value it wrote — the value is how a later edit by hand is recognised.
typedef WeightImportEntry = ({String id, double kg});

/// A bodyweight to write.
typedef WeightImport = ({
  DateTime day,
  double kg,
  String recordId,

  /// What the day holds now, which must still be there when the write
  /// happens — null for an empty day.
  double? replaces,
});

/// The calendar day a weigh-in belongs to: the day it was where the scale
/// stood, when the writing app recorded the offset, else the phone's own.
DateTime weighInDay(HealthConnectWeighIn record) {
  final offset = record.offsetSeconds;
  if (offset == null) return dateOnly(record.time.toLocal());
  final there = record.time.toUtc().add(Duration(seconds: offset));
  return DateTime(there.year, there.month, there.day);
}

/// The settings key for a day in [healthConnectWeightImportsKey].
String weighInDayKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// Kilograms to two decimals: what a scale means, without the float noise of
/// a pound value converted on the way in (176.4 lb is 80.0136 kg).
double roundKg(double kg) => (kg * 100).round() / 100;

/// How far back weigh-ins are read.
///
/// At least thirty days on every check — a scale's own app can sync to
/// Health Connect days after the weigh-in, and thirty days is also as far
/// back as Health Connect lets a newly permitted app look. Further, from just
/// before the last check, if that was longer ago, so a month away from the
/// app leaves no gap.
DateTime weighInWindowStart({required DateTime now, DateTime? lastChecked}) {
  final month = now.subtract(const Duration(days: 30));
  if (lastChecked == null) return month;
  final sinceLast = lastChecked.subtract(const Duration(days: 2));
  return sinceLast.isBefore(month) ? sinceLast : month;
}

/// Decides which weigh-ins become a day's bodyweight.
///
/// Gymfy keeps one bodyweight per day, so each day takes its **first**
/// weigh-in: the morning reading is the one people track, and a value that
/// does not change when you step on the scale again at night is one you can
/// trust.
///
/// Two promises, both kept by [imported] — the record and the value written
/// for each day:
///
///  - **A value typed by hand is never overwritten.** A day with a weight
///    and no import behind it is yours. So is a day whose imported value you
///    have since changed or cleared: it no longer matches what was written,
///    and it is left alone for good.
///  - **A record is never imported twice.** A day already holding a record's
///    value is skipped. Only if the day still holds the untouched import and
///    its first weigh-in is now a different record — the earlier one deleted
///    in Health Connect, or an earlier one synced late — does the day follow
///    it.
///
/// [current] is Gymfy's weight for each day that has a measurement row.
List<WeightImport> planWeightImport({
  required List<HealthConnectWeighIn> records,
  required Map<DateTime, double?> current,
  required Map<String, WeightImportEntry> imported,
}) {
  final firstOfDay = <DateTime, HealthConnectWeighIn>{};
  for (final record in records) {
    if (!record.kg.isFinite || record.kg <= 0) continue;
    final day = weighInDay(record);
    final seen = firstOfDay[day];
    final earlier =
        seen == null ||
        record.time.isBefore(seen.time) ||
        (record.time == seen.time && record.id.compareTo(seen.id) < 0);
    if (earlier) firstOfDay[day] = record;
  }

  final plan = <WeightImport>[];
  for (final MapEntry(key: day, value: record) in firstOfDay.entries) {
    final now = current[day];
    final previous = imported[weighInDayKey(day)];
    if (previous == null) {
      // Nothing imported here before, so a value is one you typed.
      if (now != null) continue;
    } else {
      if (previous.id == record.id) continue;
      // Changed or cleared by hand since the import.
      if (now == null || !_sameKg(now, previous.kg)) continue;
    }
    plan.add((
      day: day,
      kg: roundKg(record.kg),
      recordId: record.id,
      replaces: now,
    ));
  }
  plan.sort((a, b) => a.day.compareTo(b.day));
  return plan;
}

bool _sameKg(double a, double b) => (a - b).abs() < 1e-9;

/// Reads the weigh-in ledger. Junk reads as empty, which errs towards
/// leaving days alone: with no ledger, every filled day counts as typed.
Map<String, WeightImportEntry> decodeWeightImports(String? raw) {
  final decoded = _tryDecode(raw);
  if (decoded is! Map) return {};
  return {
    for (final MapEntry(:key, :value) in decoded.entries)
      if (value case {'id': final String id, 'kg': final num kg})
        '$key': (id: id, kg: kg.toDouble()),
  };
}

String encodeWeightImports(Map<String, WeightImportEntry> imported) =>
    jsonEncode({
      for (final MapEntry(:key, :value) in imported.entries)
        key: {'id': value.id, 'kg': value.kg},
    });

Object? _tryDecode(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    return jsonDecode(raw);
  } on FormatException {
    return null;
  }
}

// ── The service ─────────────────────────────────────────────────────────────

/// How a workout sync went.
typedef WorkoutSyncResult = ({
  int written,
  int deleted,

  /// Left out because their length is unknown — see [healthConnectSessionFor].
  int untimed,

  /// Why it stopped early, or null if it finished.
  String? error,
});

/// Keeps Health Connect and Gymfy in step, both directions.
///
/// Does nothing — not even ask Health Connect anything — unless the matching
/// switch is on and its permission is granted, so for everyone who never
/// turns this on it costs one settings read per trigger.
class HealthConnectSync {
  HealthConnectSync(this._db, this._settings, this._measurements, this._bridge);

  final AppDatabase _db;
  final SettingsRepository _settings;
  final MeasurementsRepository _measurements;
  final HealthConnectBridge _bridge;

  Future<void> _tail = Future<void>.value();

  /// Runs [task] after any sync already in flight. Finishing a workout as the
  /// app resumes fires two triggers at once, and two syncs reading the same
  /// ledger side by side would both write — and the second save would forget
  /// the first one's records.
  Future<T> _serially<T>(Future<T> Function() task) {
    final run = _tail.then((_) => task());
    _tail = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  /// Switches writing on or off. Switching on starts the clock: workouts
  /// finished from now on are written by themselves.
  Future<void> setWriteWorkouts(bool on) async {
    if (on) {
      await _settings.write(
        healthConnectWriteSinceKey,
        clock.now().toIso8601String(),
      );
    }
    await _settings.write(healthConnectWriteKey, '$on');
  }

  /// Switches the bodyweight import on or off.
  Future<void> setReadBodyweight(bool on) =>
      _settings.write(healthConnectReadKey, '$on');

  /// Everything that is switched on: workouts out, weigh-ins in.
  Future<void> syncAll() async {
    await syncWorkouts();
    await importBodyweight();
  }

  /// Writes newly finished workouts and deletes the records of removed ones.
  /// With [backfill], writes every finished workout not yet in Health
  /// Connect, however old.
  ///
  /// Null when writing is off or not permitted. Never throws; a failure is
  /// recorded under [healthConnectLastErrorKey] and in the result.
  Future<WorkoutSyncResult?> syncWorkouts({bool backfill = false}) =>
      _serially(() => _syncWorkouts(backfill: backfill));

  Future<WorkoutSyncResult?> _syncWorkouts({required bool backfill}) async {
    if (!await _flag(healthConnectWriteKey)) return null;
    if (!await _granted(writeExercisePermission)) return null;

    final sessions = await (_db.select(
      _db.workoutSessions,
    )..where((t) => t.completedAt.isNotNull())).get();
    final ledger = decodeWrittenSessions(
      await _settings.readRaw(healthConnectWrittenKey),
    );
    final plan = planWorkoutSync(
      sessions: sessions,
      written: ledger,
      writeSince: DateTime.tryParse(
        await _settings.readRaw(healthConnectWriteSinceKey) ?? '',
      ),
      backfill: backfill,
    );

    var written = 0;
    var deleted = 0;
    try {
      // The ledger is saved after every chunk, so a failure halfway through
      // a backfill keeps what did get written and retries only the rest.
      for (final chunk in _chunks(plan.delete.entries.toList())) {
        await _bridge.deleteSessions([for (final e in chunk) e.value]);
        for (final e in chunk) {
          ledger.remove(e.key);
        }
        deleted += chunk.length;
        await _saveLedger(ledger);
      }
      for (final chunk in _chunks(plan.write)) {
        await _bridge.writeSessions([for (final w in chunk) w.record]);
        for (final w in chunk) {
          ledger[w.sessionId] = w.record.clientRecordId;
        }
        written += chunk.length;
        await _saveLedger(ledger);
      }
      await _settings.clear(healthConnectLastErrorKey);
      return (
        written: written,
        deleted: deleted,
        untimed: plan.untimed,
        error: null,
      );
    } catch (error) {
      await _settings.write(healthConnectLastErrorKey, '$error');
      return (
        written: written,
        deleted: deleted,
        untimed: plan.untimed,
        error: '$error',
      );
    }
  }

  /// Reads weigh-ins and makes them bodyweight where [planWeightImport] says
  /// so. Returns how many days were filled, or null when reading is off, not
  /// permitted, or failed (recorded under [healthConnectLastErrorKey]).
  Future<int?> importBodyweight() => _serially(_importBodyweight);

  Future<int?> _importBodyweight() async {
    if (!await _flag(healthConnectReadKey)) return null;
    if (!await _granted(readWeightPermission)) return null;

    try {
      final now = clock.now();
      final from = weighInWindowStart(
        now: now,
        lastChecked: DateTime.tryParse(
          await _settings.readRaw(healthConnectWeightCheckedKey) ?? '',
        ),
      );
      final records = await _bridge.readWeights(from: from, to: now);

      final days = {for (final record in records) weighInDay(record)};
      final rows = days.isEmpty
          ? const <BodyMeasurement>[]
          : await (_db.select(
              _db.bodyMeasurements,
            )..where((t) => t.date.isIn(days))).get();
      final imported = decodeWeightImports(
        await _settings.readRaw(healthConnectWeightImportsKey),
      );
      final plan = planWeightImport(
        records: records,
        current: {for (final row in rows) dateOnly(row.date): row.weightKg},
        imported: imported,
      );

      var filled = 0;
      await _db.transaction(() async {
        for (final item in plan) {
          final row = await (_db.select(
            _db.bodyMeasurements,
          )..where((t) => t.date.equals(item.day))).getSingleOrNull();
          // Typed in between the read and now: the hand-typed value wins.
          if (row?.weightKg != item.replaces) continue;
          await _measurements.setField(
            day: item.day,
            field: MeasurementField.weight,
            value: item.kg,
          );
          imported[weighInDayKey(item.day)] = (id: item.recordId, kg: item.kg);
          filled++;
        }
        // Days before this read's window are never read again (the window
        // only ever moves forward), so their entries can go. Keeps the
        // ledger at about a month instead of growing for ever.
        final oldest = weighInDayKey(
          dateOnly(from).subtract(const Duration(days: 1)),
        );
        imported.removeWhere((day, _) => day.compareTo(oldest) < 0);
        await _settings.write(
          healthConnectWeightImportsKey,
          encodeWeightImports(imported),
        );
        await _settings.write(
          healthConnectWeightCheckedKey,
          now.toIso8601String(),
        );
      });
      await _settings.clear(healthConnectLastErrorKey);
      return filled;
    } catch (error) {
      await _settings.write(healthConnectLastErrorKey, '$error');
      return null;
    }
  }

  Future<bool> _flag(String key) async =>
      parseFlag(await _settings.readRaw(key), orElse: false);

  /// Whether Health Connect is there and grants [permission]. Asked fresh:
  /// permissions are revoked in Health Connect, where Gymfy cannot see it.
  Future<bool> _granted(String permission) async {
    if (await _bridge.availability() != HealthConnectAvailability.available) {
      return false;
    }
    return (await _bridge.grantedPermissions()).contains(permission);
  }

  Future<void> _saveLedger(Map<int, String> ledger) =>
      _settings.write(healthConnectWrittenKey, encodeWrittenSessions(ledger));
}

Iterable<List<T>> _chunks<T>(List<T> items) sync* {
  for (var i = 0; i < items.length; i += healthConnectChunk) {
    yield items.sublist(
      i,
      i + healthConnectChunk > items.length
          ? items.length
          : i + healthConnectChunk,
    );
  }
}

/// App-wide access to the [HealthConnectSync].
@Riverpod(keepAlive: true)
HealthConnectSync healthConnectSync(Ref ref) => HealthConnectSync(
  ref.watch(appDatabaseProvider),
  ref.watch(settingsRepositoryProvider),
  ref.watch(measurementsRepositoryProvider),
  ref.watch(healthConnectBridgeProvider),
);

/// Whether finished workouts are written to Health Connect.
final healthConnectWriteProvider = StreamProvider<bool>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchRaw(healthConnectWriteKey)
      .map((raw) => parseFlag(raw, orElse: false));
});

/// Whether weigh-ins are imported from Health Connect.
final healthConnectReadProvider = StreamProvider<bool>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchRaw(healthConnectReadKey)
      .map((raw) => parseFlag(raw, orElse: false));
});

/// The ids of every finished workout, in id order.
///
/// Changes exactly when a workout is finished or deleted, which are the two
/// moments Health Connect has to hear about. Ids only, so the query stays
/// cheap however long the history gets.
final completedSessionIdsProvider = StreamProvider<List<int>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final sessions = db.workoutSessions;
  final query = db.selectOnly(sessions)
    ..addColumns([sessions.id])
    ..where(sessions.completedAt.isNotNull())
    ..orderBy([OrderingTerm(expression: sessions.id)]);
  return query.map((row) => row.read(sessions.id)!).watch();
});

/// Runs Health Connect syncs at the moments that matter.
///
/// Watched from the app root, like the watch sync and automatic backups,
/// because those moments — opening the app, finishing or deleting a workout —
/// happen on screens that have nothing to do with Health Connect.
///
/// There is no background job: that would need WorkManager, a new plugin,
/// and Health Connect only lets an app read while it is in the foreground
/// anyway. So weigh-ins arrive when the app is opened.
@Riverpod(keepAlive: true)
class HealthConnectWatcher extends _$HealthConnectWatcher {
  DateTime? _lastRun;

  @override
  void build() {
    final sync = ref.watch(healthConnectSyncProvider);

    void run() {
      _lastRun = clock.now();
      unawaited(sync.syncAll());
    }

    // After the first frame: the least urgent thing the app does at launch.
    Future<void>.delayed(Duration.zero, run);

    final lifecycle = AppLifecycleListener(
      onResume: () {
        final last = _lastRun;
        if (last == null ||
            clock.now().difference(last) >= healthConnectResumeInterval) {
          run();
        }
      },
    );
    ref.onDispose(lifecycle.dispose);

    ref.listen(completedSessionIdsProvider, (previous, next) {
      // The first value is what was already there at launch, not a change.
      if (previous == null || !previous.hasValue || !next.hasValue) return;
      if (listEquals(previous.value, next.value)) return;
      unawaited(sync.syncWorkouts());
    });
  }
}
