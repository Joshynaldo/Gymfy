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
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/exercise_thumbnail.dart';
import '../data/exercise_repository.dart';
import '../data/muscle_groups.dart';
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
                    ? const _NoMatches()
                    : _CategorisedList(
                        rows: _rowsFor(filtered),
                        selected: _selected,
                        selecting: _selecting,
                        onToggle: _toggle,
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

  /// Flattens the categorised exercises into one list of rows.
  ///
  /// Flat so the list can stay lazy — only what's on screen is built, which is
  /// what keeps scrolling smooth on older hardware with seventy-eight of them.
  List<_Row> _rowsFor(List<Exercise> exercises) {
    return [
      for (final entry in groupExercises(
        exercises,
        (e) => e.muscleIds,
      ).entries) ...[
        _HeaderRow(group: entry.key, count: entry.value.length),
        for (final exercise in entry.value) _ExerciseRow(exercise: exercise),
      ],
    ];
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

/// The search box: rounded, filled, and clearable.
class _SearchField extends StatefulWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        onChanged: (value) {
          widget.onChanged(value);
          // Only to swap the clear button in and out — the query itself lives
          // on the screen above.
          setState(() {});
        },
        decoration: InputDecoration(
          // Names the second thing it searches, which is otherwise invisible:
          // "chest" finding the bench press looks like magic or a bug.
          hintText: 'Search by name or muscle',
          prefixIcon: const Icon(Icons.search, size: 20),
          // Absent until there's something to clear, so the field stays quiet
          // while you're only reading.
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Clear search',
                  onPressed: _clear,
                ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHigh,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            // A pill rather than a rounded rectangle — it reads as a search
            // field on sight, before the magnifier is even noticed.
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/// One entry in the flattened list: either a category heading or an exercise.
sealed class _Row {
  const _Row();
}

class _HeaderRow extends _Row {
  const _HeaderRow({required this.group, required this.count});

  final MuscleGroup group;
  final int count;
}

class _ExerciseRow extends _Row {
  const _ExerciseRow({required this.exercise});

  final Exercise exercise;
}

/// The library: cards under plain category headings.
class _CategorisedList extends StatelessWidget {
  const _CategorisedList({
    required this.rows,
    required this.selected,
    required this.selecting,
    required this.onToggle,
  });

  final List<_Row> rows;
  final Set<String> selected;
  final bool selecting;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Room to scroll the last card clear of the FAB.
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return FadeSlideIn(
          child: switch (row) {
            _HeaderRow() => AppSectionHeader(
              title: row.group.label,
              count: row.count,
            ),
            _ExerciseRow() => AppTile(
              icon: exerciseIcon,
              // A still of the movement rather than the same dumbbell symbol
              // seventy-eight times. Recognising a lift by its shape is faster
              // than reading its name, which is the whole job of this list.
              leading: ExerciseThumbnail(
                gifPath: row.exercise.gifPath,
                selected: selected.contains(row.exercise.id),
              ),
              title: row.exercise.name,
              subtitle: row.exercise.muscleIds.map(muscleLabel).join(' · '),
              titleTrailing: row.exercise.isCustom
                  ? const _CustomBadge()
                  : null,
              selected: selected.contains(row.exercise.id),
              // Long-press starts a selection; once one is running, a plain tap
              // toggles instead of navigating. Keeping tap as "open" until then
              // means browsing never costs an extra step.
              onTap: selecting
                  ? () => onToggle(row.exercise.id)
                  : () => context.go('/exercises/${row.exercise.id}'),
              onLongPress: selecting ? null : () => onToggle(row.exercise.id),
            ),
          },
        );
      },
    );
  }
}

/// Shown when the search and filters between them match nothing.
class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text('Nothing matches', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Try a different word, or clear a muscle filter.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small "Custom" pill. Deliberately quiet — it labels a row, it isn't a
/// call to action.
class _CustomBadge extends ConsumerWidget {
  const _CustomBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);

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
