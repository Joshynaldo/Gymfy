// Full backup and restore.
//
// The round trip is the test that matters: fill every table, back up, wipe,
// restore, and get the very same rows back. The coverage tests around it exist
// so that a table added later can't quietly fall out of the backup — the
// fixture must put a row in every table, and the backup must hold every table
// the database actually has on disk.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/backup/data/backup_format.dart';
import 'package:gymfy/features/backup/data/backup_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

/// Puts at least one row in every table, using the columns most likely to be
/// lost by a careless backup: nullable ones, v26's new ones, dates, booleans.
///
/// When a new table is added, the coverage test below fails until a row for it
/// is added here — which is the point.
Future<void> populate(AppDatabase db) async {
  await db
      .into(db.exercises)
      .insert(
        ExercisesCompanion.insert(
          id: 'barbell_bench_press',
          name: 'Barbell Bench Press',
          muscleIds: const ['chest', 'tricep'],
          isPlateLoaded: const Value(true),
          equipment: const Value('barbell'),
        ),
      );
  await db
      .into(db.exercises)
      .insert(
        ExercisesCompanion.insert(
          id: 'custom_landmine_press',
          name: 'Landmine Press',
          muscleIds: const ['front_deltoid'],
          isCustom: const Value(true),
          barWeightKg: const Value(15),
          notes: const Value('Elbow at 45°, "slow" eccentric'),
          isTimed: const Value(false),
        ),
      );

  final splitId = await db
      .into(db.splits)
      .insert(
        SplitsCompanion.insert(
          name: 'Upper / Lower',
          isActive: const Value(true),
          blockWeeks: const Value(4),
          deloadPercent: const Value(85.5),
          blockStartedAt: Value(DateTime(2026, 9, 1)),
          createdAt: Value(DateTime(2026, 8, 1, 12)),
        ),
      );
  final dayId = await db
      .into(db.workoutDays)
      .insert(WorkoutDaysCompanion.insert(splitId: splitId, name: 'Upper'));
  await db
      .into(db.workoutDaySchedules)
      .insert(WorkoutDaySchedulesCompanion.insert(dayId: dayId, weekday: 1));
  final slotId = await db
      .into(db.workoutExercises)
      .insert(
        WorkoutExercisesCompanion.insert(
          dayId: dayId,
          exerciseId: 'barbell_bench_press',
          defaultRepsMax: const Value(8),
          warmupSets: const Value(2),
          supersetGroup: const Value(1),
          targetPercent: const Value(75),
        ),
      );

  final finished = await db
      .into(db.workoutSessions)
      .insert(
        WorkoutSessionsCompanion.insert(
          name: 'Upper',
          dayId: Value(dayId),
          startedAt: Value(DateTime(2026, 9, 2, 18)),
          completedAt: Value(DateTime(2026, 9, 2, 19, 5)),
        ),
      );
  final open = await db
      .into(db.workoutSessions)
      .insert(
        WorkoutSessionsCompanion.insert(
          name: 'Free workout',
          startedAt: Value(DateTime(2026, 9, 4, 7)),
        ),
      );
  for (final (n, type, rpe, rir) in [
    (1, 'warmup', null, null),
    (1, 'normal', 8.5, null),
    (2, 'failure', null, 0),
    (3, 'drop', null, null),
  ]) {
    await db
        .into(db.loggedSets)
        .insert(
          LoggedSetsCompanion.insert(
            sessionId: finished,
            exerciseId: 'barbell_bench_press',
            setNumber: n,
            weight: const Value(102.5),
            reps: const Value(5),
            setType: Value(type),
            rpe: Value(rpe),
            rir: Value(rir),
          ),
        );
  }
  await db
      .into(db.loggedSets)
      .insert(
        LoggedSetsCompanion.insert(
          sessionId: open,
          exerciseId: 'custom_landmine_press',
          setNumber: 1,
          seconds: const Value(45),
        ),
      );
  await db
      .into(db.sessionExercises)
      .insert(
        SessionExercisesCompanion.insert(
          sessionId: open,
          exerciseId: 'barbell_bench_press',
          workoutExerciseId: Value(slotId),
        ),
      );

  await db
      .into(db.calorieEntries)
      .insert(
        CalorieEntriesCompanion.insert(
          date: DateTime(2026, 9, 2),
          name: 'Oats, milk',
          calories: const Value(420),
          protein: const Value(18),
        ),
      );
  await db
      .into(db.bodyMeasurements)
      .insert(
        BodyMeasurementsCompanion.insert(
          date: DateTime(2026, 9, 1),
          weightKg: const Value(81.3),
          waistCm: const Value(84),
        ),
      );
  await db
      .into(db.progressPhotos)
      .insert(
        ProgressPhotosCompanion.insert(
          date: DateTime(2026, 9, 1),
          fileName: '2026-09-01_1756700000000.jpg',
          note: const Value('front relaxed'),
        ),
      );
  await db
      .into(db.testedOneRms)
      .insert(
        TestedOneRmsCompanion.insert(
          exerciseId: 'barbell_bench_press',
          weightKg: 120,
          testedOn: DateTime(2026, 8, 20),
        ),
      );
  await db
      .into(db.appSettings)
      .insert(AppSettingsCompanion.insert(name: 'weight_unit', value: 'lb'));
  await db
      .into(db.restTimers)
      .insert(
        RestTimersCompanion.insert(
          exerciseId: 'barbell_bench_press',
          seconds: 180,
        ),
      );
}

