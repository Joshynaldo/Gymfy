import 'dart:convert';
import 'dart:typed_data';

/// The file extension a full backup is saved under.
///
/// Its own extension rather than `.zip`, so a backup is never mistaken for
/// something to unpack and edit, and so the restore button can tell at a glance
/// it was handed the right file. Under the hood it *is* a zip — see
/// [backupJsonEntry] and [backupPhotosPrefix].
const backupFileExtension = 'gymfy-backup';

/// The archive entry holding every table, as JSON.
const backupJsonEntry = 'backup.json';

/// Folder inside the archive that holds the progress photo files.
const backupPhotosPrefix = 'photos/';

/// Folder inside the archive that holds the pictures of custom exercises.
const backupExerciseImagesPrefix = 'exercise_images/';

/// Written into every backup so the restore can refuse a file that merely
/// happens to be JSON — a plan export, a data export, someone else's app.
const backupFormatId = 'gymfy-backup';

/// The layout of the JSON itself (not the database schema). Bumped only if the
/// envelope below changes shape; a new table or column is a schema change and
/// is handled by [migrateBackup] instead.
const backupFormatVersion = 1;

/// The oldest database schema a backup can be restored from.
///
/// Backups only exist from schema 26 on, but the payload migration is written
/// from 25 so the one step that moves data between columns (the warm-up flag
/// becoming a set type) has a home and a test. Anything older than that was
/// never written by any build of this app.
const minRestorableSchemaVersion = 25;

/// A problem with a backup file, worded for the person who picked it.
class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// One table's rows, column names stated once rather than repeated per row.
///
/// Values are exactly what SQLite holds — ints, doubles, strings and nulls —
/// so a backup round-trips without passing through the app's own types. A date
/// is the integer the database stores, not a formatted string that would have
/// to be parsed back in the right time zone.
class BackupTable {
  BackupTable({required this.columns, required this.rows});

  final List<String> columns;
  final List<List<Object?>> rows;

  Map<String, Object?> toJson() => {
    'columns': columns,
    'rows': [
      for (final row in rows) [for (final value in row) _encodeValue(value)],
    ],
  };

  factory BackupTable.fromJson(Object? json, String name) {
    if (json is! Map) throw _corrupt('table "$name" is not an object');
    final columns = json['columns'];
    final rows = json['rows'];
    if (columns is! List || columns.any((c) => c is! String)) {
      throw _corrupt('table "$name" has no column list');
    }
    if (rows is! List) throw _corrupt('table "$name" has no rows');

    final width = columns.length;
    return BackupTable(
      columns: columns.cast<String>().toList(),
      rows: [
        for (final row in rows)
          if (row is List && row.length == width)
            [for (final value in row) _decodeValue(value)]
          else
            throw _corrupt('a row in "$name" does not match its columns'),
      ],
    );
  }

  /// The rows as column-name maps. What the migration steps work on, since
  /// "the `is_warmup` of this row" reads better than an index.
  List<Map<String, Object?>> get rowMaps => [
    for (final row in rows)
      {for (var i = 0; i < columns.length; i++) columns[i]: row[i]},
  ];

  /// Builds a table from column-name maps, keeping [columns] in order.
  factory BackupTable.fromRowMaps(
    List<String> columns,
    List<Map<String, Object?>> maps,
  ) {
    return BackupTable(
      columns: columns,
      rows: [
        for (final map in maps) [for (final c in columns) map[c]],
      ],
    );
  }
}

/// A whole backup: every table, which schema wrote it, and which photos ride
/// along in the archive.
class BackupPayload {
  BackupPayload({
    required this.schemaVersion,
    required this.createdAt,
    required this.tables,
    this.photos = const [],
    this.exerciseImages = const [],
  });

  /// The database schema the rows were read from.
  final int schemaVersion;

  final DateTime createdAt;

  /// Keyed by SQL table name, e.g. `logged_sets`.
  final Map<String, BackupTable> tables;

  /// File names of the progress photos stored under [backupPhotosPrefix].
  final List<String> photos;

  /// File names of the custom-exercise pictures stored under
  /// [backupExerciseImagesPrefix].
  ///
  /// Optional in the JSON, so a backup written before these were packed still
  /// reads — it simply brings no pictures back.
  final List<String> exerciseImages;

  /// How many rows [table] holds, or 0 if it is not in the backup.
  int rowCount(String table) => tables[table]?.rows.length ?? 0;

