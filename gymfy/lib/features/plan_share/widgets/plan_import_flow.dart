import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../data/plan_document.dart';
import '../data/plan_share_repository.dart';

/// Adds every split in [document] to the library, asking for a new name where
/// one clashes, and returns the ids of the splits that went in.
///
/// One flow for every way a plan arrives — a file someone sent you, or a
/// programme bundled with the app — so the rule that your own plan is never
/// overwritten can't hold in one place and not the other.
///
/// A split the user chooses to skip is simply not in the result; an empty list
/// means nothing was imported.
Future<List<int>> importPlanDocument(
  BuildContext context,
  WidgetRef ref,
  PlanDocument document,
) async {
  final repository = ref.read(planShareRepositoryProvider);
  final imported = <int>[];

  for (final split in document.splits) {
    // Re-read inside the loop: importing two splits called "Push" from one
    // file must ask twice, and the second question has to know about the
    // first answer.
    final taken = await repository.existingSplitNames();
    if (!context.mounted) return imported;

    var name = split.name;
    if (taken.contains(name)) {
      final chosen = await showDialog<String>(
        context: context,
        builder: (context) =>
            PlanRenameDialog(clashing: split.name, taken: taken),
      );
      if (chosen == null) continue; // Skipped this one.
      name = chosen;
    }

    imported.add(await repository.import(split, name: name));
  }

  return imported;
}

/// Asks for a free name, refusing to return one that's still taken.
///
/// A rename rather than an overwrite or a silent "(2)": your programme and
/// theirs share a name but are not the same thing, and quietly replacing
/// months of your own planning with someone else's would be unforgivable.
class PlanRenameDialog extends StatefulWidget {
  const PlanRenameDialog({
    super.key,
    required this.clashing,
    required this.taken,
  });

  final String clashing;
  final Set<String> taken;

  @override
  State<PlanRenameDialog> createState() => _PlanRenameDialogState();
}

class _PlanRenameDialogState extends State<PlanRenameDialog> {
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
      setState(() => _error = context.l10n.planShareRenameEmpty);
      return;
    }
    if (widget.taken.contains(name)) {
      setState(() => _error = context.l10n.planShareRenameTaken);
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GlassDialog(
      title: Text(l10n.planShareRenameTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.planShareRenameMessage(widget.clashing)),
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
              labelText: l10n.planShareRenameLabel,
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.planShareRenameSkip),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.planShareRenameImport),
        ),
      ],
    );
  }
}
