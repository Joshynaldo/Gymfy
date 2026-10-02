import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/utils/exercise_display.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../../exercises/data/exercise_names.dart';
import '../../muscle_map/data/muscle_colors.dart';
import '../data/review.dart';
import '../../../shared/widgets/lucide_icons.dart';

/// How many exercises and muscles the card names. Three is a podium; the
/// screen below the card lists the rest.
const shareCardTopCount = 3;

/// A review laid out as one picture: the card on screen and the image that is
/// shared are the same widget.
///
/// Painted on an opaque surface rather than glass, deliberately. The share
/// sheet hands this to apps that know nothing of the backdrop behind it, and a
/// translucent pane would arrive as a card floating on whatever the receiving
/// app happens to draw — usually white.
class ReviewShareCard extends ConsumerWidget {
  const ReviewShareCard({super.key, required this.review, this.today});

  final TrainingReview review;

  /// Used to say "so far" on a period still running. Defaults to now.
  final DateTime? today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = ref.watch(accentColorProvider);
    final unit = ref.watch(weightUnitProvider);
    final now = review.current;
    final before = review.previous;
    final period = review.period;
    final running = period.isCurrent(today ?? DateTime.now());
    final muted = theme.colorScheme.onSurfaceVariant;
    final names = ref.watch(exerciseNamesProvider);

    // Only compared when the period before had something in it: "+12 vs
    // August" after a first month of nothing is a comparison with a blank.
    final compare = !before.isEmpty;
    final versus = l10n.reviewsVersus(
      period.previous.localizedShortLabel(l10n),
    );

    String? delta(num a, num b, [String Function(num)? format]) =>
        compare ? signedDelta(a, b, format: format) : null;

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(LucideIcons.chartLine, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    period.span == ReviewSpan.month
                        ? l10n.reviewsCardMonthHeading
                        : l10n.reviewsCardYearHeading,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: muted,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              period.localizedLabel(l10n),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (running)
              Text(
                l10n.reviewsCardSoFar(period.localizedShortLabel(l10n)),
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Figure(
                  label: l10n.reviewsCardWorkouts(now.workouts),
                  value: '${now.workouts}',
                  delta: delta(now.workouts, before.workouts),
                  versus: versus,
                ),
                _Figure(
                  label: l10n.reviewsCardLifted,
                  value: formatWeightUnit(now.volumeKg, unit, l10n: l10n),
                  delta: delta(
                    now.volumeKg,
                    before.volumeKg,
                    (v) => formatWeightUnit(v.toDouble(), unit, l10n: l10n),
                  ),
                  versus: versus,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Figure(
                  label: now.untimedWorkouts == 0
                      ? l10n.reviewsCardTrained
                      : l10n.reviewsCardTrainedUntimed(now.untimedWorkouts),
                  // Known minutes only; a workout whose length was never
                  // recorded is counted above and left off the clock.
                  value: formatDuration(Duration(minutes: now.minutes)),
                  delta: delta(
                    now.minutes,
                    before.minutes,
                    (v) => formatDuration(Duration(minutes: v.round())),
                  ),
                  versus: versus,
                ),
                _Figure(
                  label: l10n.reviewsCardRecords(now.records),
                  value: '${now.records}',
                  delta: delta(now.records, before.records),
                  versus: versus,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              [
                l10n.reviewsCardDaysTrained(now.activeDays),
                l10n.reviewsCardLongestStreak(now.longestStreak),
              ].join(' · '),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            if (now.topExercises.isNotEmpty) ...[
              const SizedBox(height: 18),
              _Heading(text: l10n.reviewsCardTopExercises, colour: muted),
              const SizedBox(height: 6),
              for (final (index, exercise)
                  in now.topExercises.take(shareCardTopCount).indexed)
                _RankLine(
                  rank: index + 1,
                  // The id title-cased while the library loads — it is a
                  // readable slug, and better than a blank.
                  label:
                      names[exercise.exerciseId] ??
                      muscleLabel(exercise.exerciseId),
                  value: l10n.reviewsSets(exercise.sets),
                  accent: accent,
                ),
            ],
            if (now.muscleSets.isNotEmpty) ...[
              const SizedBox(height: 14),
              _Heading(text: l10n.reviewsCardMostTrained, colour: muted),
              const SizedBox(height: 8),
              for (final entry in now.muscleSets.take(shareCardTopCount))
                _MuscleBar(
                  muscleId: entry.key,
                  sets: entry.value,
                  top: now.muscleSets.first.value,
                ),
            ],
            const SizedBox(height: 16),
            Text(
              l10n.reviewsCardTrackedWith,
              textAlign: TextAlign.right,
              style: theme.textTheme.labelSmall?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// One headline number, its label, and how it moved.
class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.delta,
    required this.versus,
  });

  final String label;
  final String value;
  final String? delta;
  final String versus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scaled down rather than cut off: "41,040 kg" on a narrow phone
            // with large text is still one number, and an ellipsis in the
            // middle of it would be worse than a smaller font.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            if (delta != null)
              Text(
                '$delta $versus',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(color: muted),
              ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.text, required this.colour});

  final String text;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: colour, letterSpacing: 1),
    );
  }
}

class _RankLine extends StatelessWidget {
  const _RankLine({
    required this.rank,
    required this.label,
    required this.value,
    required this.accent,
  });

  final int rank;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$rank',
              style: theme.textTheme.titleSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// A muscle and its share of the sets, in the muscle map's own colour so the
/// two agree about which colour is which muscle.
class _MuscleBar extends StatelessWidget {
  const _MuscleBar({
    required this.muscleId,
    required this.sets,
    required this.top,
  });

  final String muscleId;
  final int sets;
  final int top;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Flexible(
            flex: 2,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                muscleLabel(muscleId, l10n: context.l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: top == 0 ? 0 : sets / top,
                minHeight: 8,
                color: muscleColor(muscleId),
                backgroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.08,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sets',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
