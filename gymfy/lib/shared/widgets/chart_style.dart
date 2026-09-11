import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// The look every chart in the app shares.
///
/// Three charts had each grown their own gridline colour, their own axis label
/// style and their own idea of how strongly to shade under a line. None of it
/// was wrong; it just meant the progress chart and the measurement chart were
/// visibly two different charts sitting one screen apart. This is the one
/// answer to "what does a chart look like here".
///
/// Deliberately *not* a glass-theme thing. A chart is data, and the rules that
/// make it readable — a gridline you can ignore, a label that does not jitter,
/// a fill that fades rather than sits — are the same on every palette.

/// A gridline faint enough to read past.
///
/// Dashed rather than solid: a chart's grid exists to be measured against, not
/// looked at, and a broken line recedes behind the data in a way a continuous
/// one never quite does.
FlLine chartGridLine(BuildContext context) => FlLine(
  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
  strokeWidth: 1,
  dashArray: const [4, 6],
);

/// Axis labels, in tabular figures.
///
/// The figures matter more than they look like they should. Proportional digits
/// change width as the numbers tick over, so a y-axis of 100/110/120 sits at
/// three slightly different indents and the whole column looks crooked without
/// anyone being able to say why.
TextStyle? chartLabelStyle(BuildContext context) => Theme.of(context)
    .textTheme
    .bodySmall
    ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

/// The wash under a line, fading out as it falls away from it.
///
/// A flat fill reads as a solid shape with a line on top — it competes with the
/// data. A gradient reads as the line casting light downward, which is the
/// point: it gives the line weight without adding a second thing to look at.
/// [cutOffY] stops the fill at the bottom of a zoomed-in band rather than at
/// zero — for a chart whose y-axis does not start there.
BarAreaData chartAreaFill(Color accent, {double? cutOffY}) => BarAreaData(
  show: true,
  cutOffY: cutOffY ?? 0,
  applyCutOffY: cutOffY != null,
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [accent.withValues(alpha: 0.28), accent.withValues(alpha: 0)],
  ),
);

/// Whether to mark every reading with a dot.
///
/// Dots say "these are the measurements, everything between them is drawn in".
/// That is worth saying while you can still count them; past a dozen they merge
/// into a thick, lumpy line and say nothing at all.
bool chartShowsDots(int pointCount) => pointCount <= 12;
