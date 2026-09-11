// The bundled exercise animations: which file the app looks for, and whether
// what's on disk actually lines up with the exercise library.
//
// Worth pinning down because the failure mode here is silent. A file named
// slightly differently from its exercise id sits in the folder looking present
// and never reaches the app — the detail screen just shows "Preview coming
// soon", which is also what a genuinely missing file looks like.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/shared/utils/exercise_preview.dart';
import 'package:gymfy/features/exercises/data/exercise_seed_data.dart';

void main() {
  final seedIds = exerciseSeedData.map((e) => e.id.value).toSet();

  /// Every animation actually bundled, keyed by the id it claims to serve.
  Map<String, File> bundled() {
    final out = <String, File>{};
    for (final file in Directory(
      'assets/exercises',
    ).listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      final dot = name.lastIndexOf('.');
      if (dot < 0) continue;
      final extension = name.substring(dot + 1).toLowerCase();
      if (extension != 'gif' && extension != 'webp') continue;
      out[name.substring(0, dot)] = file;
    }
    return out;
  }

  group('previewCandidates', () {
    test('prefers the WebP spelling over the declared GIF', () {
      // Seed data declares `.gif` for every exercise, but what ships is an
      // animated WebP — the same loop at a sixteenth of the size. Resolving
      // the extension at load is what lets that choice change without
      // rewriting 78 seed entries.
      expect(previewCandidates('assets/exercises/squat.gif'), [
        'assets/exercises/squat.webp',
        'assets/exercises/squat.gif',
      ]);
    });

    test('a path with no extension is left alone', () {
      expect(previewCandidates('assets/exercises/squat'), [
        'assets/exercises/squat',
      ]);
    });

    test('only the last dot counts', () {
      expect(
        previewCandidates('assets/ex.v2/squat.gif').first,
        'assets/ex.v2/squat.webp',
      );
    });
  });

  group('the bundled animations', () {
    test('every file belongs to a real exercise', () {
      // The silent failure: `barbell-bench-press.webp` (hyphens) sits on disk
      // looking done while the app looks for `barbell_bench_press`.
      for (final id in bundled().keys) {
        expect(seedIds, contains(id), reason: '"$id" matches no exercise');
      }
    });

    test('each one is a real animated image, not an error page', () {
      // These are fetched over HTTP by tool/fetch_exercise_gifs.dart. A 404
      // body or a truncated download writes a file that exists, has a
      // plausible size, and renders as nothing.
      for (final entry in bundled().entries) {
        final bytes = entry.value.readAsBytesSync();
        expect(bytes.length, greaterThan(1024), reason: entry.key);

        final header = String.fromCharCodes(bytes.take(4));
        if (entry.value.path.endsWith('.webp')) {
          expect(header, 'RIFF', reason: '${entry.key} is not a WebP');
          // WebP is a still image unless it carries an ANIM chunk, and a still
          // frame of a bench press is not a demonstration of one.
          final head = String.fromCharCodes(bytes.take(64));
          expect(
            head,
            contains('ANIM'),
            reason: '${entry.key} is not animated',
          );
        } else {
          expect(header, 'GIF8', reason: '${entry.key} is not a GIF');
        }
      }
    });

    test('the whole library is covered', () {
      // Not a hard requirement of the app — a missing animation degrades to a
      // placeholder on purpose — but the set shipped complete, and an exercise
      // added later without one should be a deliberate choice rather than an
      // oversight nobody noticed.
      expect(seedIds.difference(bundled().keys.toSet()), isEmpty);
    });

    test('stays within the size budget', () {
      // All of it lands in the download; there is no server to stream from.
      // 22.5MB of 360px GIFs is a deliberate call — sharpness was worth it —
      // so this isn't a limit to creep up against, it's a tripwire for
      // something going wrong: a re-fetch at a larger size, or someone adding
      // a handful of multi-megabyte files without noticing the total.
      final total = bundled().values.fold<int>(
        0,
        (sum, file) => sum + file.lengthSync(),
      );
      expect(
        total,
        lessThan(30 * 1024 * 1024),
        reason: '${(total / 1048576).toStringAsFixed(1)}MB of animations',
      );
    });
  });
}
