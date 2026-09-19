import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/accent_color.dart';
import '../../../../shared/database/app_database.dart';
import '../../../../shared/utils/exercise_display.dart';
import '../../../../shared/utils/exercise_search.dart';
import '../../../../shared/widgets/exercise_thumbnail.dart';
import '../../../../shared/models/equipment.dart';
import '../../../../shared/widgets/muscle_filter_bar.dart';
import '../../../exercises/widgets/equipment_filter_sheet.dart';
import '../../../exercises/data/exercise_repository.dart';

/// Opens a bottom sheet over the exercise library and returns the ids of every
/// exercise the user picked, or null if they dismissed it without confirming.
///
/// Multi-select rather than one-at-a-time: building a day means adding five or
/// six exercises, and re-opening the sheet for each one made the common case the
/// slowest path. An empty list is never returned — nothing picked means the
/// confirm button is disabled, so "null" and "nothing" stay the same answer.
Future<List<String>?> showExercisePicker(BuildContext context) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _ExercisePickerSheet(),
  );
}

class _ExercisePickerSheet extends ConsumerStatefulWidget {
  const _ExercisePickerSheet();

  @override
  ConsumerState<_ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  String _query = '';

  /// The muscles being filtered on. Empty means "All".
  final _muscleFilters = <String>{};

  /// The equipment being filtered on. Empty means "All".
  final _equipmentFilters = <Equipment>{};

  /// Ids picked so far. Ids rather than rows, so a selection survives the list
  /// re-filtering underneath it — narrowing the search does not silently drop
  /// what you already ticked.
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseListProvider);

    // Take up most of the screen so the list is comfortable to scroll, and sit
    // above the keyboard when the search field is focused.
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add exercises',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (_selected.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(_selected.clear),
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  // Names the second thing it searches, which is otherwise
                  // invisible: "chest" finding the bench press looks like magic
                  // or a bug.
                  hintText: 'Search by name or muscle',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: exercisesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load exercises.\n$error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (all) {
                  final filtered = all
                      .where(
                        (e) => matchesExerciseSearch(
                          e,
                          query: _query,
                          muscleFilters: _muscleFilters,
                          equipmentFilters: _equipmentFilters,
                        ),
                      )
                      .toList();

                  // The same faceting as the library: each bar offers what
                  // survives the *other* filters, so nothing on screen leads
                  // to an empty list.
                  final options = filterOptionsFor(
                    all,
                    query: _query,
                    muscleFilters: _muscleFilters,
                    equipmentFilters: _equipmentFilters,
                  );

                  return Column(
                    children: [
                      MuscleFilterBar(
                        muscles: options.muscles,
                        selected: _muscleFilters,
                        onToggle: _toggleMuscle,
                        onClear: () => setState(_muscleFilters.clear),
                        leading: options.equipment.length > 1
                            ? EquipmentFilterButton(
                                count: _equipmentFilters.length,
                                onPressed: () => showEquipmentFilterSheet(
                                  context: context,
                                  available: options.equipment,
                                  selected: _equipmentFilters,
                                  onToggle: _toggleEquipment,
                                  onClear: () =>
                                      setState(_equipmentFilters.clear),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text('No exercises match your filters.'),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final exercise = filtered[index];
                                  return _PickerTile(
                                    exercise: exercise,
                                    selected: _selected.contains(exercise.id),
                                    onToggle: () => _toggle(exercise.id),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
            _ConfirmBar(
              count: _selected.length,
              // Disabled rather than hidden while nothing is picked: a button
              // that appears out of nowhere is easy to miss, and the sheet's
              // height shouldn't jump on the first tap.
              onConfirm: _selected.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_selected.toList()),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleMuscle(String muscleId) {
    setState(() {
      if (!_muscleFilters.remove(muscleId)) _muscleFilters.add(muscleId);
    });
  }

  void _toggleEquipment(Equipment equipment) {
    setState(() {
      if (!_equipmentFilters.remove(equipment)) {
        _equipmentFilters.add(equipment);
      }
    });
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }
}

/// One row in the picker: a checkbox, the exercise name, and its muscles.
class _PickerTile extends ConsumerWidget {
  const _PickerTile({
    required this.exercise,
    required this.selected,
    required this.onToggle,
  });

  final Exercise exercise;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);

    return ListTile(
      selected: selected,
      selectedTileColor: accent.withValues(alpha: 0.08),
      // A still of the movement rather than the same symbol on every row. This
      // is the screen where it earns the most: you are scanning a long list
      // for a lift you have in mind, and a shape is quicker to match than a
      // name. Selection still swaps it for the tick.
      leading: ExerciseThumbnail(gifPath: exercise.gifPath, selected: selected),
      title: Text(exercise.name),
      subtitle: Text(
        exercise.muscleIds.map(muscleLabel).join(', '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // The whole row toggles, not just the checkbox: a 48-pixel target beside
      // a 300-pixel one is the wrong thing to have to aim at on a phone.
      onTap: onToggle,
    );
  }
}

/// The bottom bar of the picker: how many are picked, and the confirm button.
class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({required this.count, required this.onConfirm});

  final int count;

  /// Null disables the button (nothing picked yet).
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                count == 0
                    ? 'Nothing selected'
                    : count == 1
                    ? '1 selected'
                    : '$count selected',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.playlist_add),
              label: Text(count <= 1 ? 'Add' : 'Add $count'),
            ),
          ],
        ),
      ),
    );
  }
}
