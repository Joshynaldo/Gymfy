import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n.dart';
import '../../../workout/data/workout_repository.dart';

/// Asks which workout day some exercises should be added to, and returns the
/// chosen day's id (or null if the sheet was dismissed).
///
/// Every day in every split is shown in one flat list rather than making the
/// user pick a split and then a day. Most people have one or two splits, so a
/// drill-down would be two taps to answer a question they could have answered
/// in one.
Future<int?> showAddToDaySheet(BuildContext context, {required int count}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AddToDaySheet(count: count),
  );
}

class _AddToDaySheet extends ConsumerWidget {
  const _AddToDaySheet({required this.count});

  /// How many exercises are being added — shown in the title so the sheet
  /// confirms what's about to happen.
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final daysAsync = ref.watch(allDaysProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                context.l10n.exercisesAddToDayTitle(count),
                style: theme.textTheme.titleLarge,
              ),
            ),
            Flexible(
              child: daysAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(context.l10n.workoutSplitsLoadFailed('$error')),
                ),
                data: (days) =>
                    days.isEmpty ? const _NoDays() : _DayList(days: days),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({required this.days});

  final List<SplitDay> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final entry = days[index];
        // A split heading before the first day of each split, so repeated day
        // names ("Push" in two different splits) stay tellable apart.
        final isFirstOfSplit =
            index == 0 || days[index - 1].split.id != entry.split.id;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isFirstOfSplit)
              Padding(
                padding: EdgeInsets.fromLTRB(16, index == 0 ? 8 : 20, 16, 4),
                child: Text(
                  entry.split.name,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ListTile(
              title: Text(entry.day.name),
              onTap: () => Navigator.of(context).pop(entry.day.id),
            ),
          ],
        );
      },
    );
  }
}

/// Nothing to add to yet. Says what's missing rather than showing an empty
/// list, which would read as a bug.
class _NoDays extends StatelessWidget {
  const _NoDays();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.calendar,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.exercisesNoDaysTitle,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.exercisesNoDaysMessage,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
