// Health Connect sync against a real (in-memory) database and a fake Health
// Connect: what gets written, deleted and imported, and — the part the
// privacy policy promises — what never does.

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/health_connect/data/health_connect_bridge.dart';
import 'package:gymfy/features/health_connect/data/health_connect_sync.dart';
import 'package:gymfy/features/progress/data/measurements_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/shared/data/settings_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/models/body_measurement.dart';

import 'support/fake_health_connect.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository settings;
  late MeasurementsRepository measurements;
  late FakeHealthConnect health;
  late HealthConnectSync sync;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    settings = SettingsRepository(db);
    measurements = MeasurementsRepository(db);
    health = FakeHealthConnect();
    sync = HealthConnectSync(db, settings, measurements, health);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> finished(DateTime start, {Duration? length, String? name}) {
    return db
        .into(db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            name: name ?? 'Push A',
            startedAt: Value(start),
            completedAt: Value(start.add(length ?? const Duration(hours: 1))),
          ),
        );
  }

  Future<void> writeOn({required DateTime since}) =>
      withClock(Clock.fixed(since), () => sync.setWriteWorkouts(true));

  group('writing workouts', () {
    final since = DateTime(2026, 9, 10);

    test('does nothing while switched off', () async {
      await finished(DateTime(2026, 9, 12, 18));
      expect(await sync.syncWorkouts(), isNull);
      expect(health.writeCalls, isEmpty);
    });

    test('does nothing without the permission', () async {
      await writeOn(since: since);
      health.granted = {readWeightPermission};
      await finished(DateTime(2026, 9, 12, 18));
      expect(await sync.syncWorkouts(), isNull);
      expect(health.writeCalls, isEmpty);
    });

    test('writes a finished workout as strength training, once', () async {
      await writeOn(since: since);
      final id = await finished(
        DateTime(2026, 9, 12, 18),
        length: const Duration(minutes: 75),
        name: 'Legs',
      );

      final result = await sync.syncWorkouts();
      expect(result?.written, 1);
      final record = health.sessions.values.single;
      expect(record.title, 'Legs');
      expect(record.start, DateTime(2026, 9, 12, 18));
      expect(record.end, DateTime(2026, 9, 12, 19, 15));
      expect(
        decodeWrittenSessions(await settings.readRaw(healthConnectWrittenKey)),
        {id: record.clientRecordId},
      );

      // Every trigger runs this again; none of them may write it again.
      await sync.syncWorkouts();
      await sync.syncWorkouts();
      expect(health.writeCalls, hasLength(1));
    });

    test(
      'leaves workouts from before it was switched on to the backfill',
      () async {
        await finished(DateTime(2026, 9, 1, 18));
        await finished(DateTime(2026, 9, 2, 18), length: Duration.zero);
        await writeOn(since: since);

        expect((await sync.syncWorkouts())?.written, 0);
        expect(health.sessions, isEmpty);

        final backfill = await sync.syncWorkouts(backfill: true);
        expect(backfill?.written, 1);
        expect(
          backfill?.untimed,
          1,
          reason: 'the one with no recorded length is reported, not written',
        );
        expect(health.sessions, hasLength(1));
      },
    );

    test('a backfill of years goes in chunks, and only once', () async {
      for (var i = 0; i < 250; i++) {
        await finished(DateTime(2024, 1, 1, 18).add(Duration(days: i)));
      }
      await writeOn(since: since);

      final result = await sync.syncWorkouts(backfill: true);
      expect(result?.written, 250);
      expect([for (final c in health.writeCalls) c.length], [100, 100, 50]);

      await sync.syncWorkouts(backfill: true);
      expect(health.writeCalls, hasLength(3));
    });

    test('deleting a workout deletes its record', () async {
      await writeOn(since: since);
      final keep = await finished(DateTime(2026, 9, 12, 18));
      final gone = await finished(DateTime(2026, 9, 13, 18));
      await sync.syncWorkouts();
      expect(health.sessions, hasLength(2));

      await SessionRepository(db).deleteSession(gone);
      final result = await sync.syncWorkouts();

      expect(result?.deleted, 1);
      expect(health.sessions, hasLength(1));
      expect(
        decodeWrittenSessions(
          await settings.readRaw(healthConnectWrittenKey),
        ).keys,
        [keep],
      );
    });

    test(
      'a failure is recorded, kept progress is kept, and it retries',
      () async {
        await writeOn(since: since);
        await finished(DateTime(2026, 9, 12, 18));
        health.failWith = 'Health Connect is busy';

        final failed = await sync.syncWorkouts();
        expect(failed?.error, contains('busy'));
        expect(
          await settings.readRaw(healthConnectLastErrorKey),
          contains('busy'),
        );

        health.failWith = null;
        final retried = await sync.syncWorkouts();
        expect(retried?.written, 1);
        expect(await settings.readRaw(healthConnectLastErrorKey), isNull);
      },
    );

    test('two triggers at once write once', () async {
      // Finishing a workout as the app resumes fires both. Side by side they
      // would each read an empty ledger and each write.
      await writeOn(since: since);
      await finished(DateTime(2026, 9, 12, 18));
      await Future.wait([sync.syncWorkouts(), sync.syncWorkouts()]);
      expect(health.writeCalls, hasLength(1));
    });

    test('switching on again restarts the clock', () async {
      await writeOn(since: since);
      await sync.setWriteWorkouts(false);
      await finished(DateTime(2026, 9, 20, 18));
      await writeOn(since: DateTime(2026, 9, 25));

      expect((await sync.syncWorkouts())?.written, 0);
    });
  });

  group('reading bodyweight', () {
    final now = DateTime(2026, 10, 1, 12);
    final monday = DateTime(2026, 9, 28);

    Future<int?> importAt(DateTime at) =>
        withClock(Clock.fixed(at), () => sync.importBodyweight());

    Future<double?> weightOn(DateTime day) async {
      final rows = await measurements.watchAll().first;
      for (final row in rows) {
        if (row.date == day) return row.weightKg;
      }
      return null;
    }

    setUp(() async {
      await sync.setReadBodyweight(true);
      health.weights = [
        (
          id: 'mon-am',
          time: DateTime(2026, 9, 28, 7),
          offsetSeconds: null,
          kg: 80.4,
        ),
        (
          id: 'mon-pm',
          time: DateTime(2026, 9, 28, 21),
          offsetSeconds: null,
          kg: 81.3,
        ),
      ];
    });

    test('does nothing while switched off', () async {
      await sync.setReadBodyweight(false);
      expect(await importAt(now), isNull);
      expect(health.readWindows, isEmpty);
    });

    test('does nothing without the permission', () async {
      health.granted = {writeExercisePermission};
      expect(await importAt(now), isNull);
      expect(health.readWindows, isEmpty);
    });

    test('fills an empty day with its first weigh-in', () async {
      expect(await importAt(now), 1);
      expect(await weightOn(monday), 80.4);
      expect(
        health.readWindows.single.from,
        now.subtract(const Duration(days: 30)),
      );
    });

    test('never imports the same record twice', () async {
      await importAt(now);
      expect(await importAt(now.add(const Duration(hours: 1))), 0);
      expect(await weightOn(monday), 80.4);
    });

    test('never overwrites a weight typed by hand', () async {
      await measurements.setField(
        day: monday,
        field: MeasurementField.weight,
        value: 82,
      );
      expect(await importAt(now), 0);
      expect(await weightOn(monday), 82);
    });

    test('a value changed by hand after the import stays changed', () async {
      await importAt(now);
      await measurements.setField(
        day: monday,
        field: MeasurementField.weight,
        value: 79.5,
      );
      health.weights = [
        ...health.weights,
        (
          id: 'mon-dawn',
          time: DateTime(2026, 9, 28, 5),
          offsetSeconds: null,
          kg: 80.0,
        ),
      ];

      expect(await importAt(now.add(const Duration(hours: 1))), 0);
      expect(await weightOn(monday), 79.5);
    });

    test('a value cleared by hand is not filled back in', () async {
      await importAt(now);
      await measurements.setField(
        day: monday,
        field: MeasurementField.weight,
        value: null,
      );
      expect(await importAt(now.add(const Duration(hours: 1))), 0);
      expect(await weightOn(monday), isNull);
    });

    test('leaves the other measurements of the day alone', () async {
      await measurements.setField(
        day: monday,
        field: MeasurementField.waist,
        value: 84,
      );
      await importAt(now);
      final row = (await measurements.watchAll().first).single;
      expect(row.weightKg, 80.4);
      expect(row.waistCm, 84);
    });

    test('a failed read is recorded and changes nothing', () async {
      health.failWith = 'not allowed in the background';
      expect(await importAt(now), isNull);
      expect(
        await settings.readRaw(healthConnectLastErrorKey),
        contains('background'),
      );
      expect(await weightOn(monday), isNull);
      expect(await settings.readRaw(healthConnectWeightCheckedKey), isNull);
    });

    test('the ledger only keeps what can still be read again', () async {
      health.weights = [
        (id: 'old', time: DateTime(2026, 8, 1, 7), offsetSeconds: null, kg: 82),
      ];
      await importAt(DateTime(2026, 8, 2));
      expect(
        decodeWeightImports(
          await settings.readRaw(healthConnectWeightImportsKey),
        ).keys,
        ['2026-08-01'],
      );

      // Two months away: the read reaches back past August 1 so nothing is
      // missed — and the ledger is what stops that record coming in again.
      expect(await importAt(now), 0);
      expect(await weightOn(DateTime(2026, 8, 1)), 82);

      // Checked recently now, so August is outside every future read window
      // and its entry can go.
      await importAt(now.add(const Duration(hours: 1)));
      expect(
        decodeWeightImports(
          await settings.readRaw(healthConnectWeightImportsKey),
        ),
        isEmpty,
      );
    });
  });

  group('the watcher', () {
    // It listens for the app coming back to the foreground, which needs a
    // binding. A plain test rather than testWidgets: the database streams it
    // listens to need real time, not a fake clock.
    TestWidgetsFlutterBinding.ensureInitialized();
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          healthConnectBridgeProvider.overrideWithValue(health),
        ],
      );
    });

    tearDown(() => container.dispose());

    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 100));

    test('finishing a workout writes it straight away', () async {
      await writeOn(since: DateTime(2020));
      container.listen(healthConnectWatcherProvider, (_, _) {});
      await settle();

      final sessions = container.read(sessionRepositoryProvider);
      final id = await sessions.startFreeSession(name: 'Evening');
      await settle();
      expect(health.sessions, isEmpty, reason: 'still running');

      // The database keeps whole seconds; a workout started and finished in
      // the same one has no known length and is rightly not written.
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await sessions.completeSession(id);
      await settle();

      expect(health.sessions.values.map((s) => s.title), ['Evening']);
    });

    test('deleting one deletes its record straight away', () async {
      await writeOn(since: DateTime(2020));
      final id = await finished(DateTime(2026, 9, 12, 18));
      container.listen(healthConnectWatcherProvider, (_, _) {});
      await settle();
      expect(health.sessions, hasLength(1), reason: 'the launch sync');

      await container.read(sessionRepositoryProvider).deleteSession(id);
      await settle();

      expect(health.sessions, isEmpty);
    });

    test('with both switches off, Health Connect is never asked', () async {
      await finished(DateTime(2026, 9, 12, 18));
      container.listen(healthConnectWatcherProvider, (_, _) {});
      await settle();
      await finished(DateTime(2026, 9, 13, 18));
      await settle();

      expect(health.writeCalls, isEmpty);
      expect(health.readWindows, isEmpty);
      expect(health.queries, 0);
    });
  });
}
