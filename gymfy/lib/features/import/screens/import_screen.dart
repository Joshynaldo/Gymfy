import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/glass.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_segmented.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../data/csv_reader.dart';
import '../data/import_format.dart';
import '../data/import_repository.dart';

/// Bringing a training history in from another app.
///
/// Three steps on one screen, because the middle one is the reason the screen
/// exists: pick a file, **look at what it says**, then import. Writing a
/// couple of years of somebody's training straight off a file picker with no
/// confirmation is the kind of thing you only get to do to a person once.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  /// The parsed file, once one has been picked and understood.
  WorkoutImport? _preview;

  /// How many of its sessions the device already has.
  int _alreadyHere = 0;

  /// What the user says the file's weights are in, used only when the file
  /// does not say. Defaults to their own unit, which is the better guess than
  /// kilograms: someone who set the app to pounds trains in pounds.
  WeightUnit? _assumed;

  /// The raw text, kept so changing the assumed unit can re-read it without
  /// asking for the file again.
  String? _source;

  String? _error;
  ImportOutcome? _outcome;
  bool _busy = false;

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _error = null;
      _outcome = null;
    });
    try {
      final file = await FilePicker.pickFile();
      if (file == null) return;

      final source = utf8.decode(await file.readAsBytes());
      _source = source;
      _assumed ??= ref.read(weightUnitProvider);
      await _reparse();
    } on CsvException catch (error) {
      _fail(error.message);
    } on ImportFormatException catch (error) {
      _fail(error.message);
    } on FormatException {
      // utf8.decode on something that isn't text at all.
      _fail('That file is not readable as text. Export it again as CSV.');
    } catch (error) {
      _fail('Could not read that file.\n$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Re-reads the held text. Called again when the assumed unit changes.
  Future<void> _reparse() async {
    final source = _source;
    if (source == null) return;

    final parsed = parseWorkoutCsv(
      source,
      assumedUnit: _assumed ?? WeightUnit.kg,
    );
    final already = await ref
        .read(importRepositoryProvider)
        .countAlreadyHere(parsed);
    if (!mounted) return;
    setState(() {
      _preview = parsed;
      _alreadyHere = already;
      _error = null;
    });
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _preview = null;
      _source = null;
      _error = message;
    });
  }

  Future<void> _import() async {
    final preview = _preview;
    if (preview == null) return;

    setState(() => _busy = true);
    try {
      final outcome = await ref.read(importRepositoryProvider).apply(preview);
      if (!mounted) return;
      setState(() {
        _outcome = outcome;
        _preview = null;
        _source = null;
      });
    } catch (error) {
      _fail('Could not import that file.\n$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final outcome = _outcome;

    return GlassScaffold(
      appBar: GlassAppBar(title: const Text('Import a history')),
      body: (context) => ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 24) + barInsets(context),
        children: [
          const _Explainer(),
          if (_error != null) _ErrorPanel(message: _error!),
          if (outcome != null) _OutcomePanel(outcome: outcome),
          if (preview != null) ...[
            _PreviewPanel(preview: preview, alreadyHere: _alreadyHere),
            if (!preview.unitWasStated)
              _UnitPanel(
                unit: _assumed ?? WeightUnit.kg,
                onChanged: (unit) {
                  setState(() => _assumed = unit);
                  _reparse();
                },
              ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: AppButton(
              label: preview == null ? 'Choose a file' : 'Choose another file',
              icon: Icons.folder_open,
              kind: preview == null
                  ? AppButtonKind.primary
                  : AppButtonKind.secondary,
              onPressed: _busy ? null : _pick,
            ),
          ),
          if (preview != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: AppButton(
                // The number is on the button because this is the one action
                // here that changes data the user cannot see on screen.
                label: _busy
                    ? 'Importing…'
                    : 'Import ${preview.sessions.length - _alreadyHere} '
                          'workouts',
                icon: Icons.download,
                onPressed:
                    _busy || preview.sessions.length - _alreadyHere == 0
                    ? null
                    : _import,
              ),
            ),
        ],
      ),
    );
  }
}

