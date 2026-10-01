import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/models/exercise.dart' show isBundledAsset;
import '../../exercises/data/exercise_repository.dart' show exerciseImageDir;
import '../../progress/data/photo_repository.dart';
import 'backup_format.dart';

part 'backup_repository.g.dart';

/// Settings that describe *this phone*, not your training: where its automatic
/// backups go and when the last one ran.
///
/// A restore keeps the device's own values for these, and leaves them unset
/// when the device has none — the file's values never come back. Moving
/// to a new phone would otherwise point its automatic backup at the old
/// phone's folder, which may not exist here, and stamp "last backup" with a
/// date that was never true on this device.
const deviceLocalSettingKeys = [
  'auto_backup_mode',
  'auto_backup_folder',
  'auto_backup_last_at',
  'auto_backup_last_error',
];

/// What a backup file holds, for the confirmation before restoring it.
typedef BackupSummary = ({
  DateTime createdAt,
  int schemaVersion,
  int workouts,
  int sets,
  int photos,
});

/// Full backups of the database, and restoring them.
///
/// Unlike the data export, this reads every table generically — straight from
/// [AppDatabase.allTables] — rather than picking the ones that seem
/// interesting. A table added next year is in the backup the day it is added,
/// without anyone remembering to come back here.
///
/// The file is a zip: `backup.json` with every row, plus the progress photo
/// files and custom-exercise pictures the rows point at, so a backup moved to
/// a new phone brings them with it rather than leaving a grid of broken tiles.
class BackupRepository {
  BackupRepository(
    this._db, {
    PhotosDirResolver? photosDir,
    PhotosDirResolver? exerciseImagesDir,
  }) : _photos = PhotoRepository(_db, photosDir: photosDir),
       _exerciseImagesDir = exerciseImagesDir ?? exerciseImageDir;

  final AppDatabase _db;

  /// Borrowed for its photos-folder resolution only, so this and the photo
  /// screen can never disagree about where the files live.
  final PhotoRepository _photos;

  /// Where custom-exercise pictures are restored to — the same folder
  /// `ExerciseRepository.saveImage` copies them into.
  final PhotosDirResolver _exerciseImagesDir;

  /// Every row of every table, as SQLite stores it.
  ///
  /// Read inside one transaction so the tables agree with each other. An
  /// automatic backup can run while a set is being logged; without this, a
  /// session read before it started and a set read after would give a backup
  /// whose set points at a session it doesn't contain — one that would then
  /// refuse to restore.
  Future<BackupPayload> snapshot({DateTime? now}) {
    return _db.transaction(() => _snapshot(now: now));
  }

  Future<BackupPayload> _snapshot({DateTime? now}) async {
    final tables = <String, BackupTable>{};
    for (final table in _db.allTables) {
      final columns = [for (final column in table.$columns) column.name];
      final rows = await _db
          .customSelect(
            'SELECT ${columns.map(_quote).join(', ')} '
            'FROM ${_quote(table.actualTableName)} '
            'ORDER BY ${_orderOf(table)}',
          )
          .get();
      tables[table.actualTableName] = BackupTable(
        columns: columns,
        rows: [
          for (final row in rows) [for (final c in columns) row.data[c]],
        ],
      );
    }

    final photos = await _db.select(_db.progressPhotos).get();
    return BackupPayload(
      schemaVersion: _db.schemaVersion,
      createdAt: now ?? clock.now(),
      tables: tables,
      photos: [
        for (final photo in photos)
          if (isSafePhotoName(photo.fileName)) photo.fileName,
      ],
    );
  }

