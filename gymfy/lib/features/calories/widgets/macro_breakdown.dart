import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';

/// Calories per gram for each macronutrient.
const _kcalPerGramProtein = 4;
const _kcalPerGramCarbs = 4;
const _kcalPerGramFat = 9;

/// A donut chart of the day's macro split (by calories) with a legend showing
/// grams and share of each of protein / carbs / fat.
///
/// Slice colours are derived from the accent as a triadic set, so the chart
/// stays on-theme and follows accent changes (no hardcoded palette).
class MacroBreakdown extends ConsumerWidget {
  const MacroBreakdown({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int protein;
  final int carbs;
  final int fat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final colors = _macroColors(accent);

    final pKcal = protein * _kcalPerGramProtein;
    final cKcal = carbs * _kcalPerGramCarbs;
    final fKcal = fat * _kcalPerGramFat;
    final totalKcal = pKcal + cKcal + fKcal;

    final macros = [
      (label: 'Protein', grams: protein, kcal: pKcal, color: colors[0]),
      (label: 'Carbs', grams: carbs, kcal: cKcal, color: colors[1]),
      (label: 'Fat', grams: fat, kcal: fKcal, color: colors[2]),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Macros', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (totalKcal == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Add meals with macros to see your split.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 34,
                          sections: [
                            for (final m in macros)
                              if (m.kcal > 0)
                                PieChartSectionData(
                                  value: m.kcal.toDouble(),
                                  color: m.color,
                                  radius: 16,
                                  showTitle: false,
                                ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$totalKcal',
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            'kcal',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      for (final m in macros)
                        _LegendRow(
                          color: m.color,
                          label: m.label,
                          grams: m.grams,
                          percent: totalKcal == 0 ? 0 : m.kcal / totalKcal,
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.grams,
    required this.percent,
  });

  final Color color;
  final String label;
  final int grams;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            '${grams}g · ${(percent * 100).round()}%',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Three distinct, on-theme colours (triadic) derived from the accent.
List<Color> _macroColors(Color accent) {
  final hsl = HSLColor.fromColor(accent);
  Color rotate(double degrees) =>
      hsl.withHue((hsl.hue + degrees) % 360).toColor();
  return [rotate(0), rotate(120), rotate(240)];
}