  Map<String, Object?> toJson() => {
    'format': backupFormatId,
    'formatVersion': backupFormatVersion,
    'schemaVersion': schemaVersion,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'tables': {
      for (final entry in tables.entries) entry.key: entry.value.toJson(),
    },
    'photos': photos,
    'exerciseImages': exerciseImages,
  };

  String encode() => jsonEncode(toJson());

  /// Parses a backup's JSON, checking only that it is a backup at all.
  ///
  /// Whether its schema can be restored is a separate question, asked by
  /// [checkRestorable] — a backup from a newer app is still a valid backup, and
  /// the preview can say what is in it before saying why it can't go in.
  factory BackupPayload.decode(String source) {
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      throw const BackupException('That file is not a Gymfy backup.');
    }
    if (json is! Map || json['format'] != backupFormatId) {
      throw const BackupException('That file is not a Gymfy backup.');
    }

    final formatVersion = json['formatVersion'];
    if (formatVersion is! int) throw _corrupt('it has no format version');
    if (formatVersion > backupFormatVersion) {
      throw const BackupException(
        'That backup was made by a newer version of Gymfy. Update the app to '
        'restore it.',
      );
    }

    final schemaVersion = json['schemaVersion'];
    if (schemaVersion is! int) throw _corrupt('it has no schema version');

    final createdAt = DateTime.tryParse('${json['createdAt']}');
    if (createdAt == null) throw _corrupt('it has no date');

    final tables = json['tables'];
    if (tables is! Map) throw _corrupt('it has no tables');

    final photos = json['photos'] ?? const [];
    if (photos is! List || photos.any((p) => p is! String)) {
      throw _corrupt('its photo list is unreadable');
    }
    final exerciseImages = json['exerciseImages'] ?? const [];
    if (exerciseImages is! List || exerciseImages.any((p) => p is! String)) {
      throw _corrupt('its exercise picture list is unreadable');
    }

    return BackupPayload(
      schemaVersion: schemaVersion,
      createdAt: createdAt.toLocal(),
      tables: {
        for (final entry in tables.entries)
          '${entry.key}': BackupTable.fromJson(entry.value, '${entry.key}'),
      },
      photos: photos.cast<String>().toList(),
      exerciseImages: exerciseImages.cast<String>().toList(),
    );
  }
}

/// Throws unless a backup written at [schemaVersion] can be restored into a
/// database at [currentVersion].
///
/// Newer is refused outright. Its rows may carry columns this build has never
/// heard of, and silently dropping them would "restore" a backup that is
/// missing data — the one thing a restore must never do.
void checkRestorable(int schemaVersion, {required int currentVersion}) {
  if (schemaVersion > currentVersion) {
    throw const BackupException(
      'That backup was made by a newer version of Gymfy. Update the app to '
      'restore it.',
    );
  }
  if (schemaVersion < minRestorableSchemaVersion) {
    throw const BackupException(
      'That backup is from a version of Gymfy too old to restore.',
    );
  }
}

/// Brings an older backup up to [to], one schema step at a time.
///
/// Each step mirrors what the database migration did for the same version, so
/// a restored old backup ends up exactly where the device would have if it had
/// simply been upgraded. A step only has to describe *data* moving between
/// columns: a column that is new and nullable (or has a default) can just be
/// absent from the payload, and the insert leaves it to the database.
BackupPayload migrateBackup(BackupPayload payload, {required int to}) {
  checkRestorable(payload.schemaVersion, currentVersion: to);
  var current = payload;
  while (current.schemaVersion < to) {
    final step = _steps[current.schemaVersion];
    if (step == null) {
      // A schema bump with no step here is a bug in this file, not in the
      // user's backup — but the user is the one who'd lose data, so stop.
      throw BackupException(
        'Gymfy cannot read backups from version ${current.schemaVersion} yet.',
      );
    }
    current = step(current);
  }
  return current;
}

/// Payload migrations, keyed by the version they upgrade *from*.
final Map<int, BackupPayload Function(BackupPayload)> _steps = {
  25: _from25,
  26: _from26,
};

