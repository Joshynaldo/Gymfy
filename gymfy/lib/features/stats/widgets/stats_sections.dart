import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_segmented.dart';
import '../../calculator/data/rank_inputs.dart';
import '../../calculator/data/ranked_lifts.dart';
import '../../calculator/data/tier_style.dart';
import '../../calculator/widgets/rank_emblem.dart';
import '../../muscle_map/data/muscle_colors.dart';
import '../../muscle_map/data/muscle_fatigue_repository.dart';
import '../../muscle_map/data/muscle_volume_repository.dart';
import '../../muscle_map/widgets/muscle_map_view.dart';
import '../../workout/data/session_repository.dart';
import '../data/training_totals.dart';
import '../../../shared/widgets/animated_count.dart';

/// What the body map is colouring.
enum MapReading {
  /// Work done over the last 7 days — a record of what you trained.
  volume,

  /// Work still weighing on each muscle right now — a guess at what is ready.
  fatigue,
}

/// The muscle map, with its two readings.
///
/// Was the whole Stats tab; now one segment of Progress. The state is which
/// reading is showing — view state rather than a stored preference, same as the
/// front/back toggle inside the map itself.
class BodyMapSection extends ConsumerStatefulWidget {
  const BodyMapSection({super.key});

  @override
  ConsumerState<BodyMapSection> createState() => _BodyMapSectionState();
}

class _BodyMapSectionState extends ConsumerState<BodyMapSection> {
  MapReading _reading = MapReading.volume;

  bool get _isFatigue => _reading == MapReading.fatigue;

  @override
  Widget build(BuildContext context) {
    final data = _isFatigue
        ? ref.watch(muscleFatigueProvider)
        : ref.watch(weeklyMuscleIntensitiesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: AppSegmented<MapReading>(
            selected: _reading,
            onChanged: (value) => setState(() => _reading = value),
            segments: const [
              (value: MapReading.volume, label: 'Volume', leading: null),
              (value: MapReading.fatigue, label: 'Fatigue', leading: null),
            ],
          ),
        ),
        // A fixed height rather than Expanded: this is a scrolling page, not a
        // screen the map owns, and an unbounded child inside a ListView has no
        // height to fill.
        SizedBox(
          height: 460,
          child: MuscleMapView(
            intensities: data,
            // Fatigue is red, always — not the accent. The two readings share
            // this diagram, so colour is what tells you which one you are
            // looking at without reading the caption.
            heatColor: _isFatigue ? fatigueColor : null,
            emptyMessage: _isFatigue
                ? 'Everything is recovered — nothing you have trained '
                      'recently is still weighing on you.'
                : 'No training logged in the last 7 days — finish a '
                      'workout to light up your muscle map.',
            caption: _isFatigue
                ? 'How much recent work each muscle is still carrying. '
                      'Brighter = less recovered. Halves every two days.'
                : 'Training volume over the last 7 days. Brighter = more '
                      'volume.',
            contrastCaption: _isFatigue
                ? 'Each muscle has its own colour. Brighter still means '
                      'less recovered.'
                : 'Each muscle has its own colour. Brighter still means '
                      'more volume.',
          ),
        ),
      ],
    );
  }
}

/// Where you stand: the headline tier, then a medal per ranked lift.
class RankSection extends ConsumerWidget {
  const RankSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inputs = ref.watch(rankInputsProvider);
    final lifts = ref.watch(rankedLiftsProvider);

    if (inputs.sex == null || inputs.bodyweightKg == null) {
      return AppPanel(
        icon: Icons.military_tech_outlined,
        title: 'Strength rank',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ranks compare your lifts to your own bodyweight, so they need '
              'your bodyweight and which standards table to use.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                onPressed: () => context.go('/more/rank'),
                child: const Text('Set it up'),
              ),
            ),
          ],
        ),
      );
    }

    if (lifts.ranked.isEmpty) {
      return AppPanel(
        icon: Icons.military_tech_outlined,
        title: 'Strength rank',
        child: Text(
          'Log a barbell or cable lift — bench, squat, deadlift, press, row, '
          'curl — and its medal appears here.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OverallRank(lifts: lifts.ranked),
        AppSectionHeader(title: 'Your lifts', count: lifts.ranked.length),
        for (final lift in lifts.ranked) _RankRow(lift: lift),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
          child: TextButton(
            onPressed: () => context.go('/more/rank'),
            child: const Text('See the full breakdown'),
          ),
        ),
      ],
    );
  }
}

