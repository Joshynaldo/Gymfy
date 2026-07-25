import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/utils/exercise_display.dart';
import '../data/exercise_repository.dart';

/// The Exercises tab: a searchable, filterable list of the whole exercise
/// library, read live from the database.
///
/// Search text and the selected muscle filter are transient view state, so
/// they live here in the widget (a [ConsumerStatefulWidget]); the exercise
/// data itself comes from Riverpod via [exerciseListProvider].
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  String _query = '';
  String? _muscleFilter; // a MuscleId value, or null for "All".

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
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

          // Apply search + muscle filter.
          final query = _query.trim().toLowerCase();
          final filtered = all.where((e) {
            final matchesQuery =
                query.isEmpty || e.name.toLowerCase().contains(query);
            final matchesMuscle =
                _muscleFilter == null || e.muscleIds.contains(_muscleFilter);
            return matchesQuery && matchesMuscle;
          }).toList();

          return Column(
            children: [
              _SearchField(
                onChanged: (value) => setState(() => _query = value),
              ),
              _MuscleFilterBar(
                muscles: muscles,
                selected: _muscleFilter,
                onSelected: (muscle) => setState(() => _muscleFilter = muscle),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No exercises match your filters.'))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) =>
                            _ExerciseTile(exercise: filtered[index]),
                      ),
              ),
            ],
          );
        },
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
          hintText: 'Search exercises',
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

class _MuscleFilterBar extends StatelessWidget {
  const _MuscleFilterBar({
    required this.muscles,
    required this.selected,
    required this.onSelected,
  });

  final List<String> muscles;
  final String? selected;

  /// Called with the chosen muscle id, or null when "All" / a re-tap clears it.
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
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
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final muscle in muscles)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(muscleLabel(muscle)),
                selected: selected == muscle,
                onSelected: (isSelected) =>
                    onSelected(isSelected ? muscle : null),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExerciseTile extends ConsumerWidget {
  const _ExerciseTile({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    final category = exercise.category;
    final muscleIds = exercise.muscleIds;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: accent.withValues(alpha: 0.15),
        child: Icon(categoryIcon(category), color: accent),
      ),
      title: Text(exercise.name),
      subtitle: Text(
        '${category.label} • ${muscleIds.map(muscleLabel).join(', ')}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go('/exercises/${exercise.id}'),
    );
  }
}