/// v25 → v26: the warm-up flag becomes a set type, and sessions gain their own
/// running order.
///
/// RPE / RIR, superset groups, percent targets and block fields are new and
/// nullable, so they simply stay absent. The running order is backfilled for
/// in-progress sessions only, matching the database migration: a finished
/// session's history is its logged sets, not today's plan.
BackupPayload _from25(BackupPayload old) {
  final tables = Map<String, BackupTable>.of(old.tables);

  final sets = tables['logged_sets'];
  if (sets != null && sets.columns.contains('is_warmup')) {
    final columns = [
      for (final c in sets.columns)
        if (c != 'is_warmup') c,
      if (!sets.columns.contains('set_type')) 'set_type',
    ];
    tables['logged_sets'] = BackupTable.fromRowMaps(columns, [
      for (final row in sets.rowMaps)
        {...row, 'set_type': _truthy(row['is_warmup']) ? 'warmup' : 'normal'},
    ]);
  }

  if (!tables.containsKey('session_exercises')) {
    final sessions = tables['workout_sessions']?.rowMaps ?? const [];
    final planned = [...?tables['workout_exercises']?.rowMaps]
      ..sort((a, b) {
        final byPosition = _int(a['position']).compareTo(_int(b['position']));
        return byPosition != 0
            ? byPosition
            : _int(a['id']).compareTo(_int(b['id']));
      });

    final rows = <Map<String, Object?>>[];
    for (final session in sessions) {
      if (session['completed_at'] != null || session['day_id'] == null) {
        continue;
      }
      var position = 0;
      for (final entry in planned) {
        if (entry['day_id'] != session['day_id']) continue;
        rows.add({
          'id': rows.length + 1,
          'session_id': session['id'],
          'exercise_id': entry['exercise_id'],
          'position': position++,
          'workout_exercise_id': entry['id'],
        });
      }
    }
    tables['session_exercises'] = BackupTable.fromRowMaps(const [
      'id',
      'session_id',
      'exercise_id',
      'position',
      'workout_exercise_id',
    ], rows);
  }

  return BackupPayload(
    schemaVersion: 26,
    createdAt: old.createdAt,
    tables: tables,
    photos: old.photos,
    exerciseImages: old.exerciseImages,
  );
}

/// v26 → v27: goals arrive. A backup from before them has none, so the step
/// adds the table empty — the restore insists every table is present, and an
/// absent one would otherwise read as a damaged file.
BackupPayload _from26(BackupPayload old) {
  final tables = Map<String, BackupTable>.of(old.tables);
  tables.putIfAbsent(
    'goals',
    () => BackupTable(
      columns: const [
        'id',
        'kind',
        'exercise_id',
        'target',
        'start_value',
        'deadline',
        'created_at',
        'celebrated_at',
        'archived_at',
      ],
      rows: const [],
    ),
  );

  return BackupPayload(
    schemaVersion: 27,
    createdAt: old.createdAt,
    tables: tables,
    photos: old.photos,
    exerciseImages: old.exerciseImages,
  );
}

/// The file name a backup made at [now] is saved under. Sortable, so a folder
/// of automatic backups lists oldest to newest, and minute-precise so two
/// backups on one day don't overwrite each other.
String backupFileName(DateTime now) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'gymfy-${now.year}-${two(now.month)}-${two(now.day)}'
      '-${two(now.hour)}${two(now.minute)}.$backupFileExtension';
}

/// Whether [name] looks like a file [backupFileName] wrote. The automatic
/// backup only ever tidies up files that pass this — never anything else the
/// user keeps in the same folder.
bool isBackupFileName(String name) => RegExp(
  r'^gymfy-\d{4}-\d{2}-\d{2}-\d{4}(-\d+)?\.gymfy-backup$',
).hasMatch(name);

/// Whether [name] is safe to write as a photo file: a bare name with no path
/// in it. A crafted backup naming `../../something` must not be able to write
/// outside the photos folder.
bool isSafePhotoName(String name) =>
    RegExp(r'^[A-Za-z0-9._-]{1,120}$').hasMatch(name) &&
    name != '.' &&
    name != '..';

BackupException _corrupt(String detail) =>
    BackupException('That backup is damaged and cannot be read ($detail).');

bool _truthy(Object? value) => value == 1 || value == true;

int _int(Object? value) => value is int ? value : 0;

/// SQLite blobs don't survive JSON as-is. None of today's tables has one, but
/// a future table with a blob column must not make the backup throw.
Object? _encodeValue(Object? value) =>
    value is Uint8List ? {'base64': base64Encode(value)} : value;

Object? _decodeValue(Object? value) {
  if (value is Map && value['base64'] is String) {
    return base64Decode(value['base64'] as String);
  }
  if (value is Map || value is List) {
    throw _corrupt('a value is not a plain number or text');
  }
  return value;
}
