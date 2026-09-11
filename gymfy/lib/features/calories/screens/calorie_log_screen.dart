import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/utils/dates.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../data/calorie_repository.dart';
import '../widgets/macro_breakdown.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';
import '../../../shared/widgets/glass_dialog.dart';

/// A record returned by the add-meal dialog.
typedef _MealInput = ({
  String name,
  int calories,
  int protein,
  int carbs,
  int fat,
});

/// The daily calorie log: pick a day, see total calories vs. goal and macro
/// totals, and add or remove meals.
class CalorieLogScreen extends ConsumerStatefulWidget {
  const CalorieLogScreen({super.key});

  @override
  ConsumerState<CalorieLogScreen> createState() => _CalorieLogScreenState();
}

class _CalorieLogScreenState extends ConsumerState<CalorieLogScreen> {
  late DateTime _day = dateOnly(DateTime.now());

  void _shiftDay(int deltaDays) {
    setState(() => _day = _day.add(Duration(days: deltaDays)));
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(calorieEntriesForDayProvider(_day));

    return GlassScaffold(
      appBar: GlassAppBar(title: const Text('Calorie log')),
      // The day stepper is fixed, so it is held clear of the app bar; only the
      // list below it slides under the bars.
      body: (context) => Padding(
        padding: topBarInset(context),
        child: Column(
          children: [
            _DayNavigator(
              day: _day,
              onPrevious: () => _shiftDay(-1),
              // Don't let the user page into the future.
              onNext: _day.isBefore(dateOnly(DateTime.now()))
                  ? () => _shiftDay(1)
                  : null,
            ),
            Expanded(
              child: entriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load the log.\n$error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (entries) => _DayContent(entries: entries),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMeal,
        icon: const Icon(Icons.add),
        label: const Text('Add meal'),
      ),
    );
  }

  Future<void> _addMeal() async {
    final meal = await showDialog<_MealInput>(
      context: context,
      builder: (context) => const _AddMealDialog(),
    );
    if (meal == null) return;

    await ref
        .read(calorieRepositoryProvider)
        .addEntry(
          day: _day,
          name: meal.name,
          calories: meal.calories,
          protein: meal.protein,
          carbs: meal.carbs,
          fat: meal.fat,
        );
  }
}

class _DayNavigator extends StatelessWidget {
  const _DayNavigator({
    required this.day,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime day;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
            tooltip: 'Previous day',
          ),
          Text(formatDayLabel(day), style: theme.textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
            tooltip: 'Next day',
          ),
        ],
      ),
    );
  }
}

class _DayContent extends StatelessWidget {
  const _DayContent({required this.entries});

  final List<CalorieEntry> entries;

  @override
  Widget build(BuildContext context) {
    final totalCalories = entries.fold<int>(0, (s, e) => s + e.calories);
    final protein = entries.fold<int>(0, (s, e) => s + e.protein);
    final carbs = entries.fold<int>(0, (s, e) => s + e.carbs);
    final fat = entries.fold<int>(0, (s, e) => s + e.fat);

    return ListView(
      // The list itself carries no horizontal padding any more: cards bring
      // their own margin, so the meals line up with the cards on every other
      // tab instead of sitting inset by a further 16.
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 96) + bottomBarInset(context),
      children: [
        _CalorieSummary(total: totalCalories, goal: defaultCalorieGoal),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: MacroBreakdown(protein: protein, carbs: carbs, fat: fat),
        ),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Center(child: Text('No meals logged for this day yet.')),
          )
        else ...[
          AppSectionHeader(title: 'Meals', count: entries.length),
          for (final entry in entries)
            FadeSlideIn(child: _MealTile(entry: entry)),
        ],
      ],
    );
  }
}

class _CalorieSummary extends ConsumerWidget {
  const _CalorieSummary({required this.total, required this.goal});

  final int total;
  final int goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final remaining = goal - total;
    final progress = goal <= 0 ? 0.0 : (total / goal).clamp(0.0, 1.0);

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$total',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ $goal kcal',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                remaining >= 0 ? '$remaining left' : '${-remaining} over',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: remaining >= 0 ? accent : theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: accent.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealTile extends ConsumerWidget {
  const _MealTile({required this.entry});

  final CalorieEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AppTile(
      icon: Icons.restaurant,
      title: entry.name,
      subtitle: 'P ${entry.protein}g • C ${entry.carbs}g • F ${entry.fat}g',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The calorie figure is why the row exists, so it is weighted rather
          // than left the same size as the macros underneath it.
          Text(
            '${entry.calories}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            'kcal',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete entry',
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                ref.read(calorieRepositoryProvider).deleteEntry(entry.id),
          ),
        ],
      ),
    );
  }
}

/// Dialog to enter a meal's name, calories and macros. Owns its controllers via
/// a [StatefulWidget] so they're disposed at the right time.
class _AddMealDialog extends StatefulWidget {
  const _AddMealDialog();

  @override
  State<_AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<_AddMealDialog> {
  final _name = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  int _int(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return; // name is required
    Navigator.of(context).pop((
      name: name,
      calories: _int(_calories),
      protein: _int(_protein),
      carbs: _int(_carbs),
      fat: _int(_fat),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      title: const Text('Add meal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Meal',
                hintText: 'e.g. Chicken & rice',
              ),
            ),
            const SizedBox(height: 8),
            _NumberField(controller: _calories, label: 'Calories (kcal)'),
            Row(
              children: [
                Expanded(
                  child: _NumberField(controller: _protein, label: 'Protein g'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(controller: _carbs, label: 'Carbs g'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(controller: _fat, label: 'Fat g'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
    );
  }
}
