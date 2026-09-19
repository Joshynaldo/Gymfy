import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/models/exercise.dart' show isBundledAsset;
import '../../../shared/models/equipment.dart';
import '../../../shared/models/muscle_ids.dart';
import '../../../shared/utils/exercise_display.dart';
import '../data/exercise_repository.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/app_picker.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';

/// Creates a new custom exercise, or edits an existing one when [exerciseId] is
/// given.
///
/// One screen for both because the fields are identical — the only differences
/// are the title, the prefilled values, and which repository method runs on
/// save. Two near-identical screens would drift apart the first time a field is
/// added.
class ExerciseFormScreen extends ConsumerStatefulWidget {
  const ExerciseFormScreen({super.key, this.exerciseId});

  /// The exercise being edited, or null when creating a new one.
  final String? exerciseId;

  bool get isEditing => exerciseId != null;

  @override
  ConsumerState<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends ConsumerState<ExerciseFormScreen> {
  final _nameController = TextEditingController();
  final _muscleIds = <String>{};

  /// Whether sets for this exercise are logged by stacking plates.
  bool _plateLoaded = false;

  /// Defaults to `other` rather than guessing from the name: a guess that is
  /// wrong puts the exercise behind the wrong chip, where its owner will not
  /// think to look for it.
  Equipment _equipment = Equipment.other;

  /// The stored image path, once saved. Null means "no image".
  String? _imagePath;

  /// A gallery pick that hasn't been copied into app storage yet. Copying is
  /// deferred to save, so backing out of the form leaves nothing behind.
  File? _pickedImage;

  /// Edit mode fills the form from the database exactly once — refilling on
  /// every rebuild would fight the user for control of the fields.
  bool _prefilled = false;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEditing) {
      return _form(context, canSave: true);
    }

    final exerciseAsync = ref.watch(exerciseProvider(widget.exerciseId!));
    return exerciseAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: GlassAppBar(title: const Text('Edit exercise')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load this exercise.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (exercise) {
        if (exercise == null) {
          return GlassScaffold(
            appBar: GlassAppBar(title: const Text('Edit exercise')),
            body: (context) => const Center(child: Text('Exercise not found.')),
          );
        }
        _prefill(exercise);
        return _form(context, canSave: true);
      },
    );
  }

  void _prefill(Exercise exercise) {
    if (_prefilled) return;
    _prefilled = true;
    _nameController.text = exercise.name;
    _muscleIds
      ..clear()
      ..addAll(exercise.muscleIds);
    _plateLoaded = exercise.isPlateLoaded;
    _equipment = Equipment.parse(exercise.equipment);
    _imagePath = exercise.gifPath;
  }

  Widget _form(BuildContext context, {required bool canSave}) {
    final theme = Theme.of(context);

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(widget.isEditing ? 'Edit exercise' : 'New exercise'),
      ),
      body: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96) + barInsets(context),
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Cable Fly',
              border: OutlineInputBorder(),
            ),
            // Rebuilds so the save button enables the moment a name is typed.
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Text('Muscles worked', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Drives the muscle map, so pick everything this lift actually hits.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final muscleId in MuscleId.all)
                AppChip(
                  label: muscleLabel(muscleId),
                  selected: _muscleIds.contains(muscleId),
                  onTap: () => setState(() {
                    if (_muscleIds.contains(muscleId)) {
                      _muscleIds.remove(muscleId);
                    } else {
                      _muscleIds.add(muscleId);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Above the plate switch, because it is the coarser question and
          // the answer to it often settles the switch: nothing bodyweight is
          // plate-loaded.
          AppPickerField(
            label: 'Equipment',
            value: _equipment.label,
            icon: Icons.fitness_center,
            onTap: () async {
              final picked = await showOptionPicker<Equipment>(
                context: context,
                title: 'Equipment',
                selected: _equipment,
                options: [
                  for (final equipment in Equipment.values)
                    (value: equipment, label: equipment.label, subtitle: null),
                ],
              );
              if (picked != null) setState(() => _equipment = picked);
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Loaded with plates'),
            subtitle: const Text(
              'Log sets by tapping plates instead of typing a weight. For '
              'barbell and EZ-bar lifts.',
            ),
            value: _plateLoaded,
            onChanged: (value) => setState(() => _plateLoaded = value),
          ),
          const SizedBox(height: 12),
          Text('Image', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Optional. A GIF from your gallery animates just like the built-in '
            'ones.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _ImagePickerTile(
            pickedImage: _pickedImage,
            storedPath: _imagePath,
            onPick: _pickImage,
            onClear: () => setState(() {
              _pickedImage = null;
              _imagePath = null;
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _canSave && !_busy ? _save : null,
        icon: const Icon(Icons.check),
        label: Text(widget.isEditing ? 'Save' : 'Create'),
      ),
    );
  }

  /// A name and at least one muscle. Without a muscle the exercise would be
  /// invisible to the muscle map and contribute to no volume total, which looks
  /// like a bug rather than a choice.
  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _muscleIds.isNotEmpty;

  Future<void> _pickImage() async {
    // No resizing or re-encoding: those would flatten an animated GIF into a
    // single still frame.
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _pickedImage = File(picked.path));
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final repository = ref.read(exerciseRepositoryProvider);
    final router = GoRouter.of(context);
    final name = _nameController.text.trim();
    final muscleIds = _muscleIds.toList()..sort();

    try {
      if (widget.isEditing) {
        final id = widget.exerciseId!;
        final imagePath = _pickedImage == null
            ? _imagePath
            : await repository.saveImage(_pickedImage!, exerciseId: id);
        await repository.updateCustom(
          id: id,
          name: name,
          isPlateLoaded: _plateLoaded,
          equipment: _equipment,
          muscleIds: muscleIds,
          imagePath: imagePath,
        );
      } else {
        // The id is derived from the name, so it only exists after the insert —
        // which is why an image is saved and attached in a second step.
        final id = await repository.createCustom(
          name: name,
          isPlateLoaded: _plateLoaded,
          equipment: _equipment,
          muscleIds: muscleIds,
        );
        if (_pickedImage != null) {
          final imagePath = await repository.saveImage(
            _pickedImage!,
            exerciseId: id,
          );
          await repository.updateCustom(
            id: id,
            name: name,
            isPlateLoaded: _plateLoaded,
            equipment: _equipment,
            muscleIds: muscleIds,
            imagePath: imagePath,
          );
        }
      }
      router.pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Shows the chosen image (or a prompt to choose one) with a way to replace or
/// remove it.
class _ImagePickerTile extends StatelessWidget {
  const _ImagePickerTile({
    required this.pickedImage,
    required this.storedPath,
    required this.onPick,
    required this.onClear,
  });

  /// A gallery pick not yet written to app storage — takes precedence, since
  /// it's the newer of the two.
  final File? pickedImage;

  /// The already-saved image path, if any.
  final String? storedPath;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _preview();

    if (preview == null) {
      return OutlinedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.image_outlined),
        label: const Text('Choose image'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1,
            child: ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest,
              child: preview,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Replace'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget? _preview() {
    if (pickedImage != null) {
      return Image.file(pickedImage!, fit: BoxFit.contain);
    }
    final path = storedPath;
    if (path == null) return null;
    return isBundledAsset(path)
        ? Image.asset(path, fit: BoxFit.contain)
        : Image.file(File(path), fit: BoxFit.contain);
  }
}
