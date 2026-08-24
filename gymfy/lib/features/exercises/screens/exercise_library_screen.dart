import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/utils/exercise_display.dart';
import '../../../shared/utils/exercise_search.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/muscle_filter_bar.dart';
import '../../workout/data/workout_repository.dart';
import '../data/exercise_repository.dart';
import 'widgets/add_to_day_sheet.dart';

/// The Exercises tab: a searchable, filterable list of the whole exercise
/// library, read live from the database.
///
/// Search text, the selected muscle filter, and the current selection are
/// transient view state, so they live here in the widget (a
/// [ConsumerStatefulWidget]); the exercise data itself comes from Riverpod via
/// [exerciseListProvider].
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  String _query = '';

  /// The muscles being filtered on. Empty means "All".
  final _muscleFilters = <String>{};

  /// Exercise ids picked for a bulk "add to day".
  ///
  /// Ids rather than rows, so a selection survives the list re-sorting or an
  /// exercise being renamed underneath it. Empty means normal browsing mode —
  /// there's no separate "am I selecting?" flag to keep in sync.
  final _selected = <String>{};

  bool get _selecting => _selected.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseListProvider);

    return Scaffold(
      appBar: _selecting
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(_selected.clear),
                tooltip: 'Cancel selection',
              ),
              title: Text('${_selected.length} selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.playlist_add),
                  onPressed: _addSelectedToDay,
                  tooltip: 'Add to day',
                ),
              ],
            )
          : AppBar(title: const Text('Exercises')),
      body: exercisesAsync.when(
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
          // Muscles that actually appear in the data, for the filter chips.
          final muscles = musclesIn(all);

          final filtered = all.where(_matches).toList();

          return Column(
            children: [
              _SearchField(
                onChanged: (value) => setState(() => _query = value),
              ),
              MuscleFilterBar(
                muscles: muscles,
                selected: _muscleFilters,
                onToggle: _toggleMuscle,
                onClear: () => setState(_muscleFilters.clear),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No exercises match your filters.'))
                    : ListView.separated(
                        // Room to scroll the last tile clear of the FAB.
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final exercise = filtered[index];
                          return _ExerciseTile(
                            exercise: exercise,
                            selected: _selected.contains(exercise.id),
                            selecting: _selecting,
                            onToggle: () => _toggle(exercise.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      // Hidden while selecting: the app bar owns the actions then, and a FAB
      // for an unrelated action would just be in the way.
      floatingActionButton: _selecting
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.go('/exercises/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add exercise'),
            ),
    );
  }

  void _toggleMuscle(String muscleId) {
    setState(() {
      if (!_muscleFilters.remove(muscleId)) _muscleFilters.add(muscleId);
    });
  }

  /// Whether an exercise survives the search box and the muscle chips. The
  /// rules live in `shared/utils/exercise_search.dart` so the exercise picker
  /// filters identically.
  bool _matches(Exercise exercise) => matchesExerciseSearch(
    exercise,
    query: _query,
    muscleFilters: _muscleFilters,
  );

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  Future<void> _addSelectedToDay() async {
    final ids = _selected.toList();
    final dayId = await showAddToDaySheet(context, count: ids.length);
    if (dayId == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final added = await ref
        .read(workoutRepositoryProvider)
        .addExercisesToDay(dayId, ids);

    setState(_selected.clear);
    messenger.showSnackBar(
      SnackBar(
        content: Text(addedToDayMessage(added: added, asked: ids.length)),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          // Names the second thing it searches, which is otherwise invisible:
          // "chest" finding the bench press looks like magic or a bug.
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
    );
  }
}

class _ExerciseTile extends ConsumerWidget {
  const _ExerciseTile({
    required this.exercise,
    required this.selected,
    required this.selecting,
    required this.onToggle,
  });

  final Exercise exercise;
  final bool selected;

  /// Whether the screen is in selection mode. Changes what a plain tap does, so
  /// the tile needs to know even when it isn't itself selected.
  final bool selecting;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    final muscleIds = exercise.muscleIds;

    return ListTile(
      selected: selected,
      selectedTileColor: accent.withValues(alpha: 0.08),
      leading: CircleAvatar(
        backgroundColor: selected
            ? accent
            : accent.withValues(alpha: 0.15),
        child: Icon(
          selected ? Icons.check : exerciseIcon,
          color: selected ? Colors.white : accent,
        ),
      ),
      title: Row(
        children: [
          Flexible(child: Text(exercise.name, overflow: TextOverflow.ellipsis)),
          // Marks the rows that can be edited or deleted, so it's never a
          // surprise that the built-in ones can't be.
          if (exercise.isCustom) ...[
            const SizedBox(width: 8),
            _CustomBadge(accent: accent),
          ],
        ],
      ),
      subtitle: Text(
        muscleIds.map(muscleLabel).join(', '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: selecting ? null : const Icon(Icons.chevron_right),
      // Long-press starts a selection; once one is running, a plain tap toggles
      // instead of navigating. Keeping tap as "open" until then means the
      // common case — browsing — never costs an extra step.
      onTap: selecting ? onToggle : () => context.go('/exercises/${exercise.id}'),
      onLongPress: selecting ? null : onToggle,
    );
  }
}

/// A small "Custom" pill. Deliberately quiet — it labels a row, it isn't a
/// call to action.
class _CustomBadge extends StatelessWidget {
  const _CustomBadge({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Custom',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: accent),
      ),
    );
  }
}
