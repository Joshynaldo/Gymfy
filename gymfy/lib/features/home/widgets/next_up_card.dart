import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/utils/weekday.dart';
import '../../workout/data/workout_repository.dart';

/// What's coming after today.
///
/// Renders nothing at all when nothing is scheduled — the today card already
/// explains that case, and a second empty card saying the same thing would be
/// noise.
class NextUpCard extends ConsumerWidget {
  const NextUpCard({super.key, this.today});

  final DateTime? today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final weekday = (today ?? DateTime.now()).weekday;
    final next = ref.watch(nextDayProvider(weekday)).value;

    if (next == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accent.withValues(alpha: 0.15),
          child: Icon(Icons.event_outlined, color: accent),
        ),
        title: Text(next.day.name),
        subtitle: Text(relativeDayLabel(next.daysAway, next.weekday)),
        titleTextStyle: theme.textTheme.titleMedium,
      ),
    );
  }
}

/// Turns "3 days away, a Thursday" into wording a person would use.
///
/// Named days for the near future and the weekday beyond that: "in 4 days" is
/// arithmetic the reader has to do, while "Thursday" is the answer. Past a week
/// the weekday alone becomes ambiguous, so the count comes back.
String relativeDayLabel(int daysAway, int weekday) => switch (daysAway) {
  1 => 'Tomorrow',
  <= 6 => weekdayName(weekday),
  // Exactly a week out: the same weekday as today, so naming it would read as
  // "today" at a glance.
  _ => 'Next ${weekdayName(weekday)}',
};
