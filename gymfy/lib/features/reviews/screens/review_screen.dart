import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/glass.dart';
import '../../../shared/utils/exercise_display.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_icon_button.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../exercises/data/exercise_names.dart';
import '../data/image_share.dart';
import '../data/review.dart';
import '../data/review_providers.dart';
import '../widgets/review_share_card.dart';

/// How many exercises the list under the card goes down to.
const _listedExercises = 8;

/// A month or a year in training, with the one before for comparison, and a
/// button that sends it on as a picture.
///
/// Opens on [initial] and steps a period at a time from there. The step
/// lives in the screen rather than the route: flicking back through the year
/// month by month should not stack twelve screens to back out of.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.initial, this.today});

  final ReviewPeriod initial;

  /// Overridable so tests don't depend on the day they run.
  final DateTime? today;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late ReviewPeriod _period = widget.initial;

  /// Around the card, so the card — and only the card — becomes the image.
  final _shareKey = GlobalKey();

  bool _sharing = false;

  DateTime get _today => widget.today ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    final review = ref.watch(reviewProvider(_period));
    final canShare = review != null && !review.current.isEmpty;
    final atLatest = _period.isCurrent(_today) || _period.start.isAfter(_today);

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          _period.span == ReviewSpan.month
              ? 'Monthly review'
              : 'Year in training',
        ),
        actions: [
          if (canShare)
            GlassIconButton(
              icon: Icons.ios_share,
              tooltip: 'Share as image',
              onPressed: _sharing ? () {} : _share,
            ),
        ],
      ),
      body: (context) => ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 24) + barInsets(context),
        children: [
          _PeriodStepper(
            label: _period.label,
            onPrevious: () => setState(() => _period = _period.previous),
            onNext: atLatest
                ? null
                : () => setState(() => _period = _period.next),
          ),
          if (review == null)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (review.current.isEmpty)
            _NothingLogged(period: _period)
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                // Rounded on screen; the image underneath is square and fully
                // opaque, so it has no see-through corners wherever it lands.
                borderRadius: BorderRadius.circular(24),
                child: RepaintBoundary(
                  key: _shareKey,
                  child: ReviewShareCard(review: review, today: _today),
                ),
              ),
            ),
            _ExerciseList(stats: review.current),
          ],
        ],
      ),
    );
  }

  Future<void> _share() async {
    final boundary =
        _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await capturePng(boundary);
      final outcome = await shareOrSaveImage(
        bytes,
        fileName: _fileName(_period),
        title: 'Share your ${_period.label} review',
      );
      if (outcome == ShareOutcome.saved) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Image saved — send it from your files.'),
          ),
        );
      }
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not make the image.\n$error')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

/// "gymfy-review-2026-09.png" or "gymfy-review-2026.png".
String _fileName(ReviewPeriod period) {
  final month = period.start.month.toString().padLeft(2, '0');
  return period.span == ReviewSpan.month
      ? 'gymfy-review-${period.start.year}-$month.png'
      : 'gymfy-review-${period.start.year}.png';
}

class _PeriodStepper extends StatelessWidget {
  const _PeriodStepper({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;

  /// Null at the latest period — there is nothing ahead to review.
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Earlier',
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Later',
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _NothingLogged extends StatelessWidget {
  const _NothingLogged({required this.period});

  final ReviewPeriod period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No workouts in ${period.label}.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Step back to an earlier '
            '${period.span == ReviewSpan.month ? 'month' : 'year'} with the '
            'arrows above.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Every exercise of the period past the card's top three, most sets first,
/// each opening its own chart.
class _ExerciseList extends ConsumerWidget {
  const _ExerciseList({required this.stats});

  final ReviewStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final names = ref.watch(exerciseNamesProvider);
    final unit = ref.watch(weightUnitProvider);
    final shown = stats.topExercises.take(_listedExercises).toList();
    if (shown.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: 'Exercises', count: stats.topExercises.length),
        for (final exercise in shown)
          AppTile(
            icon: exerciseIcon,
            title:
                names[exercise.exerciseId] ?? muscleLabel(exercise.exerciseId),
            subtitle: [
              '${exercise.sets} ${exercise.sets == 1 ? 'set' : 'sets'}',
              '${exercise.workouts} '
                  '${exercise.workouts == 1 ? 'workout' : 'workouts'}',
              formatWeightUnit(exercise.volumeKg, unit),
            ].join(' · '),
            trailing: const Icon(Icons.show_chart, size: 20),
            // Pushed rather than gone to, so back returns to this review
            // instead of to the top of Progress.
            onTap: () =>
                context.push('/progress/exercise/${exercise.exerciseId}'),
          ),
      ],
    );
  }
}
