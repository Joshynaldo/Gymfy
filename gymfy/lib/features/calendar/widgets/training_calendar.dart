import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/accent_color.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/data/week_start.dart';
import '../../../shared/utils/dates.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/weekday.dart';
import '../../../shared/widgets/app_card.dart';
import '../../workout/data/session_repository.dart';
import '../data/calendar_month.dart';
import '../data/calendar_repository.dart';

/// Height of one day cell. Wide enough apart for a thumb; the width is
/// whatever a seventh of the card is, which on a 320-point phone is still
/// over 36.
const _cellHeight = 40.0;

/// A month of training on a calendar, beside the year grid.
///
/// The grid answers "how has the year gone"; this answers "what did I do on
/// the 14th". Days with a finished workout are marked in the accent, and
/// tapping one lists its workouts underneath, each opening its summary.
///
/// Hidden until the first workout is finished, like the year grid: a blank
/// month of numbers says nothing a new user needs to hear.
class TrainingCalendar extends ConsumerStatefulWidget {
  const TrainingCalendar({super.key, this.today});

  /// Overridable so tests don't depend on the day they run.
  final DateTime? today;

  @override
  ConsumerState<TrainingCalendar> createState() => _TrainingCalendarState();
}

class _TrainingCalendarState extends ConsumerState<TrainingCalendar> {
  late DateTime _month = monthOf(_today);

  /// The day tapped, or null. Shown under the grid.
  DateTime? _selected;

  DateTime get _today => dateOnly(widget.today ?? DateTime.now());

  @override
  Widget build(BuildContext context) {
    if (ref.watch(lastCompletedSessionProvider).value == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = context.l10n;
    final sessions = ref.watch(calendarMonthProvider(_month)).value;
    final byDay = <DateTime, List<CalendarSession>>{};
    for (final session in sessions ?? const <CalendarSession>[]) {
      byDay.putIfAbsent(session.day, () => []).add(session);
    }
    final atCurrentMonth = _month == monthOf(_today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(l10n.calendarTitle, style: theme.textTheme.titleMedium),
        ),
        AppCard(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: l10n.calendarPreviousMonth,
                    icon: const Icon(LucideIcons.chevronLeft),
                    onPressed: () => _moveMonth(-1),
                  ),
                  Expanded(
                    child: Text(
                      formatMonthYear(_month, l10n: l10n),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.calendarNextMonth,
                    icon: const Icon(LucideIcons.chevronRight),
                    // The future has nothing in it to look at.
                    onPressed: atCurrentMonth ? null : () => _moveMonth(1),
                  ),
                ],
              ),
              _MonthGrid(
                month: _month,
                today: _today,
                selected: _selected,
                trained: byDay.keys.toSet(),
                onTap: (day) =>
                    setState(() => _selected = day == _selected ? null : day),
              ),
              if (_selected != null) ...[
                const SizedBox(height: 8),
                _DayList(
                  day: _selected!,
                  today: _today,
                  sessions: byDay[_selected] ?? const [],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _moveMonth(int by) {
    setState(() {
      _month = DateTime(_month.year, _month.month + by);
      _selected = null;
    });
  }
}

class _MonthGrid extends ConsumerWidget {
  const _MonthGrid({
    required this.month,
    required this.today,
    required this.selected,
    required this.trained,
    required this.onTap,
  });

  final DateTime month;
  final DateTime today;
  final DateTime? selected;
  final Set<DateTime> trained;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final firstWeekday = ref.watch(firstWeekdayProvider);
    final cells = monthGrid(month, firstWeekday);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      children: [
        Row(
          children: [
            for (final weekday in weekdaysFrom(firstWeekday))
              Expanded(
                child: Center(
                  child: Text(
                    weekdayInitial(weekday, l10n: context.l10n),
                    style: labelStyle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var row = 0; row < cells.length ~/ 7; row++)
          Row(
            children: [
              for (final day in cells.sublist(row * 7, row * 7 + 7))
                Expanded(
                  child: day == null
                      ? const SizedBox(height: _cellHeight)
                      : _DayCell(
                          day: day,
                          trained: trained.contains(day),
                          isToday: day == today,
                          selected: day == selected,
                          future: day.isAfter(today),
                          accent: accent,
                          onTap: () => onTap(day),
                        ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.trained,
    required this.isToday,
    required this.selected,
    required this.future,
    required this.accent,
    required this.onTap,
  });

  final DateTime day;
  final bool trained;
  final bool isToday;
  final bool selected;
  final bool future;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final date = formatDate(day, l10n: l10n);
    final ink = trained
        ? Colors.white
        : future
        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45)
        : theme.colorScheme.onSurface;

    return Semantics(
      button: !future,
      selected: selected,
      label: trained ? l10n.calendarDayTrainedSemantics(date) : date,
      excludeSemantics: true,
      child: InkResponse(
        onTap: future ? null : onTap,
        radius: _cellHeight / 2,
        child: SizedBox(
          height: _cellHeight,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: trained ? accent : Colors.transparent,
                // Today is ringed, the tapped day ringed harder: two
                // different questions — where am I, what am I looking at.
                border: selected
                    ? Border.all(color: theme.colorScheme.onSurface, width: 2)
                    : isToday
                    ? Border.all(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ink,
                  fontWeight: trained || isToday
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The workouts on the tapped day, each opening its summary.
class _DayList extends StatelessWidget {
  const _DayList({
    required this.day,
    required this.today,
    required this.sessions,
  });

  final DateTime day;
  final DateTime today;
  final List<CalendarSession> sessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final label = formatDayLabel(day, today: today, l10n: l10n);

    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
        child: Text(
          l10n.calendarRestDay(label),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final session in sessions)
          // A plain row rather than an AppTile: this already sits inside the
          // calendar's card, and a card per workout inside it would be panes
          // stacked on panes.
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: Icon(
              session.free ? LucideIcons.zap : LucideIcons.dumbbell,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(
              session.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              [
                _time(session.finishedAt),
                if (session.length != null) formatDuration(session.length!),
                l10n.calendarDaySets(session.sets),
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(LucideIcons.chevronRight, size: 20),
            // Within the Progress tab, so back returns here rather than
            // dropping you on the Workout tab.
            onTap: () => context.go('/progress/session/${session.id}'),
          ),
      ],
    );
  }
}

/// "18:05" — when a workout finished.
String _time(DateTime moment) =>
    '${moment.hour.toString().padLeft(2, '0')}:'
    '${moment.minute.toString().padLeft(2, '0')}';
