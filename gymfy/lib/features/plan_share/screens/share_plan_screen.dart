// Material exports an animation curve also named `Split`; hide it so `Split`
// here unambiguously means our Drift row class.
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:printing/printing.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/widgets/app_card.dart';
import '../../workout/data/workout_repository.dart';
import '../data/plan_document.dart';
import '../data/plan_pdf.dart';
import '../data/plan_share_repository.dart';
import '../widgets/plan_import_flow.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';

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
    final l10n = context.l10n;
    final splitsAsync = ref.watch(splitListProvider);

    return GlassScaffold(
      appBar: GlassAppBar(title: Text(l10n.planShareTitle)),
      body: (context) => splitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.workoutSplitsLoadFailed('$error'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (splits) => ListView(
          padding:
              const EdgeInsets.only(top: 4, bottom: 24) + barInsets(context),
          children: [
            const _Explainer(),
            if (splits.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Text(l10n.planShareNoSplits),
              )
            else ...[
              AppSectionHeader(
                title: l10n.planShareSend,
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
            AppSectionHeader(title: l10n.planShareReceive),
            AppTile(
              icon: LucideIcons.download,
              title: l10n.planShareImportTitle,
              subtitle: l10n.planShareImportSubtitle,
              trailing: null,
              onTap: _busy ? null : _import,
            ),
          ],
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
    final l10n = context.l10n;
    try {
      final document = await _document();
      final saved = await FilePicker.saveFile(
        dialogTitle: l10n.planShareSaveDialogTitle,
        fileName: planFileName(document),
        bytes: utf8.encode(document.encode()),
      );
      if (saved == null) return; // Cancelled.
      _say(l10n.planShareSaved);
    } catch (error) {
      _complain(l10n.planShareSaveFailed('$error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _printPdf() async {
    setState(() => _busy = true);
    final l10n = context.l10n;
    try {
      final document = await _document();
      final bytes = await buildPlanPdf(document, l10n: l10n);
      // The system sheet handles printing *and* "save as PDF" / share, so one
      // button covers both without us guessing which one was meant.
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: planFileName(document).replaceAll('.$planFileExtension', ''),
      );
    } catch (error) {
      _complain(l10n.planSharePdfFailed('$error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    final l10n = context.l10n;
    try {
      final file = await FilePicker.pickFile();
      if (file == null) return;

      final source = utf8.decode(await file.readAsBytes());

      final document = PlanDocument.decode(source);
      if (!mounted) return;
      await _merge(document);
    } on PlanFormatException catch (error) {
      // It knows what went wrong; this screen knows the language.
      _complain(error.describe(l10n));
    } catch (error) {
      _complain(l10n.planShareReadFailed('$error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Adds each split from [document], asking for a new name where one clashes.
  ///
  /// The flow itself is shared with the bundled programmes, see
  /// plan_import_flow.dart.
  Future<void> _merge(PlanDocument document) async {
    final imported = (await importPlanDocument(context, ref, document)).length;

    if (!mounted) return;
    _say(context.l10n.planShareImported(imported));
  }

  void _complain(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _say(String message) => _complain(message);
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
        context.l10n.planShareExplainer,
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
      icon: LucideIcons.calendarRange,
      title: split.name,
      subtitle: split.isActive ? context.l10n.commonActive : null,
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
              icon: const Icon(LucideIcons.download),
              label: Text(context.l10n.planShareSaveFile),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: enabled ? onPrint : null,
              icon: const Icon(LucideIcons.fileText),
              label: Text(context.l10n.planSharePdf),
            ),
          ),
        ],
      ),
    );
  }
}
