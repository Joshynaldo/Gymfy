import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/accent_color.dart';
import '../../../../shared/utils/weekday.dart';

/// Seven toggles, Monday to Sunday, for putting a workout day on the calendar.
///
/// Laid out as a fixed row rather than wrapping chips: the week always has the
/// same seven slots in the same order, so a stable grid is easier to read at a
/// glance than a reflowing list — you learn where Thursday sits and stop
/// reading the labels.
class WeekdayPicker extends ConsumerWidget {
  const WeekdayPicker({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  /// ISO weekdays currently assigned to this day.
  final List<int> selected;

  /// Called with the weekday that was tapped, on or off.
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);

    return Row(
      children: [
        for (final weekday in weekdays)
          Expanded(
            child: _WeekdayToggle(
              weekday: weekday,
              selected: selected.contains(weekday),
              accent: accent,
              onTap: () => onToggle(weekday),
            ),
          ),
      ],
    );
  }
}

class _WeekdayToggle extends StatelessWidget {
  const _WeekdayToggle({
    required this.weekday,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final int weekday;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: weekdayName(weekday),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? accent
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              weekdayInitial(weekday),
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