class _Explainer extends StatelessWidget {
  const _Explainer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPanel(
      icon: Icons.move_to_inbox_outlined,
      title: 'Bring your history with you',
      child: Text(
        'Export your workouts from the other app as a CSV file, then pick it '
        'here. Hevy and Strong both do this from their settings.\n\n'
        'Columns are matched by name, so most exports work without anything '
        'being configured. Nothing is overwritten — importing only adds, and '
        'importing the same file twice adds nothing the second time.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );
  }
}

/// What the file turned out to contain, before anything is written.
class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.preview, required this.alreadyHere});

  final WorkoutImport preview;
  final int alreadyHere;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessions = preview.sessions;
    final incoming = sessions.length - alreadyHere;

    if (sessions.isEmpty) {
      return AppPanel(
        icon: Icons.help_outline,
        title: 'Nothing to import',
        child: Text(
          'That file was read, but none of its rows were sets — no exercise '
          'name, reps and weight together on any line.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return AppPanel(
      icon: Icons.fact_check_outlined,
      title: 'What is in this file',
      // Naming the app is reassurance at the one moment it is worth
      // something: just before committing a year of training on the strength
      // of a preview. Recognition only — the import does not depend on it.
      subtitle: preview.source == null
          ? null
          : 'Looks like a ${preview.source} export',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Line('Workouts', '${sessions.length}'),
          _Line('Sets', '${preview.setCount}'),
          _Line('Exercises', '${preview.exerciseNames.length}'),
          _Line(
            'From',
            '${formatShortDate(sessions.first.start)} '
                '${sessions.first.start.year}',
          ),
          _Line(
            'To',
            '${formatShortDate(sessions.last.start)} '
                '${sessions.last.start.year}',
          ),
          if (alreadyHere > 0)
            _Line('Already here', '$alreadyHere — will be skipped'),
          if (preview.skippedRows > 0)
            _Line('Rows that were not sets', '${preview.skippedRows}'),
          const SizedBox(height: 10),
          Text(
            incoming == 0
                ? 'Every workout in this file is already on your phone.'
                : '$incoming workouts will be added.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Only shown when the file does not say what unit its weights are in.
class _UnitPanel extends StatelessWidget {
  const _UnitPanel({required this.unit, required this.onChanged});

  final WeightUnit unit;
  final ValueChanged<WeightUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPanel(
      icon: Icons.scale_outlined,
      title: 'What unit is this file in?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // Said plainly, because it is the one thing on this screen that
            // cannot be checked afterwards by looking: 100 kg and 100 lbs are
            // both plausible numbers, and the wrong choice rewrites a whole
            // history by a factor of 2.2.
            'This export does not name its unit, so it has to be told. '
            'Getting it wrong scales every weight you import.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          AppSegmented<WeightUnit>(
            segments: const [
              (value: WeightUnit.kg, label: 'Kilograms', leading: null),
              (value: WeightUnit.lbs, label: 'Pounds', leading: null),
            ],
            selected: unit,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _OutcomePanel extends StatelessWidget {
  const _OutcomePanel({required this.outcome});

  final ImportOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPanel(
      icon: Icons.check_circle_outline,
      title: 'Imported',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Line('Workouts added', '${outcome.sessionsAdded}'),
          _Line('Sets added', '${outcome.setsAdded}'),
          if (outcome.sessionsSkipped > 0)
            _Line('Already here', '${outcome.sessionsSkipped} — skipped'),
          if (outcome.exercisesCreated.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              // Said rather than hidden, because these rows are incomplete in
              // a way that shows up later: no muscles means they are missing
              // from the muscle map and from every muscle filter.
              '${outcome.exercisesCreated.length} exercises were new and have '
              'been added to your library. They have no muscles set yet, so '
              'they will not appear on the muscle map until you edit them.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPanel(
      icon: Icons.error_outline,
      title: 'That file could not be read',
      child: SelectableText(
        // Selectable so the header line can be copied out of it. When a file
        // will not load, what its columns are called is the one piece of
        // information that turns this into a fix.
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );
  }
}