  /// Writes a complete backup archive to [path].
  ///
  /// Streams the photos from disk into the zip one at a time instead of
  /// loading them all, so a phone with a year of progress photos doesn't need
  /// all of them in memory at once. Written under a temporary name and renamed
  /// into place, so an app killed halfway leaves no file that looks like a
  /// good backup but isn't.
  Future<File> writeArchive(String path, {DateTime? now}) async {
    final payload = await snapshot(now: now);
    final dir = await _photos.ensureDir();
    final present = [
      for (final name in payload.photos)
        if (File('${dir.path}/$name').existsSync()) name,
    ];
    final images = _exerciseImageFiles(payload);

    final partial = '$path.part';
    final encoder = ZipFileEncoder()..create(partial);
    try {
      encoder.addArchiveFile(
        ArchiveFile.string(
          backupJsonEntry,
          BackupPayload(
            schemaVersion: payload.schemaVersion,
            createdAt: payload.createdAt,
            tables: payload.tables,
            photos: present,
            exerciseImages: images.keys.toList(),
          ).encode(),
        ),
      );
      for (final name in present) {
        await encoder.addFile(
          File('${dir.path}/$name'),
          '$backupPhotosPrefix$name',
        );
      }
      for (final MapEntry(key: name, value: file) in images.entries) {
        await encoder.addFile(file, '$backupExerciseImagesPrefix$name');
      }
    } finally {
      await encoder.close();
    }
    return File(partial).rename(path);
  }

  /// Builds a backup in memory, for the save dialog — which on Android takes
  /// the file's bytes rather than a path to write to.
  Future<Uint8List> buildArchiveBytes({DateTime? now}) async {
    final temp = await getTemporaryDirectory();
    final file = await writeArchive(
      '${temp.path}/${backupFileName(now ?? clock.now())}',
      now: now,
    );
    try {
      return await file.readAsBytes();
    } finally {
      await file.delete();
    }
  }

  /// Reads what a backup holds without restoring it.
  Future<BackupSummary> inspect(String path) {
    return _withArchive(path, (archive) async {
      final payload = _payloadOf(archive);
      return (
        createdAt: payload.createdAt,
        schemaVersion: payload.schemaVersion,
        workouts: payload.rowCount('workout_sessions'),
        sets: payload.rowCount('logged_sets'),
        photos: payload.photos.length,
      );
    });
  }

  /// Replaces everything on this device with the backup at [path].
  ///
  /// Everything is checked before anything is touched: a file from a newer
  /// app, a damaged file or a file that isn't a backup at all is refused with
  /// the database exactly as it was. Photos are unpacked first and the rows go
  /// in last, in one transaction — if the rows fail, the worst left behind is
  /// a few unused image files, never a half-restored log.
  Future<void> restore(String path) {
    return _withArchive(path, (archive) async {
      var payload = _prepare(_payloadOf(archive));

      final dir = await _photos.ensureDir();
      await _unpack(archive, backupPhotosPrefix, payload.photos, dir);

      // Asked for only when the backup has pictures, so restoring one without
      // any never touches the documents folder.
      if (payload.exerciseImages.isNotEmpty) {
        final imageDir = await _exerciseImagesDir();
        if (!imageDir.existsSync()) await imageDir.create(recursive: true);
        final restored = await _unpack(
          archive,
          backupExerciseImagesPrefix,
          payload.exerciseImages,
          imageDir,
        );
        payload = _relinkExerciseImages(payload, imageDir, restored);
      }

      await _replaceAll(payload);
    });
  }

  /// Writes each of [names] stored under [prefix] in [archive] into [dir],
  /// and returns the names actually written.
  ///
  /// A name with a path in it is skipped: a crafted backup naming
  /// `../../something` must not be able to write outside [dir].
  Future<Set<String>> _unpack(
    Archive archive,
    String prefix,
    List<String> names,
    Directory dir,
  ) async {
    final written = <String>{};
    for (final name in names) {
      if (!isSafePhotoName(name)) continue;
      final entry = archive.find('$prefix$name');
      if (entry == null || !entry.isFile) continue;
      final output = OutputFileStream('${dir.path}/$name');
      try {
        entry.writeContent(output);
      } finally {
        await output.close();
      }
      written.add(name);
    }
    return written;
  }

