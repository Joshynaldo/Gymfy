import 'package:flutter/material.dart';

import '../data/rest_timer_repository.dart';

/// The rest lengths offered in the picker: 30 seconds up to five minutes,
/// spaced the way people actually rest — finer at the short end.
const restLengthOptions = [30, 45, 60, 90, 120, 150, 180, 240, 300];

/// Returned by [showRestLengthPicker] to mean "drop the override and follow the
/// global default". Zero is outside the storable range on purpose, so it can
/// never be mistaken for a real rest length.
const clearRestLength = 0;

/// Asks for a rest length, returning seconds, or null if cancelled.
///
/// A list of common rests rather than a free-text field: nobody rests for 97
/// seconds, and a picker is far quicker mid-workout than a keyboard.
Future<int?> showRestLengthPicker(
  BuildContext context, {
  required int current,
  required String title,

  /// Label for the "no override, follow the default" option. Null hides it —
  /// the global default itself has nothing to fall back to.
  String? clearLabel,
}) {
  return showDialog<int>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);

      return SimpleDialog(
        title: Text(title),
        children: [
          for (final seconds in restLengthOptions)
            ListTile(
              title: Text(formatRest(seconds)),
              trailing: seconds == current
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(seconds),
            ),
          if (clearLabel != null) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings_backup_restore),
              title: Text(clearLabel),
              onTap: () => Navigator.of(context).pop(clearRestLength),
            ),
          ],
        ],
      );
    },
  );
}
