import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/utils/dates.dart';

part 'photo_repository.g.dart';

/// A photo row plus the absolute path its image currently lives at. The path is
/// resolved on read, never stored — see [ProgressPhotos].
typedef PhotoItem = ({ProgressPhoto photo, String path});

/// Resolves the directory progress photos are kept in. Injectable so tests can
/// point it at a temporary directory instead of a real device path.
typedef PhotosDirResolver = Future<Directory> Function();

/// Where progress photos live on a real device: a subfolder of the app's own
/// documents directory, so they're private to the app and removed with it.
Future<Directory> _appPhotosDir() async {
  final documents = await getApplicationDocumentsDirectory();
  return Directory('${documents.path}/progress_photos');
}

/// Storage for progress photos: copies picked images into app storage and keeps
/// the database rows pointing at them.
class PhotoRepository {
  PhotoRepository(this._db, {PhotosDirResolver? photosDir})
    : _photosDir = photosDir ?? _appPhotosDir;

  final AppDatabase _db;
  final PhotosDirResolver _photosDir;

  /// The photos directory, created if it isn't there yet.
  Future<Directory> ensureDir() async {
    final dir = await _photosDir();
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Streams every photo, newest day first, each with its resolved path.
  Stream<List<PhotoItem>> watchAll() {
    final query = _db.select(_db.progressPhotos)
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch().asyncMap((rows) async {
      final dir = await ensureDir();
      return [
        for (final row in rows)
          (photo: row, path: '${dir.path}/${row.fileName}'),
      ];
    });
  }

  /// Copies [source] into app storage and records it against [day].
  ///
  /// The copy is what makes the photo durable: the picked file may be a cache
  /// entry the OS clears, or a gallery item the user later deletes.
  Future<void> addPhoto({
    required DateTime day,
    required File source,
    String? note,
  }) async {
    final dir = await ensureDir();
    final d = dateOnly(day);
    final fileName = buildFileName(day: d, source: source.path);
    await source.copy('${dir.path}/$fileName');

    await _db.into(_db.progressPhotos).insert(
      ProgressPhotosCompanion.insert(
        date: d,
        fileName: fileName,
        note: Value(note),
      ),
    );
  }

  /// Removes a photo's row and its file. The row goes first: an orphaned file is
  /// invisible clutter, but a row pointing at a missing file is a broken tile.
  Future<void> deletePhoto(ProgressPhoto photo) async {
    await (_db.delete(_db.progressPhotos)
          ..where((t) => t.id.equals(photo.id)))
        .go();

    final dir = await ensureDir();
    final file = File('${dir.path}/${photo.fileName}');
    if (file.existsSync()) {
      await file.delete();
    }
  }
}

/// Builds a unique, sortable file name for a photo taken on [day], keeping the
/// source file's extension. The timestamp suffix keeps several photos on the
/// same day from overwriting each other.
String buildFileName({
  required DateTime day,
  required String source,
  DateTime? now,
}) {
  final stamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
  final month = day.month.toString().padLeft(2, '0');
  final dayOfMonth = day.day.toString().padLeft(2, '0');

  // Take the extension off the source, defaulting to .jpg for anything odd.
  final dot = source.lastIndexOf('.');
  final rawExt = dot == -1 ? '' : source.substring(dot).toLowerCase();
  final ext = RegExp(r'^\.[a-z0-9]{2,5}$').hasMatch(rawExt) ? rawExt : '.jpg';

  return '${day.year}-$month-${dayOfMonth}_$stamp$ext';
}

/// App-wide access to the [PhotoRepository].
@Riverpod(keepAlive: true)
PhotoRepository photoRepository(Ref ref) {
  return PhotoRepository(ref.watch(appDatabaseProvider));
}

/// The live photo list, newest first.
final progressPhotosProvider = StreamProvider<List<PhotoItem>>((ref) {
  return ref.watch(photoRepositoryProvider).watchAll();
});
