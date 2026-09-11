import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/utils/dates.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/weekday.dart';
import '../data/activity_repository.dart';
import '../../../shared/widgets/app_card.dart';

// Grid geometry. One column per week, one row per weekday.
//
// The squares are sized to be tappable rather than just visible: at the old
// 12px a fingertip covered most of a month, and picking one day out of the
// grid was a matter of luck. 18px with a 4px gap puts the touch target close to
// the 48px minimum once the gap either side is counted, and makes the shade
// steps easier to tell apart at arm's length.
const _cell = 18.0;
const _gap = 4.0;
const _step = _cell + _gap;
const _monthLabelHeight = 20.0;
const _gridHeight = _monthLabelHeight + 7 * _step;

/// Font size for the month and weekday labels.
const _labelFontSize = 11.0;

/// Identifies the painted grid.
///
/// Public so a widget test can aim a tap at a specific square: the grid is one
/// render object with no child widgets to find, and Material scatters enough
/// other [CustomPaint]s around that picking it out by type is guesswork.
const activityGridKey = Key('activity-grid');

/// Full width of the painted grid — a year of week columns.
const activityGridWidth = activityWeeks * _step;

/// The centre of the square for [week] and [weekdayRow], in grid coordinates.
///
/// Shared with the tests so they aim at squares the same way the tap handler
/// reads them — a test with its own copy of this arithmetic would keep passing
/// if the geometry changed underneath it.
Offset activityCellCentre({required int week, required int weekdayRow}) {
  return Offset(
    week * _step + _cell / 2,
    _monthLabelHeight + weekdayRow * _step + _cell / 2,
  );
}

/// A GitHub-style year of training, shaded by minutes spent in the gym.
///
/// Rendered by a [CustomPainter] rather than 371 little widgets: it's one
/// render object and one paint pass instead of several hundred to lay out on
/// every scroll frame, which matters on the older Android hardware this app
/// targets. The grid is simple enough — rectangles on a fixed pitch — that the
/// painter stays readable.
class ActivityHeatmap extends ConsumerStatefulWidget {
  const ActivityHeatmap({super.key, this.today});

  /// Overridable so tests don't depend on the day they run.
  final DateTime? today;

