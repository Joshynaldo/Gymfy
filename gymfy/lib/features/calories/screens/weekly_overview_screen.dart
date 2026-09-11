import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/format.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/bar_chart.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../data/calorie_repository.dart';
import '../data/weekly_overview_repository.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';

/// The weekly overview: the last seven days of calories against the daily goal.
class WeeklyOverviewScreen extends ConsumerWidget {
  const WeeklyOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekAsync = ref.watch(weeklyOverviewProvider);

    return GlassScaffold(
      appBar: GlassAppBar(title: const Text('This week')),
      body: weekAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load the week.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (week) => FadeSlideIn(
          child: ListView(
            padding:
                const EdgeInsets.fromLTRB(16, 8, 16, 24) + barInsets(context),
            children: [_CaloriesSection(week: week)],
          ),
        ),
      ),
    );
  }
}

class _CaloriesSection extends StatelessWidget {
  const _CaloriesSection({required this.week});

  final List<DaySummary> week;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const goal = defaultCalorieGoal;
    final logged = week.where((d) => d.calories > 0).toList();
    final average = logged.isEmpty
        ? 0
        : (logged.fold<int>(0, (s, d) => s + d.calories) / logged.length)
              .round();
    final onTarget = logged.where((d) => d.calories <= goal).length;

    // Leave headroom above whichever is higher: the goal line or the biggest day.
    final peak = week.fold<int>(
      goal,
      (m, d) => d.calories > m ? d.calories : m,
    );

    return AppPanel(
      icon: Icons.local_fire_department_outlined,
      title: 'Calories',
      // Days with nothing logged show no bar rather than a misleading zero.
      subtitle: logged.isEmpty
          ? 'Nothing logged in the last 7 days.'
          : '$average kcal average • $onTarget of ${logged.length} '
                'logged ${logged.length == 1 ? 'day' : 'days'} within goal',
      // The headline number belongs in the heading row, not buried in the
      // sentence under it: it is the one figure you opened this screen for.
      trailing: logged.isEmpty
          ? null
          : Text(
              '$average',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: SimpleBarChart(
              labels: [for (final d in week) formatWeekdayAbbr(d.day)],
              values: [
                for (final d in week)
                  d.calories == 0 ? null : d.calories.toDouble(),
              ],
              maxY: peak * 1.15,
              goal: goal.toDouble(),
              overGoalIsBad: true,
              yLabel: (value) => value.round().toString(),
              tooltip: (i) =>
                  '${week[i].calories} kcal\n${formatDayLabel(week[i].day)}',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Dashed line = daily goal ($goal kcal)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
