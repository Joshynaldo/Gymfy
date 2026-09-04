// Reports which exercise GIFs are still missing, and which files in
// assets/exercises/ don't belong to any exercise.
//
// Run from the package root:
//   dart run tool/check_exercise_gifs.dart
//
// Not a test. A missing GIF is a normal, shipping state — the detail screen
// shows a placeholder — so failing the build over one would be wrong. This is
// a progress report for whoever is filling the folder, and it catches the one
// mistake that *is* silent: a file named slightly differently from its
// exercise id, which looks present on disk and absent in the app.
//
// It is a dev tool, not part of the app; nothing imports it.

import 'dart:io';

/// Where the GIFs live, and the naming convention the app expects.
const _dir = 'assets/exercises';

/// Pulls exercise ids straight out of the seed data source.
///
/// Read as text rather than imported: this file is plain Dart with no Flutter
/// binding, and `exercise_seed_data.dart` pulls in Drift, which needs one.
Set<String> _seedIds() {
  final source = File(
    'lib/features/exercises/data/exercise_seed_data.dart',
  ).readAsStringSync();
  return RegExp(r"id: Value\('([a-z_0-9]+)'\)")
      .allMatches(source)
      .map((m) => m.group(1)!)
      .toSet();
}

void main() {
  final ids = _seedIds();
  if (ids.isEmpty) {
    stderr.writeln('Found no exercise ids — has the seed data format changed?');
    exitCode = 1;
    return;
  }

  final present = Directory(_dir)
      .listSync()
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last)
      .where((n) => n.toLowerCase().endsWith('.gif') || n.toLowerCase().endsWith('.webp'))
      .toSet();

  final have = present.map((n) => n.substring(0, n.lastIndexOf('.'))).toSet();
  final missing = ids.difference(have).toList()..sort();
  final orphans = have.difference(ids).toList()..sort();

  stdout.writeln('${have.length} of ${ids.length} exercises have an animation.');

  if (orphans.isNotEmpty) {
    // The important half of this report. A file called
    // `barbell-bench-press.gif` sits in the folder looking done and never
    // reaches the app, because the app only ever looks for the exact id.
    stdout.writeln('\nFiles matching no exercise id (${orphans.length}):');
    for (final name in orphans) {
      stdout.writeln('  $name.gif');
    }
  }

  if (missing.isNotEmpty) {
    stdout.writeln('\nStill missing (${missing.length}):');
    for (final id in missing) {
      stdout.writeln('  $id.gif');
    }
  }

  final bytes = Directory(_dir)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.gif') || f.path.toLowerCase().endsWith('.webp'))
      .fold<int>(0, (sum, f) => sum + f.lengthSync());
  if (bytes > 0) {
    final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
    final each = (bytes / have.length / 1024).round();
    stdout.writeln('\n${mb}MB total, averaging ${each}KB each.');
    // All of this ships inside the APK; there is no server to stream from, so
    // the total *is* the cost to every user on first install. Reported as a
    // fact rather than a complaint: the project ships full-size GIFs on
    // purpose. Only an unreasonable figure is worth flagging.
    if (bytes > 30 * 1024 * 1024) {
      stdout.writeln(
        'That is a lot to add to a first download. See the README for the '
        'ffmpeg re-encode, which gets the set to roughly a fifth of this.',
      );
    }
  }
}