  /// The picture files custom exercises point at that exist on this phone,
  /// keyed by the bare file name they are stored under in the archive.
  ///
  /// A built-in exercise's GIF ships with the app and is never packed.
  Map<String, File> _exerciseImageFiles(BackupPayload payload) {
    final files = <String, File>{};
    final exercises = payload.tables['exercises'];
    if (exercises == null) return files;
    for (final row in exercises.rowMaps) {
      final path = row['gif_path'];
      if (path is! String || isBundledAsset(path)) continue;
      final name = _fileNameOf(path);
      final file = File(path);
      if (!isSafePhotoName(name) || !file.existsSync()) continue;
      files[name] = file;
    }
    return files;
  }

  /// Points every custom exercise whose picture was just unpacked at its new
  /// home in [dir].
  ///
  /// The stored path is absolute, and the documents folder it names is not
  /// the same on every phone (on iOS it changes with every install), so the
  /// old path would point nowhere even with the file back in place.
  BackupPayload _relinkExerciseImages(
    BackupPayload payload,
    Directory dir,
    Set<String> restored,
  ) {
    final exercises = payload.tables['exercises'];
    final column = exercises?.columns.indexOf('gif_path') ?? -1;
    if (exercises == null || column == -1 || restored.isEmpty) return payload;

    final rows = [
      for (final row in exercises.rows)
        if (row[column] case final String path
            when !isBundledAsset(path) && restored.contains(_fileNameOf(path)))
          [...row]..[column] = '${dir.path}/${_fileNameOf(path)}'
        else
          row,
    ];
    return BackupPayload(
      schemaVersion: payload.schemaVersion,
      createdAt: payload.createdAt,
      tables: {
        ...payload.tables,
        'exercises': BackupTable(columns: exercises.columns, rows: rows),
      },
      photos: payload.photos,
      exerciseImages: payload.exerciseImages,
    );
  }

  /// The last segment of [path], whichever separator the phone that wrote it
  /// used.
  static String _fileNameOf(String path) => path.split(RegExp(r'[/\\]')).last;

  /// Restores [payload] into the database. The photo files are the caller's
  /// business; this is only the rows.
  Future<void> restorePayload(BackupPayload payload) async =>
      _replaceAll(_prepare(payload));

  /// Checks [payload] can go in, migrates it to this schema, and makes sure it
  /// names only tables and columns that exist.
  ///
  /// The name check is also what keeps a crafted file from smuggling SQL in
  /// through a "column name" — every name used in a statement below has been
  /// matched against the app's own schema first.
  BackupPayload _prepare(BackupPayload payload) {
    checkRestorable(payload.schemaVersion, currentVersion: _db.schemaVersion);
    final migrated = migrateBackup(payload, to: _db.schemaVersion);

    final known = {for (final t in _db.allTables) t.actualTableName: t};
    for (final name in migrated.tables.keys) {
      if (!known.containsKey(name)) {
        throw BackupException(BackupProblem.damaged, 'unknown table "$name"');
      }
    }
    for (final table in known.values) {
      final data = migrated.tables[table.actualTableName];
      if (data == null) {
        throw BackupException(
          BackupProblem.damaged,
          'table "${table.actualTableName}" is missing',
        );
      }
      final columns = {for (final c in table.$columns) c.name};
      for (final column in data.columns) {
        if (!columns.contains(column)) {
          throw BackupException(
            BackupProblem.damaged,
            'unknown column "$column" in "${table.actualTableName}"',
          );
        }
      }
    }
    return migrated;
  }

