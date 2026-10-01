import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/data/settings_repository.dart';
import '../../workout/data/session_repository.dart';
import 'backup_format.dart';
import 'backup_repository.dart';

part 'auto_backup.g.dart';

/// Settings keys, reserved in FEATURE_PLAN.md. Spelled once, here.
const autoBackupModeKey = 'auto_backup_mode';
const autoBackupFolderKey = 'auto_backup_folder';
const autoBackupLastAtKey = 'auto_backup_last_at';

/// Why the last automatic backup failed, or unset if it succeeded. Kept so the
/// backup screen can say so: an automatic backup that has been quietly failing
/// for a month is worse than none, because you think you have one.
const autoBackupLastErrorKey = 'auto_backup_last_error';

/// How often a weekly backup runs.
const autoBackupInterval = Duration(days: 7);

/// How many automatic backups are kept in the folder before the oldest go.
/// Ten weeks of weekly backups, or the last ten workouts.
const autoBackupKeep = 10;

/// When automatic backups run.
enum AutoBackupMode {
  off('off', 'Off'),
  weekly('weekly', 'Weekly'),
  afterWorkout('after_workout', 'After each workout');

  const AutoBackupMode(this.slug, this.label);

  /// What is stored in the settings table.
  final String slug;
  final String label;

  /// Reads a stored value. Anything unrecognised is [off]: a backup that runs
  /// when nobody asked for it would be writing files into a folder the user
  /// may no longer expect.
  static AutoBackupMode parse(String? raw) => values.firstWhere(
    (mode) => mode.slug == raw,
    orElse: () => AutoBackupMode.off,
  );
}

/// What asked for a backup.
enum AutoBackupTrigger {
  /// The app was opened or came back to the foreground.
  appOpened,

  /// A workout was just finished.
  workoutFinished,
}

/// Whether an automatic backup should run now.
///
/// Weekly runs whenever the app is opened and the last backup is a week old
/// (or there never was one). After-workout runs on finishing a workout — and
/// also falls back to weekly when the app is opened, so someone who stops
/// training doesn't stop being backed up because nothing triggers it.
bool isAutoBackupDue({
  required AutoBackupMode mode,
  required AutoBackupTrigger trigger,
  required DateTime? lastAt,
  required DateTime now,
}) {
  if (mode == AutoBackupMode.off) return false;
  if (mode == AutoBackupMode.afterWorkout &&
      trigger == AutoBackupTrigger.workoutFinished) {
    return true;
  }
  return lastAt == null || now.difference(lastAt) >= autoBackupInterval;
}

/// Writes backups into the folder the user picked, on a schedule.
///
/// There is no background job: Android would need WorkManager (a new plugin)
/// to wake the app, and this app stays off the network and light on plugins.
/// So "weekly" means "the first time the app is open once a week has passed",
/// which for a training log — opened every time you train — is close enough.
class AutoBackupService {
  AutoBackupService(this._backups, this._settings);

  final BackupRepository _backups;
  final SettingsRepository _settings;

  /// Set while a backup is being written, so a workout finished during the
  /// weekly backup doesn't start a second one writing beside it.
  Future<File?>? _running;

  /// Runs a backup if [trigger] makes one due. Returns the file written, or
  /// null if none was due. Never throws: a failure is recorded under
  /// [autoBackupLastErrorKey] for the backup screen to show.
  Future<File?> runIfDue(AutoBackupTrigger trigger) async {
    final mode = AutoBackupMode.parse(
      await _settings.readRaw(autoBackupModeKey),
    );
    final folder = await _settings.readRaw(autoBackupFolderKey);
    if (folder == null || folder.isEmpty) return null;

    final lastAt = DateTime.tryParse(
      await _settings.readRaw(autoBackupLastAtKey) ?? '',
    );
    final due = isAutoBackupDue(
      mode: mode,
      trigger: trigger,
      lastAt: lastAt,
      now: clock.now(),
    );
    if (!due) return null;

    try {
      return await backupNow();
    } catch (_) {
      return null; // Already recorded by backupNow.
    }
  }

  /// Writes a backup into the chosen folder now, whatever the schedule says.
  Future<File?> backupNow() {
    return _running ??= _write().whenComplete(() => _running = null);
  }

  Future<File?> _write() async {
    final folder = await _settings.readRaw(autoBackupFolderKey);
    if (folder == null || folder.isEmpty) return null;

    try {
      final dir = Directory(folder);
      if (!dir.existsSync()) await dir.create(recursive: true);

      final now = clock.now();
      final file = await _backups.writeArchive(
        _freePath(dir, backupFileName(now)),
        now: now,
      );
      await _settings.write(autoBackupLastAtKey, now.toIso8601String());
      await _settings.clear(autoBackupLastErrorKey);
      await pruneBackups(dir);
      return file;
    } catch (error) {
      await _settings.write(autoBackupLastErrorKey, '$error');
      rethrow;
    }
  }

