import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/utils/weekday.dart';
import '../../../shared/widgets/animated_count.dart';
import '../../../shared/widgets/app_card.dart';
import '../data/recap.dart';
import '../data/recap_repository.dart';

/// How the week is going: one number, and seven bars under it.
///
/// The long version of this — volume, sessions and muscles across three ranges
/// — is the Trends segment of Progress. What belongs on Home is the single
/// glance: am I doing the work this week. Anything more and the tab stops
/// answering "what am I doing today" first.
///
/// Renders nothing at all before the first logged set. A card reading "0 kg" on
/// a new install is worse than no card: it looks like a failure rather than a
/// beginning.
class WeekCard extends ConsumerWidget {
  const WeekCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recap = ref.watch(recapProvider(RecapPeriod.week));
    if (recap == null || recap.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);
    final peak = recap.buckets.fold<double>(
      0,
      (max, b) => b.volumeKg > max ? b.volumeKg : max,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: 'This week',
          countLabel:
              '${recap.sessions} ${recap.sessions == 1 ? 'workout' : 'workouts'}',
        ),
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Counts up when it changes. Coming back to Home after a session
              // is the one moment this number has, and one that silently
              // replaced itself says nothing happened.
              AnimatedCount(
                value: weightIn(recap.totalVolumeKg, unit),
                format: (value) => '${formatWeight(value)} ${unit.label}',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 3),
              // The bucket's own label is a chart axis tick — one or two
              // letters, sized to fit under a bar. In a sentence it came out as
              // "lifted since S", which is not a day and not English.
              Text(
                'lifted since ${weekdayName(recap.buckets.first.start.weekday)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              // No fixed height on the row. The bars themselves are 56; the
              // label under them is whatever the reader's text size makes it,
              // and the design's 76 was the sum of the two at one particular
              // setting. Hard-coding a total means the label overflows the
              // moment anything about it changes — which it did, by two pixels
              // at the default size and six at 130%.
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final bucket in recap.buckets)
                    Expanded(
                      child: _Bar(
                        label: bucket.label,
                        // Against the tallest day rather than a fixed scale:
                        // the question is which day was the big one, not how
                        // this week compares to an arbitrary ceiling.
                        fraction: peak == 0 ? 0 : bucket.volumeKg / peak,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.fraction});

  final String label;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 56,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: fraction.clamp(0.0, 1.0),
                widthFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    // White, not the accent. There is one accent on this tab
                    // and it is on the button that starts the workout; seven
                    // accent bars underneath it would be seven more things
                    // claiming to be the point.
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}