  Future<void> _replaceAll(BackupPayload payload) async {
    final tables = _db.allTables.toList();

    await _db.transaction(() async {
      // Foreign keys stay on, but are checked at the end instead of row by
      // row. Inserting in an order that satisfies every reference would mean
      // sorting the tables by dependency — and getting that wrong for a future
      // table would only show up as a restore that fails on someone's phone.
      await _db.customStatement('PRAGMA defer_foreign_keys = ON');

      final keep = await _db
          .customSelect(
            'SELECT * FROM "app_settings" WHERE "name" IN '
            '(${deviceLocalSettingKeys.map((_) => '?').join(', ')})',
            variables: [for (final k in deviceLocalSettingKeys) Variable(k)],
          )
          .get();

      for (final table in tables.reversed) {
        await _db.customStatement(
          'DELETE FROM ${_quote(table.actualTableName)}',
        );
      }

      for (final table in tables) {
        final data = payload.tables[table.actualTableName]!;
        if (data.rows.isEmpty) continue;
        final sql =
            'INSERT INTO ${_quote(table.actualTableName)} '
            '(${data.columns.map(_quote).join(', ')}) '
            'VALUES (${data.columns.map((_) => '?').join(', ')})';
        await _db.batch((batch) {
          for (final row in data.rows) {
            batch.customStatement(sql, row);
          }
        });
      }

      // This phone's values, or none at all. A key this phone never had must
      // not come back from the file either: on a new phone that would point
      // its automatic backup at the old phone's folder and claim a "last
      // backup" that never happened here, so no backup would be due for days.
      await _db.customStatement(
        'DELETE FROM "app_settings" WHERE "name" IN '
        '(${deviceLocalSettingKeys.map((_) => '?').join(', ')})',
        deviceLocalSettingKeys,
      );
      for (final row in keep) {
        final columns = row.data.keys.toList();
        await _db.customStatement(
          'INSERT OR REPLACE INTO "app_settings" '
          '(${columns.map(_quote).join(', ')}) '
          'VALUES (${columns.map((_) => '?').join(', ')})',
          [for (final c in columns) row.data[c]],
        );
      }

      // A deferred violation would make the COMMIT itself fail, and SQLite
      // leaves the transaction open when that happens. Asking first and
      // throwing here lets the transaction roll back cleanly instead.
      final broken = await _db.customSelect('PRAGMA foreign_key_check').get();
      if (broken.isNotEmpty) {
        throw const BackupException(
          BackupProblem.damaged,
          'some rows point at data that is not in it',
        );
      }
    });

    // Raw statements don't tell drift what changed, so every open screen is
    // told at once that everything did.
    _db.notifyUpdates({for (final t in tables) TableUpdate.onTable(t)});
  }

  BackupPayload _payloadOf(Archive archive) {
    final entry = archive.find(backupJsonEntry);
    if (entry == null || !entry.isFile) {
      throw const BackupException(BackupProblem.notABackup);
    }
    final String source;
    try {
      source = utf8.decode(entry.content);
    } on FormatException {
      throw const BackupException(BackupProblem.notABackup);
    }
    return BackupPayload.decode(source);
  }

  /// Opens the zip at [path], runs [body], and always closes the file.
  Future<T> _withArchive<T>(
    String path,
    Future<T> Function(Archive archive) body,
  ) async {
    final input = InputFileStream(path);
    try {
      final Archive archive;
      try {
        archive = ZipDecoder().decodeStream(input);
      } catch (_) {
        // Not a zip at all — a plan file, a CSV, a photo picked by mistake.
        throw const BackupException(BackupProblem.notABackup);
      }
      return await body(archive);
    } finally {
      await input.close();
    }
  }

  /// A stable row order, so two backups of the same data are the same file.
  String _orderOf(TableInfo table) {
    final key = table.$primaryKey;
    if (key.isEmpty) return 'rowid';
    return key.map((c) => _quote(c.name)).join(', ');
  }

  static String _quote(String name) => '"${name.replaceAll('"', '""')}"';
}

/// App-wide access to the [BackupRepository].
@Riverpod(keepAlive: true)
BackupRepository backupRepository(Ref ref) {
  return BackupRepository(ref.watch(appDatabaseProvider));
}
