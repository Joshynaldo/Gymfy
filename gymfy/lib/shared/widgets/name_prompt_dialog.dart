import 'package:flutter/material.dart';

/// Shows a simple "enter a name" dialog and returns the trimmed text, or null
/// if the user cancelled or left it blank.
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
  String confirmLabel = 'Create',
  String initialValue = '',
}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (context) => _NamePromptDialog(
      title: title,
      label: label,
      hint: hint,
      confirmLabel: confirmLabel,
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
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: widget.label, hintText: widget.hint),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
