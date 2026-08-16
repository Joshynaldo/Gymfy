import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/utils/exercise_display.dart';
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
          final muscles = <String>{for (final e in all) ...e.muscleIds}.toList()
            ..sort();

          final filtered = all.where(_matches).toList();

          return Column(
            children: [
              _SearchField(
                onChanged: (value) => setState(() => _query = value),
              ),
              _MuscleFilterBar(
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

  /// Whether an exercise survives the search box and the muscle chips.
  ///
  /// The two combine with AND (a search *within* a filtered set), but several
  /// muscle chips combine with OR: picking Chest and Triceps asks for "anything
  /// that trains either", which is how you build a push day. Requiring both
  /// would answer a question almost nobody has, and would usually return
  /// nothing.
  bool _matches(Exercise exercise) {
    final query = _query.trim().toLowerCase();
    final matchesQuery =
        query.isEmpty ||
        exercise.name.toLowerCase().contains(query) ||
        // Searching by muscle: "delt" finds the lateral raise even though the
        // word never appears in its name.
        exercise.muscleIds.any(
          (muscleId) => muscleLabel(muscleId).toLowerCase().contains(query),
        );

    final matchesMuscle =
        _muscleFilters.isEmpty ||
        exercise.muscleIds.any(_muscleFilters.contains);

    return matchesQuery && matchesMuscle;
  }

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
      SnackBar(content: Text(_addedMessage(added: added, asked: ids.length))),
    );
  }

  /// Says what actually happened, since exercises already in the day are
  /// skipped and a plain "4 added" would sometimes be a lie.
  String _addedMessage({required int added, required int asked}) {
    if (added == 0) {
      return asked == 1
          ? 'Already in that day'
          : 'All $asked were already in that day';
    }
    final addedText = added == 1 ? '1 exercise added' : '$added exercises added';
    final skipped = asked - added;
    return skipped == 0 ? addedText : '$addedText — $skipped already there';
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

/// The horizontal row of muscle filter chips.
///
/// Several can be on at once; the selected ones are pulled to the front so a
/// choice made after scrolling right doesn't disappear off-screen when you
/// scroll back.
class _MuscleFilterBar extends StatelessWidget {
  const _MuscleFilterBar({
    required this.muscles,
    required this.selected,
    required this.onToggle,
    required this.onClear,
  });

  final List<String> muscles;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ordered = [
      ...muscles.where(selected.contains),
      ...muscles.where((m) => !selected.contains(m)),
    ];

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: const Text('All'),
              selected: selected.isEmpty,
              // Already showing everything, so this would be a no-op tap. A
              // disabled chip says "you're here" better than one that does
              // nothing when pressed.
              onSelected: selected.isEmpty ? null : (_) => onClear(),
            ),
          ),
          for (final muscle in ordered)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(muscleLabel(muscle)),
                selected: selected.contains(muscle),
                onSelected: (_) => onToggle(muscle),
              ),
            ),
        ],
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
