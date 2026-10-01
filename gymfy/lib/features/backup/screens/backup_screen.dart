import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/theme/accent_color.dart';
import '../../../app/theme/glass.dart';
import '../../../shared/data/settings_repository.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_segmented.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../exercises/data/exercise_repository.dart';
import '../../workout/data/session_repository.dart';
import '../data/auto_backup.dart';
import '../data/backup_format.dart';
import '../data/backup_repository.dart';

/// Asks the user for a folder. A seam so widget tests can answer without a
/// platform picker; the app uses [FilePicker.getDirectoryPath].
final backupFolderPickerProvider = Provider<Future<String?> Function()>(
  (ref) =>
      () => FilePicker.getDirectoryPath(dialogTitle: 'Folder for backups'),
);

/// The folder used when the picked one can't be written to: the app's own
/// folder on shared storage (`Android/data/<app>/files/Backups`), which needs
/// no permission at all — but goes when the app is uninstalled.
final appBackupFolderProvider = Provider<Future<String> Function()>(
  (ref) => () async {
    final base =
        await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    return '${base.path}/Backups';
  },
);

/// Full backup and restore, and the automatic backup.
///
/// Separate from the data export on purpose. The export is a copy for reading
/// elsewhere; this is the one file that puts the app back exactly as it was,
/// and the screen says plainly which of the two you are holding.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  /// True while a backup or restore runs, so no button can start a second.
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return GlassScaffold(
      appBar: GlassAppBar(title: const Text('Backup & restore')),
      body: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24) + barInsets(context),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              'One file with everything in Gymfy — workouts, plans, '
              'exercises, measurements, meals, settings and progress '
              'photos. Restore it on this phone or a new one. Nothing is '
              'uploaded anywhere.',
              style: muted,
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
          const AppSectionHeader(title: 'Back up'),
          AppPanel(
            icon: Icons.backup_outlined,
            title: 'Save a backup',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saves a .$backupFileExtension file wherever you choose. '
                  'Keep a copy somewhere other than this phone.',
                  style: muted,
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _saveBackup,
                    icon: const Icon(Icons.save_alt, size: 18),
                    label: const Text('Save backup'),
                  ),
                ),
              ],
            ),
          ),
          const AppSectionHeader(title: 'Restore'),
          AppPanel(
            icon: Icons.settings_backup_restore,
            title: 'Restore from a backup',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replaces everything on this phone with what is in the '
                  'backup. You will see what it holds before anything '
                  'changes.',
                  style: muted,
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _restore,
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: const Text('Choose backup'),
                  ),
                ),
              ],
            ),
          ),
          const AppSectionHeader(title: 'Automatic backup'),
          _AutoBackupPanel(
            busy: _busy,
            onPickFolder: _pickFolder,
            onBackupNow: _backupToFolderNow,
          ),
        ],
      ),
    );
  }

  Future<void> _saveBackup() async {
    setState(() => _busy = true);
    try {
      final bytes = await ref
          .read(backupRepositoryProvider)
          .buildArchiveBytes();
      final name = backupFileName(DateTime.now());
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Save your backup',
        fileName: name,
        bytes: bytes,
      );
      if (saved == null) return; // Cancelled.
      _say('Saved $name');
    } catch (error) {
      _say('Could not save the backup.\n$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    // A workout open on another tab would be pointing at a session the
    // restore may delete or replace. Finishing it first is one tap; untangling
    // a live screen from rows that changed under it is not.
    final open = await ref
        .read(sessionRepositoryProvider)
        .watchInProgressSession()
        .first;
    if (open != null) {
      _say('Finish or discard your current workout before restoring.');
      return;
    }

    setState(() => _busy = true);
    try {
      final picked = await FilePicker.pickFile(dialogTitle: 'Choose a backup');
      if (picked == null) return;
      final path = await _localPath(picked);

      final repository = ref.read(backupRepositoryProvider);
      final summary = await repository.inspect(path);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _ConfirmRestoreDialog(summary: summary),
      );
      if (confirmed != true) return;

      await repository.restore(path);
      // A backup from an older app may predate exercises added to the built-in
      // library since; this is the same top-up every launch does.
      await ref.read(exerciseRepositoryProvider).seed();

      if (!mounted) return;
      _say('Backup restored.');
      context.go('/home');
    } on BackupException catch (error) {
      _say(error.message);
    } catch (error) {
      _say('Could not restore that backup.\n$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// A path the archive can be read from. The picker usually hands back a
  /// cached copy on disk; when it only has the bytes, they are written out.
  Future<String> _localPath(PlatformFile picked) async {
    final path = picked.path;
    if (path != null) return path;
    final temp = await getTemporaryDirectory();
    final file = File('${temp.path}/restore.$backupFileExtension');
    await file.writeAsBytes(await picked.readAsBytes());
    return file.path;
  }

  Future<void> _pickFolder() async {
    final path = await ref.read(backupFolderPickerProvider)();
    if (path == null || !mounted) return;

    final problem = await checkFolderWritable(path);
    if (!mounted) return;
    if (problem == null) {
      await _setFolder(path);
      return;
    }

    final fallback = await ref.read(appBackupFolderProvider)();
    if (!mounted) return;
    final useFallback = await showDialog<bool>(
      context: context,
      builder: (context) => GlassDialog(
        title: const Text('Gymfy can\'t write there'),
        content: Text(
          'Android only lets Gymfy save into some folders. Try a folder '
          'inside Documents or Download — or use Gymfy\'s own folder, which '
          'always works but is deleted if you uninstall the app:\n\n'
          '$fallback',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Use Gymfy\'s folder'),
          ),
        ],
      ),
    );
    if (useFallback != true) return;
    final fallbackProblem = await checkFolderWritable(fallback);
    if (fallbackProblem != null) {
      _say('Could not use that folder either.\n$fallbackProblem');
      return;
    }
    await _setFolder(fallback);
  }

  Future<void> _setFolder(String path) async {
    final settings = ref.read(settingsRepositoryProvider);
    await settings.write(autoBackupFolderKey, path);
    await settings.clear(autoBackupLastErrorKey);
    // Picking a folder is the moment someone is thinking about backups; if
    // they haven't chosen when, weekly is the sensible default.
    final mode = AutoBackupMode.parse(
      await settings.readRaw(autoBackupModeKey),
    );
    if (mode == AutoBackupMode.off) {
      await settings.write(autoBackupModeKey, AutoBackupMode.weekly.slug);
    }
    _say('Backups will be saved to $path');
  }

  Future<void> _backupToFolderNow() async {
    setState(() => _busy = true);
    try {
      final file = await ref.read(autoBackupServiceProvider).backupNow();
      if (file != null) _say('Saved ${file.uri.pathSegments.last}');
    } catch (error) {
      _say('Could not save the backup.\n$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// "Are you sure", with what the backup holds — so nobody replaces a year of
/// training with last spring's file by accident.
class _ConfirmRestoreDialog extends StatelessWidget {
  const _ConfirmRestoreDialog({required this.summary});

  final BackupSummary summary;

  @override
  Widget build(BuildContext context) {
    String count(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

    return GlassDialog(
      title: const Text('Replace everything?'),
      content: Text(
        'Backup from ${formatDateTime(summary.createdAt)}: '
        '${count(summary.workouts, 'workout')}, '
        '${count(summary.sets, 'set')}, '
        '${count(summary.photos, 'photo')}.\n\n'
        'Everything currently on this phone will be replaced by it. This '
        'cannot be undone — save a backup first if you might want today\'s '
        'data back.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Restore'),
        ),
      ],
    );
  }
}

/// When automatic backups run, where they go, and how the last one went.
class _AutoBackupPanel extends ConsumerWidget {
  const _AutoBackupPanel({
    required this.busy,
    required this.onPickFolder,
    required this.onBackupNow,
  });

  final bool busy;
  final VoidCallback onPickFolder;
  final VoidCallback onBackupNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final mode = ref.watch(autoBackupModeProvider);
    final folder = ref.watch(rawSettingProvider(autoBackupFolderKey)).value;
    final lastAt = DateTime.tryParse(
      ref.watch(rawSettingProvider(autoBackupLastAtKey)).value ?? '',
    );
    final lastError = ref
        .watch(rawSettingProvider(autoBackupLastErrorKey))
        .value;
    final hasFolder = folder != null && folder.isNotEmpty;

    return AppPanel(
      icon: Icons.schedule,
      title: 'Automatic backup',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSegmented<AutoBackupMode>(
            segments: [
              for (final m in AutoBackupMode.values)
                (
                  value: m,
                  label: m == AutoBackupMode.afterWorkout
                      ? 'After workout'
                      : m.label,
                  leading: null,
                ),
            ],
            selected: mode,
            onChanged: (next) async {
              if (next != AutoBackupMode.off && !hasFolder) {
                onPickFolder();
                return;
              }
              await ref
                  .read(settingsRepositoryProvider)
                  .write(autoBackupModeKey, next.slug);
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.folder_outlined),
            title: Text(hasFolder ? folder : 'No folder chosen'),
            subtitle: Text(
              lastError != null
                  ? 'Last automatic backup failed: $lastError'
                  : lastAt != null
                  ? 'Last backup ${formatDateTime(lastAt)}'
                  : 'No automatic backup yet',
              style: lastError != null
                  ? theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    )
                  : muted,
            ),
            trailing: TextButton(
              onPressed: busy ? null : onPickFolder,
              child: Text(hasFolder ? 'Change' : 'Choose'),
            ),
          ),
          if (hasFolder)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: busy ? null : onBackupNow,
                style: TextButton.styleFrom(foregroundColor: accent),
                icon: const Icon(Icons.backup_outlined, size: 18),
                label: const Text('Back up to folder now'),
              ),
            ),
          const SizedBox(height: 8),
          // Said up front, not discovered: there is no background job, and
          // Android limits where the app may write without extra permissions.
          Text(
            'Runs while Gymfy is open — when you open it once a week has '
            'passed, or right after you finish a workout. The last '
            '$autoBackupKeep automatic backups are kept. Choose a folder in '
            'Documents or Download; cloud drives and SD cards are not '
            'supported.',
            style: muted,
          ),
        ],
      ),
    );
  }
}
