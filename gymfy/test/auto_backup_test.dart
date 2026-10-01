// Automatic backups: when they run, where they go, and what they tidy up.
//
// The tidying tests carry the weight. The folder is one the user picked, and
// may hold anything else they keep there — so only files the backup itself
// named may ever be deleted.

import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/backup/data/auto_backup.dart';
import 'package:gymfy/features/backup/data/backup_format.dart';
import 'package:gymfy/features/backup/data/backup_repository.dart';
import 'package:gymfy/shared/data/settings_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  group('isAutoBackupDue', () {
    final now = DateTime(2026, 9, 10, 12);

    bool due(
      AutoBackupMode mode,
      AutoBackupTrigger trigger, {
      DateTime? lastAt,
    }) =>
        isAutoBackupDue(mode: mode, trigger: trigger, lastAt: lastAt, now: now);

    test('off never runs', () {
      for (final trigger in AutoBackupTrigger.values) {
        expect(due(AutoBackupMode.off, trigger), isFalse);
      }
    });

    test('weekly runs once a week has passed, or if it never ran', () {
      const opened = AutoBackupTrigger.appOpened;
      expect(due(AutoBackupMode.weekly, opened), isTrue);
      expect(
        due(AutoBackupMode.weekly, opened, lastAt: DateTime(2026, 9, 3, 12)),
        isTrue,
      );
      expect(
        due(AutoBackupMode.weekly, opened, lastAt: DateTime(2026, 9, 4)),
        isFalse,
      );
    });

    test('weekly ignores finishing a workout within the week', () {
      expect(
        due(
          AutoBackupMode.weekly,
          AutoBackupTrigger.workoutFinished,
          lastAt: DateTime(2026, 9, 9),
        ),
        isFalse,
      );
    });

    test('after-workout runs on every finish', () {
      expect(
        due(
          AutoBackupMode.afterWorkout,
          AutoBackupTrigger.workoutFinished,
          lastAt: now,
        ),
        isTrue,
      );
    });

    test('after-workout still backs up weekly when nobody trains', () {
      const opened = AutoBackupTrigger.appOpened;
      expect(
        due(AutoBackupMode.afterWorkout, opened, lastAt: DateTime(2026, 9, 9)),
        isFalse,
      );
      expect(
        due(AutoBackupMode.afterWorkout, opened, lastAt: DateTime(2026, 8, 1)),
        isTrue,
      );
    });
  });

  group('AutoBackupMode.parse', () {
    test('reads what it writes', () {
      for (final mode in AutoBackupMode.values) {
        expect(AutoBackupMode.parse(mode.slug), mode);
      }
    });

    test('anything else is off', () {
      for (final raw in [null, '', 'daily', 'WEEKLY']) {
        expect(AutoBackupMode.parse(raw), AutoBackupMode.off, reason: raw);
      }
    });
  });

  group('isNewlyFinished', () {
    test('a later finish is a finish', () {
      expect(
        isNewlyFinished(
          before: DateTime(2026, 9, 1),
          after: DateTime(2026, 9, 2),
        ),
        isTrue,
      );
      expect(
        isNewlyFinished(before: null, after: DateTime(2026, 9, 2)),
        isTrue,
      );
    });

    test('deleting the latest workout is not', () {
      expect(
        isNewlyFinished(
          before: DateTime(2026, 9, 2),
          after: DateTime(2026, 9, 1),
        ),
        isFalse,
      );
      expect(
        isNewlyFinished(before: DateTime(2026, 9, 2), after: null),
        isFalse,
      );
      expect(
        isNewlyFinished(
          before: DateTime(2026, 9, 2),
          after: DateTime(2026, 9, 2),
        ),
        isFalse,
      );
    });
  });

  group('AutoBackupService', () {
    late AppDatabase db;
    late Directory temp;
    late Directory folder;
    late SettingsRepository settings;
    late AutoBackupService service;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      temp = await Directory.systemTemp.createTemp('gymfy_auto_backup_test');
      folder = Directory('${temp.path}/Backups');
      settings = SettingsRepository(db);
      service = AutoBackupService(
        BackupRepository(
          db,
          photosDir: () async => Directory('${temp.path}/photos'),
        ),
        settings,
      );
    });

    tearDown(() async {
      await db.close();
      await temp.delete(recursive: true);
    });

    List<String> filesIn(Directory dir) => [
      for (final f in dir.listSync().whereType<File>()) f.uri.pathSegments.last,
    ]..sort();

    test('does nothing without a folder', () async {
      await settings.write(autoBackupModeKey, 'weekly');
      expect(await service.runIfDue(AutoBackupTrigger.appOpened), isNull);
    });

    test('does nothing when off', () async {
      await settings.write(autoBackupFolderKey, folder.path);
      expect(await service.runIfDue(AutoBackupTrigger.appOpened), isNull);
      expect(folder.existsSync(), isFalse);
    });

    test('writes a restorable backup and records when', () async {
      await settings.write(autoBackupModeKey, 'weekly');
      await settings.write(autoBackupFolderKey, folder.path);
      final now = DateTime(2026, 9, 10, 7, 45);

      final file = await withClock(
        Clock.fixed(now),
        () => service.runIfDue(AutoBackupTrigger.appOpened),
      );

      expect(file, isNotNull);
      expect(filesIn(folder), ['gymfy-2026-09-10-0745.gymfy-backup']);
      expect(
        await settings.readRaw(autoBackupLastAtKey),
        now.toIso8601String(),
      );
      final summary = await BackupRepository(db).inspect(file!.path);
      expect(summary.schemaVersion, db.schemaVersion);
    });

    test('is not due again the same week', () async {
      await settings.write(autoBackupModeKey, 'weekly');
      await settings.write(autoBackupFolderKey, folder.path);

      await withClock(
        Clock.fixed(DateTime(2026, 9, 10)),
        () => service.runIfDue(AutoBackupTrigger.appOpened),
      );
      final second = await withClock(
        Clock.fixed(DateTime(2026, 9, 12)),
        () => service.runIfDue(AutoBackupTrigger.appOpened),
      );

      expect(second, isNull);
      expect(filesIn(folder), hasLength(1));
    });

    test('two backups in one minute do not overwrite each other', () async {
      await settings.write(autoBackupFolderKey, folder.path);
      final now = DateTime(2026, 9, 10, 7, 45);

      await withClock(Clock.fixed(now), service.backupNow);
      await withClock(Clock.fixed(now), service.backupNow);

      expect(filesIn(folder), [
        'gymfy-2026-09-10-0745-2.gymfy-backup',
        'gymfy-2026-09-10-0745.gymfy-backup',
      ]);
    });

    test('a failure is recorded, then cleared by the next success', () async {
      await settings.write(autoBackupModeKey, 'weekly');
      // A file where the folder should be: nothing can be written inside it.
      final blocker = File('${temp.path}/not_a_folder');
      await blocker.writeAsString('x');
      await settings.write(autoBackupFolderKey, blocker.path);

      final file = await service.runIfDue(AutoBackupTrigger.appOpened);

      expect(file, isNull);
      expect(await settings.readRaw(autoBackupLastErrorKey), isNotNull);
      expect(await settings.readRaw(autoBackupLastAtKey), isNull);

      await settings.write(autoBackupFolderKey, folder.path);
      await service.runIfDue(AutoBackupTrigger.appOpened);
      expect(await settings.readRaw(autoBackupLastErrorKey), isNull);
    });

    test('leaves no half-written file behind', () async {
      await settings.write(autoBackupFolderKey, folder.path);
      await service.backupNow();
      expect(filesIn(folder).where((f) => f.endsWith('.part')), isEmpty);
    });
  });

  group('pruneBackups', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('gymfy_prune_test');
    });

    tearDown(() => dir.delete(recursive: true));

    test('keeps the newest and never touches anything else', () async {
      final names = [
        for (var day = 1; day <= 5; day++)
          backupFileName(DateTime(2026, 9, day, 8)),
      ];
      for (final name in [
        ...names,
        'holiday.jpg',
        'my-keep.gymfy-backup',
        'gymfy-notes.txt',
      ]) {
        await File('${dir.path}/$name').writeAsString('x');
      }

      await pruneBackups(dir, keep: 2);

      final left = [
        for (final f in dir.listSync().whereType<File>())
          f.uri.pathSegments.last,
      ]..sort();
      expect(left, [
        'gymfy-2026-09-04-0800.gymfy-backup',
        'gymfy-2026-09-05-0800.gymfy-backup',
        'gymfy-notes.txt',
        'holiday.jpg',
        'my-keep.gymfy-backup',
      ]);
    });
  });

  group('checkFolderWritable', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('gymfy_writable_test');
    });

    tearDown(() => dir.delete(recursive: true));

    test('a normal folder is fine, and is left clean', () async {
      expect(await checkFolderWritable(dir.path), isNull);
      expect(dir.listSync(), isEmpty);
    });

    test('a folder that cannot be created says why', () async {
      final file = File('${dir.path}/file');
      await file.writeAsString('x');
      expect(await checkFolderWritable('${file.path}/inside'), isNotNull);
    });
  });
}
