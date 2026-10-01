import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/glass_dialog.dart';

/// Shows a simple "enter a name" dialog and returns the trimmed text, or null
/// if the user cancelled or left it blank.
///
/// [confirmLabel] defaults to "Create" in the app's language.
///
/// Used for creating splits and days. It owns its
/// [TextEditingController] via a [StatefulWidget] so the controller is disposed
/// only when the dialog is fully gone — disposing it earlier crashes while the
/// dialog animates away.
Future<String?> showNamePromptDialog(
  BuildContext context, {
  required String title,
  required String label,
  String? hint,
  String? confirmLabel,
  String initialValue = '',
}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (context) => _NamePromptDialog(
      title: title,
      label: label,
      hint: hint,
      confirmLabel: confirmLabel ?? context.l10n.commonCreate,
      initialValue: initialValue,
    ),
  );

  final trimmed = result?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

class _NamePromptDialog extends StatefulWidget {
  const _NamePromptDialog({
    required this.title,
    required this.label,
    required this.hint,
    required this.confirmLabel,
    required this.initialValue,
  });

  final String title;
  final String label;
  final String? hint;
  final String confirmLabel;
  final String initialValue;

  @override
  State<_NamePromptDialog> createState() => _NamePromptDialogState();
}

class _NamePromptDialogState extends State<_NamePromptDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
