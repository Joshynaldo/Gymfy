import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/export_format.dart';
import '../data/export_repository.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Export data')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            'Save a copy of everything you have logged. The file is written '
            'wherever you choose — nothing is uploaded anywhere.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _FormatCard(
            icon: Icons.table_chart_outlined,
            title: 'Spreadsheet (CSV)',
            subtitle:
                'One row per set, ready to open in Excel or Sheets and chart '
                'however you like.',
            buttonLabel: 'Save CSV',
            onPressed: _busy ? null : _exportCsv,
          ),
          const SizedBox(height: 12),
          _FormatCard(
            icon: Icons.data_object,
            title: 'Everything (JSON)',
            subtitle:
                'Your workouts with their sets kept together, plus your body '
                'measurements and calorie log.',
            buttonLabel: 'Save JSON',
            onPressed: _busy ? null : _exportJson,
          ),
          const SizedBox(height: 24),
          Text(
            // Said plainly rather than discovered later. Someone exporting
            // before a phone swap needs to know this is a copy, not a backup.
            'These files are a copy for your own use. Gymfy cannot import them '
            'back, and progress photos are not included — they stay as image '
            'files on your phone.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv() => _save(
    extension: 'csv',
    build: (data) => toCsv(data.sets),
    emptyMessage: 'No finished workouts to export yet.',
  );

  Future<void> _exportJson() => _save(
    extension: 'json',
    build: toJson,
    // JSON carries measurements and meals too, so it can be worth saving even
    // with no workouts logged.
    emptyMessage: 'Nothing logged to export yet.',
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
        dialogTitle: 'Save your data',
        fileName: exportFileName(extension),
        bytes: utf8.encode(build(data)),
      );
      if (saved == null) return; // Cancelled.
      _say('Saved ${exportFileName(extension)}');
    } catch (error) {
      _say('Could not save that file.\n$error');
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
    return data.sets.isEmpty &&
        data.measurements.isEmpty &&
        data.meals.isEmpty;
  }

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
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;

  /// Null while an export is already running.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.save_alt),
                label: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