/// Every row of every table, as comparable JSON.
Future<String> dump(BackupRepository repo) async {
  final payload = await repo.snapshot(now: DateTime(2026, 1, 1));
  return jsonEncode({
    for (final e in payload.tables.entries) e.key: e.value.toJson(),
  });
}

Future<void> wipe(AppDatabase db) async {
  for (final table in db.allTables.toList().reversed) {
    await db.customStatement('DELETE FROM "${table.actualTableName}"');
  }
}

Future<AppDatabase> openDb() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db.customStatement('PRAGMA foreign_keys = ON');
  return db;
}

/// Writes [json] as `backup.json` inside a zip at [path], for hand-made files.
Future<void> writeZip(String path, String json) async {
  final encoder = ZipFileEncoder()..create(path);
  encoder.addArchiveFile(ArchiveFile.string(backupJsonEntry, json));
  await encoder.close();
}

void main() {
  late AppDatabase db;
  late Directory temp;
  late Directory photos;
  late BackupRepository repo;

  setUp(() async {
    db = await openDb();
    temp = await Directory.systemTemp.createTemp('gymfy_backup_test');
    photos = Directory('${temp.path}/photos');
    repo = BackupRepository(db, photosDir: () async => photos);
  });

  tearDown(() async {
    await db.close();
    await temp.delete(recursive: true);
  });

  group('coverage', () {
    test('the fixture puts a row in every table', () async {
      await populate(db);
      for (final table in db.allTables) {
        final count = await db
            .customSelect(
              'SELECT COUNT(*) AS c FROM "${table.actualTableName}"',
            )
            .getSingle();
        expect(
          count.data['c'],
          greaterThan(0),
          reason:
              '${table.actualTableName} is empty — add a row for it to '
              'populate() so the round trip covers it',
        );
      }
    });

    test('the backup holds every table that exists on disk', () async {
      // Read from SQLite itself, not from drift's list: a table created by
      // raw SQL in a migration, and never declared, would be missed by
      // anything that only asks drift.
      final onDisk = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      final payload = await repo.snapshot();

      expect(payload.tables.keys.toSet(), {
        for (final row in onDisk) row.data['name'] as String,
      });
    });

    test('every column of every table is in the backup', () async {
      final payload = await repo.snapshot();
      for (final table in db.allTables) {
        final onDisk = await db
            .customSelect('PRAGMA table_info("${table.actualTableName}")')
            .get();
        expect(
          payload.tables[table.actualTableName]!.columns.toSet(),
          {for (final row in onDisk) row.data['name'] as String},
          reason: table.actualTableName,
        );
      }
    });

    test('records the schema it was taken from', () async {
      final payload = await repo.snapshot();
      expect(payload.schemaVersion, db.schemaVersion);
      expect(payload.schemaVersion, 26);
    });
  });

  group('round trip', () {
    test('populate, back up, wipe, restore: identical rows', () async {
      await populate(db);
      final before = await dump(repo);

      final path = '${temp.path}/b.$backupFileExtension';
      await repo.writeArchive(path);
      await wipe(db);
      expect(await db.select(db.loggedSets).get(), isEmpty);

      await repo.restore(path);

      expect(await dump(repo), before);
    });

    test('restores onto a fresh install (a new phone)', () async {
      await populate(db);
      final before = await dump(repo);
      final path = '${temp.path}/b.$backupFileExtension';
      await repo.writeArchive(path);

      // Two separate in-memory databases, deliberately: the old phone and the
      // new one.
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(
        () => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false,
      );
      final other = await openDb();
      addTearDown(other.close);
      final otherRepo = BackupRepository(
        other,
        photosDir: () async => Directory('${temp.path}/other_photos'),
      );
      await otherRepo.restore(path);

      expect(await dump(otherRepo), before);
    });

    test('replaces what is there rather than merging into it', () async {
      await populate(db);
      final path = '${temp.path}/b.$backupFileExtension';
      await repo.writeArchive(path);
      final before = await dump(repo);

      // Things done after the backup, which the restore must undo.
      await db
          .into(db.calorieEntries)
          .insert(
            CalorieEntriesCompanion.insert(
              date: DateTime(2026, 9, 10),
              name: 'Later snack',
            ),
          );
      await (db.delete(db.restTimers)).go();

      await repo.restore(path);

      expect(await dump(repo), before);
    });

    test('typed reads see the restored values, v26 columns included', () async {
      await populate(db);
      final path = '${temp.path}/b.$backupFileExtension';
      await repo.writeArchive(path);
      await wipe(db);
      await repo.restore(path);

      final sets = await db.select(db.loggedSets).get();
      expect(sets.map((s) => s.setType), [
        'warmup',
        'normal',
        'failure',
        'drop',
        'normal',
      ]);
      expect(sets[1].rpe, 8.5);
      expect(sets[2].rir, 0);
      final split = await db.select(db.splits).getSingle();
      expect(split.blockStartedAt, DateTime(2026, 9, 1));
      expect(split.deloadPercent, 85.5);
      final exercise = await (db.select(
        db.exercises,
      )..where((t) => t.id.equals('custom_landmine_press'))).getSingle();
      expect(exercise.notes, 'Elbow at 45°, "slow" eccentric');
      expect(exercise.isCustom, isTrue);
    });

    test('new rows after a restore do not reuse restored ids', () async {
      await populate(db);
      final path = '${temp.path}/b.$backupFileExtension';
      await repo.writeArchive(path);
      await wipe(db);
      await repo.restore(path);

      final maxId = (await db.select(db.loggedSets).get())
          .map((s) => s.id)
          .reduce((a, b) => a > b ? a : b);
      final session = (await db.select(db.workoutSessions).get()).first;
      final id = await db
          .into(db.loggedSets)
          .insert(
            LoggedSetsCompanion.insert(
              sessionId: session.id,
              exerciseId: 'barbell_bench_press',
              setNumber: 9,
            ),
          );
      expect(id, greaterThan(maxId));
    });

    test('open queries hear about the restore', () async {
      await populate(db);
      final path = '${temp.path}/b.$backupFileExtension';
      await repo.writeArchive(path);
      await wipe(db);

      final counts = db
          .select(db.loggedSets)
          .watch()
          .map((rows) => rows.length);
      final heard = expectLater(counts, emitsThrough(5));
      await repo.restore(path);
      await heard;
    });
  });

  group('photos', () {
    const name = '2026-09-01_1756700000000.jpg';
    final image = Uint8List.fromList(List.generate(4096, (i) => i % 251));

    test('ride along in the archive and come back', () async {
      await populate(db);
      await photos.create(recursive: true);
      await File('${photos.path}/$name').writeAsBytes(image);

      final path = '${temp.path}/b.$backupFileExtension';
      await repo.writeArchive(path);
      await photos.delete(recursive: true);
      await wipe(db);

      await repo.restore(path);

      expect(await File('${photos.path}/$name').readAsBytes(), image);
    });

    test('a photo whose file is gone is listed nowhere', () async {
      await populate(db);
      // No file written for the fixture's photo row.
      final path = '${temp.path}/b.$backupFileExtension';
      await repo.writeArchive(path);

      final summary = await repo.inspect(path);
      expect(summary.photos, 0);
      // The row itself is still backed up, like every row.
      await wipe(db);
      await repo.restore(path);
      expect(await db.select(db.progressPhotos).get(), hasLength(1));
    });

    test('a crafted name cannot write outside the photos folder', () async {
      final payload = await repo.snapshot();
      final json = BackupPayload(
        schemaVersion: payload.schemaVersion,
        createdAt: payload.createdAt,
        tables: payload.tables,
        photos: const ['../escaped.jpg'],
      ).encode();
      final path = '${temp.path}/evil.$backupFileExtension';
      final encoder = ZipFileEncoder()..create(path);
      encoder.addArchiveFile(ArchiveFile.string(backupJsonEntry, json));
      encoder.addArchiveFile(
        ArchiveFile.bytes('$backupPhotosPrefix../escaped.jpg', image),
      );
      await encoder.close();

      await repo.restore(path);

      expect(File('${temp.path}/escaped.jpg').existsSync(), isFalse);
    });
  });

  group('refusing', () {
    test(
      'a backup from a newer schema, leaving everything as it was',
      () async {
        await populate(db);
        final before = await dump(repo);
        final payload = await repo.snapshot();
        final path = '${temp.path}/newer.$backupFileExtension';
        await writeZip(
          path,
          BackupPayload(
            schemaVersion: db.schemaVersion + 1,
            createdAt: payload.createdAt,
            tables: payload.tables,
          ).encode(),
        );

        await expectLater(
          repo.restore(path),
          throwsA(
            isA<BackupException>().having(
              (e) => e.message,
              'message',
              contains('newer version'),
            ),
          ),
        );
        expect(await dump(repo), before);
      },
    );

    test('a file that is not a zip', () async {
      final path = '${temp.path}/plan.gymfy';
      await File(path).writeAsString('{"splits": []}');

      expect(repo.restore(path), throwsA(isA<BackupException>()));
      expect(repo.inspect(path), throwsA(isA<BackupException>()));
    });

    test('a zip that is not a backup', () async {
      final path = '${temp.path}/other.zip';
      await writeZip(path, '{"format": "something-else"}');

      expect(
        repo.restore(path),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'message',
            contains('not a Gymfy backup'),
          ),
        ),
      );
    });

    test('a backup missing a table', () async {
      final payload = await repo.snapshot();
      final tables = Map.of(payload.tables)..remove('rest_timers');
      expect(
        () => repo.restorePayload(
          BackupPayload(
            schemaVersion: payload.schemaVersion,
            createdAt: payload.createdAt,
            tables: tables,
          ),
        ),
        throwsA(isA<BackupException>()),
      );
    });

    test('a column the schema does not have — never pasted into SQL', () async {
      final payload = await repo.snapshot();
      final tables = Map.of(payload.tables)
        ..['app_settings'] = BackupTable(
          columns: const ['name', 'value) ; DROP TABLE exercises; --'],
          rows: const [
            ['a', 'b'],
          ],
        );

      await expectLater(
        repo.restorePayload(
          BackupPayload(
            schemaVersion: payload.schemaVersion,
            createdAt: payload.createdAt,
            tables: tables,
          ),
        ),
        throwsA(isA<BackupException>()),
      );
      // Still there.
      await db.select(db.exercises).get();
    });

    test('a broken reference rolls the whole restore back', () async {
      await populate(db);
      final before = await dump(repo);
      final payload = await repo.snapshot();
      final sets = payload.tables['logged_sets']!;
      final sessionColumn = sets.columns.indexOf('session_id');
      final tables = Map.of(payload.tables)
        ..['logged_sets'] = BackupTable(
          columns: sets.columns,
          rows: [
            for (final row in sets.rows) [...row]..[sessionColumn] = 999,
          ],
        );

      await expectLater(
        repo.restorePayload(
          BackupPayload(
            schemaVersion: payload.schemaVersion,
            createdAt: payload.createdAt,
            tables: tables,
          ),
        ),
        throwsA(isA<BackupException>()),
      );
      expect(await dump(repo), before);
    });
  });

  group('older backups', () {
    /// Rewrites a v26 snapshot into the shape a v25 database would have had.
    BackupPayload asV25(BackupPayload v26) {
      final sets = v26.tables['logged_sets']!;
      final v25Columns = [
        for (final c in sets.columns)
          if (!{'set_type', 'rpe', 'rir'}.contains(c)) c,
        'is_warmup',
      ];
      final planned = v26.tables['workout_exercises']!;
      final splits = v26.tables['splits']!;
      List<String> without(BackupTable t, Set<String> gone) => [
        for (final c in t.columns)
          if (!gone.contains(c)) c,
      ];
      final plannedColumns = without(planned, {
        'superset_group',
        'target_percent',
      });
      final splitColumns = without(splits, {
        'block_weeks',
        'deload_percent',
        'block_started_at',
      });

      final tables = Map.of(v26.tables)
        ..remove('session_exercises')
        ..['logged_sets'] = BackupTable.fromRowMaps(v25Columns, [
          for (final row in sets.rowMaps)
            {...row, 'is_warmup': row['set_type'] == 'warmup' ? 1 : 0},
        ])
        ..['workout_exercises'] = BackupTable.fromRowMaps(
          plannedColumns,
          planned.rowMaps,
        )
        ..['splits'] = BackupTable.fromRowMaps(splitColumns, splits.rowMaps);

      return BackupPayload(
        schemaVersion: 25,
        createdAt: v26.createdAt,
        tables: tables,
      );
    }

    test('a v25 backup is migrated: warm-up flag becomes a set type', () async {
      await populate(db);
      final v25 = asV25(await repo.snapshot());
      await wipe(db);

      await repo.restorePayload(v25);

      final sets = await db.select(db.loggedSets).get();
      // v25 only knew warm-up or not: drop and failure come back as normal.
      expect(sets.map((s) => s.setType), [
        'warmup',
        'normal',
        'normal',
        'normal',
        'normal',
      ]);
      expect(sets.every((s) => s.rpe == null && s.rir == null), isTrue);
      final planned = await db.select(db.workoutExercises).getSingle();
      expect(planned.supersetGroup, isNull);
      expect(planned.targetPercent, isNull);
    });

    test(
      'a v25 backup backfills the running order of open sessions only',
      () async {
        await populate(db);
        // Make the open session one started from the plan, like v25 had.
        final day = await db.select(db.workoutDays).getSingle();
        await (db.update(db.workoutSessions)
              ..where((t) => t.completedAt.isNull()))
            .write(WorkoutSessionsCompanion(dayId: Value(day.id)));
        final v25 = asV25(await repo.snapshot());
        await wipe(db);

        await repo.restorePayload(v25);

        final open = await (db.select(
          db.workoutSessions,
        )..where((t) => t.completedAt.isNull())).getSingle();
        final order = await db.select(db.sessionExercises).get();
        final slot = await db.select(db.workoutExercises).getSingle();
        expect(order, hasLength(1));
        expect(order.single.sessionId, open.id);
        expect(order.single.exerciseId, slot.exerciseId);
        expect(order.single.workoutExerciseId, slot.id);
        expect(order.single.position, 0);
      },
    );

    test('anything older than v25 is refused', () {
      expect(
        () => migrateBackup(
          BackupPayload(
            schemaVersion: 24,
            createdAt: DateTime(2026),
            tables: {},
          ),
          to: 26,
        ),
        throwsA(isA<BackupException>()),
      );
    });
  });

  group('device settings', () {
    test("this phone's automatic-backup settings survive a restore", () async {
      await populate(db);
      await db
          .into(db.appSettings)
          .insert(
            AppSettingsCompanion.insert(
              name: 'auto_backup_folder',
              value: '/old/phone',
            ),
          );
      final path = '${temp.path}/b.$backupFileExtension';
      await repo.writeArchive(path);

      await (db.update(db.appSettings)
            ..where((t) => t.name.equals('auto_backup_folder')))
          .write(const AppSettingsCompanion(value: Value('/new/phone')));
      await repo.restore(path);

      final rows = await db.select(db.appSettings).get();
      String? valueOf(String key) =>
          rows.where((r) => r.name == key).firstOrNull?.value;
      expect(valueOf('auto_backup_folder'), '/new/phone');
      // Everything else is the backup's.
      expect(valueOf('weight_unit'), 'lb');
    });
  });

  group('format', () {
    test('a summary says what the file holds', () async {
      await populate(db);
      final path = '${temp.path}/b.$backupFileExtension';
      await repo.writeArchive(path, now: DateTime(2026, 9, 5, 8, 30));

      final summary = await repo.inspect(path);

      expect(summary.createdAt, DateTime(2026, 9, 5, 8, 30));
      expect(summary.schemaVersion, 26);
      expect(summary.workouts, 2);
      expect(summary.sets, 5);
    });

    test('JSON round trip keeps blobs, nulls and numbers apart', () {
      final payload = BackupPayload(
        schemaVersion: 26,
        createdAt: DateTime(2026, 9, 5),
        tables: {
          't': BackupTable(
            columns: const ['a', 'b', 'c', 'd'],
            rows: [
              [
                1,
                2.5,
                null,
                Uint8List.fromList([0, 255, 7]),
              ],
            ],
          ),
        },
      );

      final back = BackupPayload.decode(payload.encode());

      expect(back.tables['t']!.rows.single, [
        1,
        2.5,
        null,
        Uint8List.fromList([0, 255, 7]),
      ]);
      expect(back.createdAt, DateTime(2026, 9, 5));
    });

    test('a row that does not match its columns is damage', () {
      final json = jsonEncode({
        'format': backupFormatId,
        'formatVersion': 1,
        'schemaVersion': 26,
        'createdAt': '2026-09-05T00:00:00.000Z',
        'tables': {
          't': {
            'columns': ['a', 'b'],
            'rows': [
              [1],
            ],
          },
        },
      });
      expect(() => BackupPayload.decode(json), throwsA(isA<BackupException>()));
    });

    test('file names sort by date and are recognised', () {
      final name = backupFileName(DateTime(2026, 3, 7, 9, 5));
      expect(name, 'gymfy-2026-03-07-0905.gymfy-backup');
      expect(isBackupFileName(name), isTrue);
      expect(isBackupFileName('gymfy-2026-03-07-0905-2.gymfy-backup'), isTrue);
      expect(isBackupFileName('my-notes.gymfy-backup'), isFalse);
      expect(isBackupFileName('gymfy-2026-03-07-0905.zip'), isFalse);
    });

    test('photo names with a path in them are unsafe', () {
      expect(isSafePhotoName('2026-09-01_1756700000000.jpg'), isTrue);
      expect(isSafePhotoName('../x.jpg'), isFalse);
      expect(isSafePhotoName('a/b.jpg'), isFalse);
      expect(isSafePhotoName('..'), isFalse);
      expect(isSafePhotoName(''), isFalse);
    });
  });
}