  /// A path in [dir] named [name], or with a counter added if that is taken —
  /// two backups in one minute, say, a weekly one and an after-workout one.
  String _freePath(Directory dir, String name) {
    var path = '${dir.path}/$name';
    final stem = name.substring(
      0,
      name.length - backupFileExtension.length - 1,
    );
    for (var n = 2; File(path).existsSync(); n++) {
      path = '${dir.path}/$stem-$n.$backupFileExtension';
    }
    return path;
  }
}

/// Deletes all but the newest [keep] automatic backups in [dir].
///
/// Only files named exactly the way [backupFileName] names them are touched, so
/// a folder shared with anything else — photos, documents, a backup the user
/// renamed to keep — is left alone.
Future<void> pruneBackups(Directory dir, {int keep = autoBackupKeep}) async {
  final backups = <File>[];
  await for (final entity in dir.list()) {
    if (entity is File && isBackupFileName(_baseName(entity.path))) {
      backups.add(entity);
    }
  }
  if (backups.length <= keep) return;
  // Names sort by date, so newest last.
  backups.sort((a, b) => _baseName(a.path).compareTo(_baseName(b.path)));
  for (final old in backups.take(backups.length - keep)) {
    try {
      await old.delete();
    } on FileSystemException {
      // On Android 11+ a file left by a previous install of the app is no
      // longer ours to delete. Leaving it is harmless.
    }
  }
}

/// Checks that the app can actually write into [path], by writing and removing
/// a tiny file. Returns null if it can, or the reason it can't.
///
/// Asked the moment a folder is picked rather than discovered a week later: on
/// Android the folder picker will happily offer folders this app is not
/// allowed to write to, and it is far better to say so while the user is
/// still looking at the picker.
Future<String?> checkFolderWritable(String path) async {
  try {
    final dir = Directory(path);
    if (!dir.existsSync()) await dir.create(recursive: true);
    final probe = File('${dir.path}/.gymfy-write-test');
    await probe.writeAsString('ok', flush: true);
    await probe.delete();
    return null;
  } on FileSystemException catch (error) {
    return error.osError?.message ?? error.message;
  }
}

String _baseName(String path) => path.split(RegExp(r'[/\\]')).last;

/// App-wide access to the [AutoBackupService].
@Riverpod(keepAlive: true)
AutoBackupService autoBackupService(Ref ref) {
  return AutoBackupService(
    ref.watch(backupRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
  );
}

/// The automatic-backup mode, watched.
final autoBackupModeProvider = Provider<AutoBackupMode>((ref) {
  return AutoBackupMode.parse(
    ref.watch(rawSettingProvider(autoBackupModeKey)).value,
  );
});

/// Runs automatic backups when they are due.
///
/// Watched from the app root, like the watch sync, because the moments that
/// matter — opening the app, finishing a workout — happen on screens that have
/// nothing to do with backups.
@Riverpod(keepAlive: true)
class AutoBackupWatcher extends _$AutoBackupWatcher {
  @override
  void build() {
    final service = ref.watch(autoBackupServiceProvider);

    // After the first frame rather than during startup: a backup is the least
    // urgent thing the app does at launch, and the first screen should not
    // wait on a zip being written.
    Future<void>.delayed(
      Duration.zero,
      () => service.runIfDue(AutoBackupTrigger.appOpened),
    );

    final lifecycle = AppLifecycleListener(
      onResume: () => service.runIfDue(AutoBackupTrigger.appOpened),
    );
    ref.onDispose(lifecycle.dispose);

    ref.listen(lastCompletedSessionProvider, (previous, next) {
      // The first value is what was already there at launch, not a finish.
      if (previous == null || !previous.hasValue) return;
      if (isNewlyFinished(
        before: previous.value?.completedAt,
        after: next.value?.completedAt,
      )) {
        service.runIfDue(AutoBackupTrigger.workoutFinished);
      }
    });
  }
}

/// Whether the latest finished workout moving from [before] to [after] means
/// one was just completed.
///
/// Compared by finish time, not id: deleting your latest workout makes an
/// older one "last", and that is not finishing anything.
bool isNewlyFinished({required DateTime? before, required DateTime? after}) {
  if (after == null) return false;
  return before == null || after.isAfter(before);
}
