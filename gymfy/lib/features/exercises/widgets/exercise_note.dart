import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/glass.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../../../shared/widgets/pressable.dart';
import '../data/exercise_repository.dart';

/// What the editor gives back.
///
/// Three outcomes, not two, and the difference matters: the outer null means
/// the user backed out and whatever was stored must be left exactly as it was,
/// while `(text: null)` means they deliberately emptied the field and the note
/// should go. `showNamePromptDialog` collapses those two into one null, which
/// is right for "name a new split" and would be quietly destructive here —
/// tapping Cancel would wipe the note you opened to read.
typedef NoteEdit = ({String? text});

/// Asks for the note on [exercise], prefilled with whatever it already has.
///
/// A dialog rather than a sheet, matching `showNamePromptDialog`: this is one
/// field and two buttons, and Flutter lifts a dialog above the keyboard on its
/// own.
Future<NoteEdit?> showExerciseNoteDialog(
  BuildContext context,
  Exercise exercise,
) {
  return showDialog<NoteEdit>(
    context: context,
    builder: (context) => _NoteDialog(exercise: exercise),
  );
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.exercise});

  final Exercise exercise;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  // Owned by a StatefulWidget so it is disposed only once the dialog is fully
  // gone. Disposing it earlier crashes while the dialog animates away — the
  // same reason `_NamePromptDialog` is built this way.
  late final _controller = TextEditingController(
    text: widget.exercise.notes ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop((text: _controller.text));

  @override
  Widget build(BuildContext context) {
    final hadNote = widget.exercise.notes != null;

    return GlassDialog(
      title: Text(widget.exercise.name),
      content: TextField(
        controller: _controller,
        autofocus: true,
        // Several lines, because the useful note is rarely one fact: seat 4,
        // pins at 3, the machine by the window. Capped so a long one scrolls
        // inside the field instead of pushing the buttons off the screen.
        maxLines: 5,
        minLines: 3,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Note',
          hintText: 'Seat height, pin, grip width, which machine…',
          // Room for the text to breathe; a multi-line field with the default
          // dense padding reads as a box that has been sat on.
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        // Only offered when there is something to delete. A Clear button on an
        // empty field does nothing and still has to be understood.
        if (hadNote)
          TextButton(
            onPressed: () => Navigator.of(context).pop((text: null)),
            child: const Text('Clear'),
          ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

/// Opens the editor and writes the result. Does nothing if the user backed out.
Future<void> editExerciseNote(
  BuildContext context,
  WidgetRef ref,
  Exercise exercise,
) async {
  final edit = await showExerciseNoteDialog(context, exercise);
  if (edit == null) return;
  await ref.read(exerciseRepositoryProvider).setNotes(exercise.id, edit.text);
}

/// The note on an exercise, or an invitation to write one.
///
/// Shown wherever you might need it and tappable to edit in place, because the
/// moment you want a seat height is the moment you are standing at the machine
/// — not two screens away in a library you would have to go and find.
class ExerciseNoteTile extends ConsumerWidget {
  const ExerciseNoteTile({
    super.key,
    required this.exercise,
    this.dense = false,
  });

  final Exercise exercise;

  /// Tighter, for the card in a running session where the note is one line of
  /// several rather than the subject of the screen.
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final note = exercise.notes;
    final radius = BorderRadius.circular(dense ? 12 : 15);

    return Pressable(
      borderRadius: radius,
      splash: false,
      haptic: false,
      onTap: () => editExerciseNote(context, ref, exercise),
      child: GlassSurface(
        borderRadius: radius,
        tier: GlassTier.quiet,
        fallbackColor: theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 12 : 14,
            vertical: dense ? 10 : 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                note == null
                    ? Icons.sticky_note_2_outlined
                    : Icons.sticky_note_2,
                size: dense ? 15 : 17,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: dense ? 8 : 10),
              Expanded(
                child: Text(
                  // The empty state says what to write, not "No note". A
                  // labelled blank is a thing to wonder about; an example is
                  // an instruction.
                  note ?? 'Add a note — seat height, pin, grip…',
                  style: (dense
                          ? theme.textTheme.bodySmall
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(
                        color: note == null
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                        height: 1.35,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
