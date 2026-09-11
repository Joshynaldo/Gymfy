// Material exports an animation curve also named `Split`; hide it so `Split`
// here unambiguously means our Drift row class.
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../workout/data/workout_repository.dart';
import '../data/plan_document.dart';
import '../data/plan_pdf.dart';
import '../data/plan_share_repository.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';
import '../../../shared/widgets/glass_dialog.dart';

/// Sharing plans: send your splits as a file, print them, or take someone
/// else's in.
class SharePlanScreen extends ConsumerStatefulWidget {
  const SharePlanScreen({super.key});

  @override
  ConsumerState<SharePlanScreen> createState() => _SharePlanScreenState();
}

class _SharePlanScreenState extends ConsumerState<SharePlanScreen> {
  /// Splits ticked for export. Ids rather than rows, so the selection survives
  /// the list rebuilding underneath it.
  final _selected = <int>{};

  /// True while an export or import is running, so the buttons can't be fired
  /// twice — the second tap would open a second share sheet behind the first.
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final splitsAsync = ref.watch(splitListProvider);

    return GlassScaffold(
      appBar: GlassAppBar(title: const Text('Share a plan')),
      body: splitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load your splits.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (splits) => FadeSlideIn(
          child: ListView(
            padding:
                const EdgeInsets.only(top: 4, bottom: 24) + barInsets(context),
            children: [
              const _Explainer(),
              if (splits.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Text(
                    'You have no splits to save yet — but you can still '
                    'import one from someone else.',
                  ),
                )
              else ...[
                AppSectionHeader(
                  title: 'Send',
                  // Counts what is ticked, not how many exist: the number that
                  // matters here is how many are about to leave the phone.
                  count: _selected.isEmpty ? null : _selected.length,
                ),
                for (final split in splits)
                  _SplitCheckbox(
                    split: split,
                    selected: _selected.contains(split.id),
                    onChanged: (_) => setState(() {
                      if (!_selected.remove(split.id)) _selected.add(split.id);
                    }),
                  ),
                const SizedBox(height: 4),
                _Actions(
                  enabled: _selected.isNotEmpty && !_busy,
                  onSave: _saveFile,
                  onPrint: _printPdf,
                ),
              ],
              const AppSectionHeader(title: 'Receive'),
              AppTile(
                icon: Icons.download,
                title: 'Import a plan',
                subtitle: 'Open a .gymfy file someone sent you',
                trailing: null,
                onTap: _busy ? null : _import,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the document for whatever is ticked.
  Future<PlanDocument> _document() {
    return ref.read(planShareRepositoryProvider).export(_selected.toList());
  }

  /// Writes the plan wherever the user chooses, via the system save dialog.
  ///
  /// A save rather than a direct share sheet: the only Flutter share plugin
  /// available can't be built alongside the file picker on this toolchain (see
  /// pubspec). Saving turns out to be no worse — the file lands somewhere the
  /// user picked and their file manager can send it on from there, whereas a
  /// share sheet leaves them nothing to send twice.
  Future<void> _saveFile() async {
    setState(() => _busy = true);
    try {
      final document = await _document();
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Save your plan',
        fileName: planFileName(document),
        bytes: utf8.encode(document.encode()),
      );
      if (saved == null) return; // Cancelled.
      _say('Plan saved — send it from your files app.');
    } catch (error) {
      _complain('Could not save that plan.\n$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _printPdf() async {
    setState(() => _busy = true);
    try {
      final document = await _document();
      final bytes = await buildPlanPdf(document);
      // The system sheet handles printing *and* "save as PDF" / share, so one
      // button covers both without us guessing which one was meant.
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: planFileName(document).replaceAll('.$planFileExtension', ''),
      );
    } catch (error) {
      _complain('Could not build that PDF.\n$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final file = await FilePicker.pickFile();
      if (file == null) return;

      final source = utf8.decode(await file.readAsBytes());

      final document = PlanDocument.decode(source);
      if (!mounted) return;
      await _merge(document);
    } on PlanFormatException catch (error) {
      // Its message is already written for a person to read.
      _complain(error.message);
    } catch (error) {
      _complain('Could not read that file.\n$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Adds each split from [document], asking for a new name where one clashes.
  Future<void> _merge(PlanDocument document) async {
    final repository = ref.read(planShareRepositoryProvider);
    var imported = 0;

    for (final split in document.splits) {
      // Re-read inside the loop: importing two splits called "Push" from one
      // file must ask twice, and the second question has to know about the
      // first answer.
      final taken = await repository.existingSplitNames();
      if (!mounted) return;

      var name = split.name;
      if (taken.contains(name)) {
        final chosen = await _askForName(split.name, taken);
        if (chosen == null) continue; // Skipped this one.
        name = chosen;
      }

      await repository.import(split, name: name);
      imported++;
    }

    if (!mounted) return;
    _say(
      imported == 0
          ? 'Nothing imported'
          : imported == 1
          ? 'Plan imported'
          : '$imported plans imported',
    );
  }

  /// Asks the user to rename a split whose name is already in use.
  ///
  /// A rename rather than an overwrite or a silent "(2)": your programme and
  /// theirs share a name but are not the same thing, and quietly replacing
  /// months of your own planning with someone else's would be unforgivable.
  Future<String?> _askForName(String clashing, Set<String> taken) {
    return showDialog<String>(
      context: context,
      builder: (context) => _RenameDialog(clashing: clashing, taken: taken),
    );
  }

  void _complain(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _say(String message) => _complain(message);
}

/// Asks for a free name, refusing to return one that's still taken.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.clashing, required this.taken});

  final String clashing;
  final Set<String> taken;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(
    text: suggestFreeName(widget.clashing, widget.taken),
  );

  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give it a name.');
      return;
    }
    if (widget.taken.contains(name)) {
      setState(() => _error = 'You already have a plan called that.');
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      title: const Text('Name already used'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You already have a plan called "${widget.clashing}". Give the '
            'imported one a different name — your own plan is kept either way.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              labelText: 'Plan name',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Skip this one'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Import')),
      ],
    );
  }
}

class _Explainer extends StatelessWidget {
  const _Explainer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        // Says what is *not* in the file. Someone about to send their programme
        // to a stranger deserves to know that before they tap, not after.
        'A plan file holds your splits, their days and the exercises in them. '
        'It never includes your workouts, your weights, your measurements or '
        'your photos.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SplitCheckbox extends ConsumerWidget {
  const _SplitCheckbox({
    required this.split,
    required this.selected,
    required this.onChanged,
  });

  final Split split;
  final bool selected;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // An AppTile rather than a CheckboxListTile: the card's own selected state
    // already means "this one is picked" everywhere else in the app — accent
    // border, tinted surface, tick in place of the glyph — so a checkbox would
    // be a second, competing way to say the same thing.
    return AppTile(
      icon: Icons.calendar_view_week,
      title: split.name,
      subtitle: split.isActive ? 'Active' : null,
      trailing: null,
      selected: selected,
      onTap: () => onChanged(!selected),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.enabled,
    required this.onSave,
    required this.onPrint,
  });

  final bool enabled;
  final VoidCallback onSave;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: enabled ? onSave : null,
              icon: const Icon(Icons.save_alt),
              label: const Text('Save file'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: enabled ? onPrint : null,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('PDF'),
            ),
          ),
        ],
      ),
    );
  }
}
