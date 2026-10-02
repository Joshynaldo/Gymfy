import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/theme/accent_color.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_language.dart';
import '../../../l10n/l10n.dart';
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
      () => FilePicker.getDirectoryPath(
        dialogTitle: ref.read(appLocalizationsProvider).backupFolderPickerTitle,
      ),
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
    final l10n = context.l10n;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return GlassScaffold(
      appBar: GlassAppBar(title: Text(l10n.backupTitle)),
      body: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24) + barInsets(context),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(l10n.backupIntro, style: muted),
          ),
          if (_busy) const LinearProgressIndicator(),
          AppSectionHeader(title: l10n.backupSectionBackUp),
          AppPanel(
            icon: LucideIcons.archiveRestore,
            title: l10n.backupSaveTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.backupSaveMessage(backupFileExtension), style: muted),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _saveBackup,
                    icon: const Icon(LucideIcons.download, size: 18),
                    label: Text(l10n.backupSaveButton),
                  ),
                ),
              ],
            ),
          ),
          AppSectionHeader(title: l10n.backupSectionRestore),
          AppPanel(
            icon: LucideIcons.rotateCcw,
            title: l10n.backupRestoreTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.backupRestoreMessage, style: muted),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _restore,
                    icon: const Icon(LucideIcons.folderOpen, size: 18),
                    label: Text(l10n.backupChooseButton),
                  ),
                ),
              ],
            ),
          ),
          AppSectionHeader(title: l10n.backupAutomaticTitle),
          _AutoBackupPanel(
            busy: _busy,
            onPickFolder: _pickFolder,
            onBackupNow: _backupToFolderNow,
          ),
        ],
      ),
    );
  }

  /// The strings for messages said after an await. [_say] checks [mounted]
  /// before showing anything, so the fallback is never seen.
  AppLocalizations get _l10n => mounted ? context.l10n : englishLocalizations;

  Future<void> _saveBackup() async {
    setState(() => _busy = true);
    try {
      final bytes = await ref
          .read(backupRepositoryProvider)
          .buildArchiveBytes();
      final name = backupFileName(DateTime.now());
      final saved = await FilePicker.saveFile(
        dialogTitle: _l10n.backupSaveDialogTitle,
        fileName: name,
        bytes: bytes,
      );
      if (saved == null) return; // Cancelled.
      _say(_l10n.backupSaved(name));
    } catch (error) {
      _say(_l10n.backupSaveFailed('$error'));
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
      _say(_l10n.backupFinishWorkoutFirst);
      return;
    }

    setState(() => _busy = true);
    try {
      final picked = await FilePicker.pickFile(
        dialogTitle: _l10n.backupPickDialogTitle,
      );
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
      _say(_l10n.backupRestored);
      context.go('/home');
    } on BackupException catch (error) {
      _say(error.describe(_l10n));
    } catch (error) {
      _say(_l10n.backupRestoreFailed('$error'));
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
        title: Text(context.l10n.backupCantWriteTitle),
        content: Text(context.l10n.backupCantWriteMessage(fallback)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.backupUseAppFolder),
          ),
        ],
      ),
    );
    if (useFallback != true) return;
    final fallbackProblem = await checkFolderWritable(fallback);
    if (fallbackProblem != null) {
      _say(_l10n.backupFolderFailed(fallbackProblem));
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
    _say(_l10n.backupFolderSet(path));
  }

  Future<void> _backupToFolderNow() async {
    setState(() => _busy = true);
    try {
      final file = await ref.read(autoBackupServiceProvider).backupNow();
      if (file != null) _say(_l10n.backupSaved(file.uri.pathSegments.last));
    } catch (error) {
      _say(_l10n.backupSaveFailed('$error'));
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
    final l10n = context.l10n;

    return GlassDialog(
      title: Text(l10n.backupReplaceTitle),
      content: Text(
        l10n.backupReplaceMessage(
          formatDateTime(summary.createdAt, l10n: l10n),
          summary.workouts,
          summary.sets,
          summary.photos,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.backupRestoreButton),
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
    final l10n = context.l10n;
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
      icon: LucideIcons.clock,
      title: l10n.backupAutomaticTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSegmented<AutoBackupMode>(
            segments: [
              for (final m in AutoBackupMode.values)
                (value: m, label: m.localizedLabel(l10n), leading: null),
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
            leading: const Icon(LucideIcons.folder),
            title: Text(hasFolder ? folder : l10n.backupNoFolder),
            subtitle: Text(
              lastError != null
                  ? l10n.backupLastFailed(lastError)
                  : lastAt != null
                  ? l10n.backupLastAt(formatDateTime(lastAt, l10n: l10n))
                  : l10n.backupNoneYet,
              style: lastError != null
                  ? theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    )
                  : muted,
            ),
            trailing: TextButton(
              onPressed: busy ? null : onPickFolder,
              child: Text(hasFolder ? l10n.backupChange : l10n.backupChoose),
            ),
          ),
          if (hasFolder)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: busy ? null : onBackupNow,
                style: TextButton.styleFrom(foregroundColor: accent),
                icon: const Icon(LucideIcons.archiveRestore, size: 18),
                label: Text(l10n.backupNowButton),
              ),
            ),
          const SizedBox(height: 8),
          // Said up front, not discovered: there is no background job, and
          // Android limits where the app may write without extra permissions.
          Text(l10n.backupAutoExplainer(autoBackupKeep), style: muted),
        ],
      ),
    );
  }
}
