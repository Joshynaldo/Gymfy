import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/accent_color.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/utils/weekday.dart';
import '../../workout/data/workout_repository.dart';
import '../../../shared/widgets/app_card.dart';

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

    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accent.withValues(alpha: 0.15),
          child: Icon(LucideIcons.calendar, color: accent),
        ),
        title: Text(next.day.name),
        subtitle: Text(
          relativeDayLabel(next.daysAway, next.weekday, l10n: context.l10n),
        ),
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
///
/// In [l10n]'s language when given, English otherwise.
String relativeDayLabel(int daysAway, int weekday, {AppLocalizations? l10n}) {
  final strings = l10n ?? englishLocalizations;
  final name = weekdayName(weekday, l10n: l10n);
  return switch (daysAway) {
    1 => strings.homeNextUpTomorrow,
    <= 6 => name,
    // Exactly a week out: the same weekday as today, so naming it would read
    // as "today" at a glance.
    _ => strings.homeNextUpNextWeekday(name),
  };
}