  @override
  ConsumerState<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends ConsumerState<ActivityHeatmap> {
  final _scrollController = ScrollController();

  /// The day the user tapped, or null. Shown in the caption — a year of squares
  /// with no way to ask "which day was that?" is a picture, not a record.
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    // Open on today. A year of history scrolled to last January would hide the
    // part anyone actually looks at.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final minutes = ref.watch(activityMinutesProvider).value;

    // Nothing finished yet — the Home tab already tells a new user what to do,
    // and an empty year of grey squares underneath would just be furniture.
    if (minutes == null || minutes.isEmpty) return const SizedBox.shrink();

    final today = dateOnly(widget.today ?? DateTime.now());
    final start = activityGridStart(today);
    final palette = activityPalette(accent, theme.colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text('Activity', style: theme.textTheme.titleMedium),
        ),
        AppCard(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Outside the scroll view so the labels stay put while the
                  // year slides past them.
                  const _WeekdayLabels(),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      child: GestureDetector(
                        onTapUp: (details) =>
                            _selectAt(details.localPosition, start, today),
                        child: CustomPaint(
                          key: activityGridKey,
                          size: const Size(activityGridWidth, _gridHeight),
                          painter: _HeatmapPainter(
                            start: start,
                            today: today,
                            minutes: minutes,
                            palette: palette,
                            selected: _selected,
                            labelColour: theme.colorScheme.onSurfaceVariant,
                            selectionColour: theme.colorScheme.onSurface,
                            textDirection: Directionality.of(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _Caption(
                selected: _selected,
                minutes: minutes,
                palette: palette,
                today: today,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Turns a tap inside the grid into the day it landed on.
  void _selectAt(Offset position, DateTime start, DateTime today) {
    final week = ((position.dx) / _step).floor();
    final weekdayRow = ((position.dy - _monthLabelHeight) / _step).floor();
    if (week < 0 || week >= activityWeeks) return;
    if (weekdayRow < 0 || weekdayRow > 6) return;

    final day = DateTime(
      start.year,
      start.month,
      start.day + week * 7 + weekdayRow,
    );
    // The last column runs past today, and the future isn't tappable.
    if (day.isAfter(today)) return;

    setState(() => _selected = day == _selected ? null : day);
  }
}

/// The five shades, darkest-to-brightest, with "untrained" first.
///
/// Built from the accent so the grid matches the rest of the app rather than
/// being permanently GitHub green.
List<Color> activityPalette(Color accent, ColorScheme scheme) {
  return [
    // Visible but clearly "nothing": an untrained day still needs a square, or
    // the grid loses its shape in a quiet month.
    scheme.onSurface.withValues(alpha: 0.08),
    accent.withValues(alpha: 0.25),
    accent.withValues(alpha: 0.45),
    accent.withValues(alpha: 0.70),
    accent,
  ];
}

class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontSize: _labelFontSize,
    );

    return SizedBox(
      height: _gridHeight,
      child: Column(
        children: [
          const SizedBox(height: _monthLabelHeight),
          // Only Mon/Wed/Fri are named. Seven labels at this size would be a
          // wall of text taller than the thing it describes.
          for (var weekday = 1; weekday <= 7; weekday++)
            SizedBox(
              height: _step,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  weekday.isOdd && weekday <= 5 ? weekdayInitial(weekday) : '',
                  style: style,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Draws the whole grid: month labels along the top, then a square per day.
class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.start,
    required this.today,
    required this.minutes,
    required this.palette,
    required this.selected,
    required this.labelColour,
    required this.selectionColour,
    required this.textDirection,
  });

  final DateTime start;
  final DateTime today;
  final Map<DateTime, int> minutes;
  final List<Color> palette;
  final DateTime? selected;
  final Color labelColour;
  final Color selectionColour;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    var lastMonth = -1;

    for (var week = 0; week < activityWeeks; week++) {
      for (var row = 0; row < 7; row++) {
        final day = DateTime(
          start.year,
          start.month,
          start.day + week * 7 + row,
        );
        // The grid ends on a Sunday, so the final column usually runs a few
        // days into the future. Those squares are left blank rather than drawn
        // as untrained days you failed to use.
        if (day.isAfter(today)) continue;

        final rect = Rect.fromLTWH(
          week * _step,
          _monthLabelHeight + row * _step,
          _cell,
          _cell,
        );
        paint.color = palette[activityLevel(minutes[day] ?? 0)];
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          paint,
        );

        if (selected != null && day == selected) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(6)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = selectionColour,
          );
        }
      }

      // A month label on the first column that belongs to a new month, so the
      // year is readable without counting squares.
      final columnStart = DateTime(
        start.year,
        start.month,
        start.day + week * 7,
      );
      if (columnStart.month != lastMonth) {
        lastMonth = columnStart.month;
        _paintText(
          canvas,
          formatMonthAbbr(columnStart),
          Offset(week * _step, 0),
        );
      }
    }
  }

  void _paintText(Canvas canvas, String text, Offset at) {
    TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(color: labelColour, fontSize: _labelFontSize),
        ),
        textDirection: textDirection,
      )
      ..layout()
      ..paint(canvas, at);
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) {
    return old.minutes != minutes ||
        old.selected != selected ||
        old.today != today ||
        old.palette != palette;
  }
}

/// Under the grid: either the tapped day, or the year's total plus a legend.
class _Caption extends StatelessWidget {
  const _Caption({
    required this.selected,
    required this.minutes,
    required this.palette,
    required this.today,
  });

  final DateTime? selected;

  /// The same "today" the grid was laid out from.
  ///
  /// Passed in rather than read off the clock inside [formatDayLabel]: the grid
  /// draws its last column from the widget's `today`, and a caption that
  /// consulted the real date instead could label that column "Mon 24 Aug" while
  /// the grid treats it as today. Two answers from one screen.
  final DateTime today;
  final Map<DateTime, int> minutes;
  final List<Color> palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    if (selected != null) {
      final trained = minutes[selected] ?? 0;
      return Text(
        trained == 0
            ? '${formatDayLabel(selected!, today: today)} — rest day'
            : '${formatDayLabel(selected!, today: today)} — '
                  '${formatDuration(Duration(minutes: trained))} trained',
        style: style,
      );
    }

    final days = minutes.length;
    final total = minutes.values.fold(0, (sum, m) => sum + m);

    return Row(
      children: [
        Expanded(
          child: Text(
            '${days == 1 ? '1 day' : '$days days'} • '
            '${formatDuration(Duration(minutes: total))} this year',
            style: style,
          ),
        ),
        Text('Less', style: style),
        const SizedBox(width: 4),
        for (final colour in palette)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colour,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        const SizedBox(width: 4),
        Text('More', style: style),
      ],
    );
  }
}
