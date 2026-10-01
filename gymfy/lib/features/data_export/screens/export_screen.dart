import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets/app_card.dart';
import '../data/export_format.dart';
import '../data/export_repository.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';

/// Getting your data out of the app.
///
/// Worth having before anyone trusts the app with a year of training: data you
/// can't get out isn't really yours. Nothing here talks to a server — the file
/// goes wherever you point the save dialog.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  /// True while a file is being built, so neither button can be fired twice.
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return GlassScaffold(
      appBar: GlassAppBar(title: Text(l10n.dataExportTitle)),
      body: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24) + barInsets(context),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              l10n.dataExportIntro,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          AppSectionHeader(title: l10n.dataExportFormatTitle),
          _FormatCard(
            icon: Icons.table_chart_outlined,
            title: l10n.dataExportCsvTitle,
            badge: 'CSV',
            subtitle: l10n.dataExportCsvSubtitle,
            buttonLabel: l10n.dataExportCsvButton,
            onPressed: _busy ? null : _exportCsv,
          ),
          _FormatCard(
            icon: Icons.data_object,
            title: l10n.dataExportJsonTitle,
            badge: 'JSON',
            subtitle: l10n.dataExportJsonSubtitle,
            buttonLabel: l10n.dataExportJsonButton,
            onPressed: _busy ? null : _exportJson,
          ),
          const SizedBox(height: 12),
          // Said plainly rather than discovered later. Someone exporting
          // before a phone swap needs to know this is a copy, not a backup —
          // so it gets a panel of its own instead of being small print they
          // scroll past.
          AppPanel(
            icon: Icons.info_outline,
            title: l10n.dataExportCopyTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dataExportCopyMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => context.go('/more/settings/backup'),
                    icon: const Icon(Icons.backup_outlined, size: 18),
                    label: Text(l10n.backupTitle),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv() => _save(
    extension: 'csv',
    build: (data) => toCsv(data.sets),
    emptyMessage: context.l10n.dataExportNoWorkouts,
  );

  Future<void> _exportJson() => _save(
    extension: 'json',
    build: toJson,
    // JSON carries measurements and meals too, so it can be worth saving even
    // with no workouts logged.
    emptyMessage: context.l10n.dataExportNothing,
  );

  Future<void> _save({
    required String extension,
    required String Function(ExportData) build,
    required String emptyMessage,
  }) async {
    setState(() => _busy = true);
    try {
      final data = await ref.read(exportRepositoryProvider).load();
      if (_isEmpty(data, extension)) {
        _say(emptyMessage);
        return;
      }

      final saved = await FilePicker.saveFile(
        dialogTitle: _l10n.dataExportSaveDialogTitle,
        fileName: exportFileName(extension),
        bytes: utf8.encode(build(data)),
      );
      if (saved == null) return; // Cancelled.
      _say(_l10n.dataExportSaved(exportFileName(extension)));
    } catch (error) {
      _say(_l10n.dataExportSaveFailed('$error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Whether there is nothing worth writing.
  ///
  /// Checked before the save dialog rather than after: handing someone a file
  /// picker and then giving them a header row with no data under it wastes
  /// their time and looks like the export is broken.
  bool _isEmpty(ExportData data, String extension) {
    if (extension == 'csv') return data.sets.isEmpty;
    return data.sets.isEmpty && data.measurements.isEmpty && data.meals.isEmpty;
  }

  /// The strings for messages said after an await. [_say] checks [mounted]
  /// before showing anything, so the fallback is never seen.
  AppLocalizations get _l10n => mounted ? context.l10n : englishLocalizations;

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// One export option: what it is, what it's good for, and the button.
class _FormatCard extends StatelessWidget {
  const _FormatCard({
    required this.icon,
    required this.title,
    required this.badge,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;

  /// The file extension, as a chip. Split out of the title so the two cards
  /// differ by a word you can read at a glance rather than by a parenthesis.
  final String badge;

  final String subtitle;
  final String buttonLabel;

  /// Null while an export is already running.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPanel(
      icon: icon,
      title: title,
      trailing: _Badge(label: badge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.save_alt, size: 18),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small tag for a file extension.
class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
