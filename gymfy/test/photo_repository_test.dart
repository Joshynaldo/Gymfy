// Covers the progress-photo storage rules: picked files are copied into the
// app's own directory, rows resolve to a path, deleting removes both, and the
// generated file names are unique and safe.
//
// Runs against a real temporary directory and an in-memory database — no
// gallery, no plugin.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:gymfy/features/progress/data/photo_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  late AppDatabase db;
  late Directory temp;
  late Directory photosDir;
  late PhotoRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    temp = await Directory.systemTemp.createTemp('gymfy_photos_test');
    photosDir = Directory('${temp.path}/progress_photos');
    repo = PhotoRepository(db, photosDir: () async => photosDir);
  });

  tearDown(() async {
    await db.close();
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  /// Stands in for a photo the user picked out of their gallery.
  Future<File> fakePickedImage(String name) async {
    final file = File('${temp.path}/$name');
    await file.writeAsBytes([1, 2, 3, 4]);
    return file;
  }

  test('adding a photo copies the file in and records the row', () async {
    final picked = await fakePickedImage('IMG_1234.jpg');

    await repo.addPhoto(day: DateTime(2026, 7, 25), source: picked);

    final items = await repo.watchAll().first;
    expect(items, hasLength(1));

    final item = items.single;
    expect(item.photo.date, DateTime(2026, 7, 25));
    // The stored copy exists inside the app's own directory...
    expect(File(item.path).existsSync(), isTrue);
    expect(item.path, startsWith(photosDir.path));
    // ...and the original is left alone.
    expect(picked.existsSync(), isTrue);
  });

  test(
    'only the file name is stored, so the path is resolved on read',
    () async {
      await repo.addPhoto(
        day: DateTime(2026, 7, 25),
        source: await fakePickedImage('IMG_1.jpg'),
      );

      final item = (await repo.watchAll().first).single;
      // A directory separator in the column would mean a baked-in absolute path.
      expect(item.photo.fileName, isNot(contains('/')));
      expect(item.path, '${photosDir.path}/${item.photo.fileName}');
    },
  );

  test('deleting a photo removes both the row and the file', () async {
    await repo.addPhoto(
      day: DateTime(2026, 7, 25),
      source: await fakePickedImage('IMG_1.jpg'),
    );
    final item = (await repo.watchAll().first).single;

    await repo.deletePhoto(item.photo);

    expect(await repo.watchAll().first, isEmpty);
    expect(File(item.path).existsSync(), isFalse);
  });

  test('deleting survives the file already being gone', () async {
    await repo.addPhoto(
      day: DateTime(2026, 7, 25),
      source: await fakePickedImage('IMG_1.jpg'),
    );
    final item = (await repo.watchAll().first).single;
    await File(item.path).delete();

    // Must still clear the row rather than throwing.
    await repo.deletePhoto(item.photo);
    expect(await repo.watchAll().first, isEmpty);
  });

  test(
    'several photos can share a day without overwriting each other',
    () async {
      final day = DateTime(2026, 7, 25);
      await repo.addPhoto(
        day: day,
        source: await fakePickedImage('front.jpg'),
        note: 'front',
      );
      await repo.addPhoto(
        day: day,
        source: await fakePickedImage('back.jpg'),
        note: 'back',
      );

      final items = await repo.watchAll().first;
      expect(items, hasLength(2));
      expect(items.map((i) => i.photo.fileName).toSet(), hasLength(2));
      expect(photosDir.listSync(), hasLength(2));
    },
  );

  test('photos come back newest day first', () async {
    await repo.addPhoto(
      day: DateTime(2026, 7, 10),
      source: await fakePickedImage('a.jpg'),
      note: 'older',
    );
    await repo.addPhoto(
      day: DateTime(2026, 7, 25),
      source: await fakePickedImage('b.jpg'),
      note: 'newer',
    );

    final items = await repo.watchAll().first;
    expect(items.map((i) => i.photo.note), ['newer', 'older']);
  });

  group('buildFileName', () {
    final day = DateTime(2026, 7, 5);
    final now = DateTime(2026, 7, 5, 12);

    test('leads with the sortable date and keeps the extension', () {
      final name = buildFileName(day: day, source: '/x/IMG_1.PNG', now: now);
      expect(name, startsWith('2026-07-05_'));
      expect(name, endsWith('.png'));
    });

    test('falls back to .jpg for a missing or odd extension', () {
      expect(
        buildFileName(day: day, source: '/x/noext', now: now),
        endsWith('.jpg'),
      );
      expect(
        buildFileName(day: day, source: '/x/weird.tar.gz2345', now: now),
        endsWith('.jpg'),
      );
    });
  });
}