/// One emblem for the whole lifter, plus the spread behind it.
class _OverallRank extends StatelessWidget {
  const _OverallRank({required this.lifts});

  final List<RankedLift> lifts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // The *lowest* tier across the ranked lifts, not the highest. A single
    // strong deadlift shouldn't crown someone Advanced while their press is
    // Novice — the honest one-word answer to "how strong am I" is the one your
    // weakest big lift gives, and it also points at what to work on.
    final tier = lifts
        .map((l) => l.rank.tier)
        .reduce((a, b) => a.index <= b.index ? a : b);
    final best = lifts
        .map((l) => l.rank.tier)
        .reduce((a, b) => a.index >= b.index ? a : b);

    return AppPanel(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          RankEmblem(tier: tier, size: 76),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tier.label,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: tierColor(tier),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tier == best
                      ? 'Every ranked lift is ${tier.label.toLowerCase()}.'
                      : 'Your weakest ranked lift. Your best is '
                            '${best.label.toLowerCase()}.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One lift: its medal, its name, and how far to the next tier.
class _RankRow extends ConsumerWidget {
  const _RankRow({required this.lift});

  final RankedLift lift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);
    final rank = lift.rank;
    final next = rank.next;

    return AppCard(
      onTap: () => context.go('/more/rank'),
      child: Row(
        children: [
          RankEmblem(tier: rank.tier, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lift.name,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${rank.tier.label} • '
                  '${formatWeightUnit(lift.oneRm, unit)} '
                  '${lift.tested ? 'tested' : 'est.'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    // Elite has nothing above it, so the bar reads full.
                    value: rank.progressToNext ?? 1,
                    minHeight: 5,
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    color: tierColor(rank.tier),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            next == null
                ? 'Top'
                : '+${formatWeightUnit(rank.weightToNext!, unit)}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// What it all adds up to.
class TotalsSection extends ConsumerWidget {
  const TotalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totals = ref.watch(trainingTotalsProvider);
    final streak = ref.watch(workoutStreakProvider).value ?? 0;
    final unit = ref.watch(weightUnitProvider);

    if (totals == null || totals.workouts == 0) return const SizedBox.shrink();

    final comparison = volumeComparison(totals.volumeKg);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeader(title: 'All time'),
        AppPanel(
          child: Column(
            children: [
              Row(
                children: [
                  _Stat(
                    icon: Icons.event_available,
                    value: '${totals.workouts}',
                    count: totals.workouts.toDouble(),
                    format: (value) => '${value.round()}',
                    label: totals.workouts == 1 ? 'workout' : 'workouts',
                  ),
                  _Stat(
                    icon: Icons.repeat,
                    value: '${totals.sets}',
                    count: totals.sets.toDouble(),
                    format: (value) => '${value.round()}',
                    label: totals.sets == 1 ? 'set' : 'sets',
                  ),
                  _Stat(
                    icon: Icons.timer_outlined,
                    value: formatDuration(Duration(minutes: totals.minutes)),
                    label: 'trained',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _Stat(
                    icon: Icons.fitness_center,
                    value: formatWeightUnit(totals.volumeKg, unit),
                    count: totals.volumeKg,
                    format: (v) => formatWeightUnit(v, unit),
                    label: 'lifted',
                  ),
                  _Stat(
                    icon: Icons.calendar_month,
                    value: '${totals.days}',
                    label: totals.days == 1 ? 'day' : 'days',
                  ),
                  _Stat(
                    icon: Icons.local_fire_department,
                    value: '$streak',
                    label: 'day streak',
                  ),
                ],
              ),
            ],
          ),
        ),
        if (comparison != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Text(
              // A lifetime volume figure has no feel to it. This gives it one.
              'That is ${comparison.times.toStringAsFixed(1)}× '
              '${comparison.label}.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// One figure in the all-time grid.
class _Stat extends ConsumerWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    this.count,
    this.format,
  });

  final IconData icon;

  /// What to show when the figure is not one that counts — a clock, mostly.
  final String value;

  final String label;

  /// The figure, when it is a number worth watching move.
  ///
  /// The Stats tab is kept alive behind the navigation shell, so these widgets
  /// survive while you go and train. Coming back to it after logging a session
  /// and watching the all-time total climb to its new figure is the one moment
  /// this screen has — a number that has silently replaced itself says nothing.
  final double? count;

  /// How to render an in-between value. Required alongside [count].
  final String Function(double value)? format;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final style = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );

    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(height: 6),
          if (count != null && format != null)
            AnimatedCount(value: count!, format: format!, style: style)
          else
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
