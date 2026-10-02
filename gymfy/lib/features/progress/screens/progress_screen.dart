import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/glass.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/utils/exercise_display.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_segmented.dart';
import '../../../shared/widgets/exercise_thumbnail.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_icon_button.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../calendar/widgets/training_calendar.dart';
import '../../goals/widgets/goals_link.dart';
import '../../reviews/widgets/review_links.dart';
import '../../stats/widgets/stats_sections.dart';
import '../data/progress_repository.dart';
import '../widgets/activity_heatmap.dart';
import '../widgets/recap_section.dart';
import '../widgets/streak_card.dart';
import '../../../shared/widgets/lucide_icons.dart';

/// Which question Progress is answering.
///
/// Ordered the way the design orders them, which is also how the question gets
/// shorter: what does my body look like now, how have the last weeks gone, what
/// does it all add up to. Present, recent, ever.
enum ProgressView {
  /// What your body is doing — the muscle map, measurements and photos.
  body('Body'),

  /// How the last week / month / year went, and each exercise's own curve.
  trends('Trends'),

  /// What it all adds up to: totals, the year grid, records, rank.
  allTime('All-time');

  const ProgressView(this.label);

  /// The English name. On screen use [localizedLabel].
  final String label;

  /// The name in the app's language, e.g. "Verlauf".
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    ProgressView.body => l10n.progressViewBody,
    ProgressView.trends => l10n.progressViewTrends,
    ProgressView.allTime => l10n.progressViewAllTime,
  };
}

/// The Progress tab: three answers to "how is it going", behind one control.
///
/// These used to be two tabs and a buried screen — Progress was a list of
/// exercises under More, and Stats was a bottom-nav slot of its own. They were
/// always the same question asked at three ranges, and splitting them across
/// the navigation meant the answer depended on which door you came in by.
///
/// The segmented control lives in the app bar rather than in the list, so it
/// survives the scroll. A control that chooses what the screen is showing, and
/// then scrolls away, takes the only way back with it.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  // Opens on Trends rather than on the first segment: it is the view that
  // answers "how is it going" with numbers, and the one you came for.
  ProgressView _view = ProgressView.trends;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(l10n.progressTitle),
        actions: [
          // Actions rather than list entries, so they are reachable even when
          // a segment shows its empty state.
          GlassIconButton(
            icon: LucideIcons.images,
            tooltip: l10n.progressPhotosTitle,
            onPressed: () => context.go('/progress/photos'),
          ),
          GlassIconButton(
            icon: LucideIcons.ruler,
            tooltip: l10n.progressMeasurementsTitle,
            onPressed: () => context.go('/progress/measurements'),
          ),
        ],
        bottom: SegmentedBar<ProgressView>(
          selected: _view,
          onChanged: (value) => setState(() => _view = value),
          segments: [
            for (final view in ProgressView.values)
              (value: view, label: view.localizedLabel(l10n), leading: null),
          ],
        ),
      ),
      // Keyed by the segment so the switch reads as a change of subject rather
      // than the same list quietly rearranging itself.
      body: (context) => FadeSlideIn(
        key: ValueKey(_view),
        child: switch (_view) {
          ProgressView.trends => const _Trends(),
          ProgressView.allTime => const _AllTime(),
          ProgressView.body => const _Body(),
        },
      ),
    );
  }
}

/// Volume, sessions and muscles over a range — then each exercise's own curve.
class _Trends extends ConsumerWidget {
  const _Trends();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesWithHistoryProvider);
    final exercises = exercisesAsync.value ?? const [];

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 24) + barInsets(context),
      children: [
        const RecapSection(),
        // The recap's long form: a calendar month or year written up.
        const ReviewLinks(),
        if (exercises.isNotEmpty) ...[
          AppSectionHeader(
            title: context.l10n.progressPerExercise,
            count: exercises.length,
          ),
          for (final exercise in exercises)
            AppTile(
              icon: exerciseIcon,
              leading: ExerciseThumbnail(gifPath: exercise.gifPath),
              title: exercise.name,
              // A chart icon rather than a chevron: it says what opening this
              // gets you, which "›" doesn't.
              trailing: const Icon(LucideIcons.chartLine, size: 20),
              onTap: () => context.go('/progress/exercise/${exercise.id}'),
            ),
        ] else if (!exercisesAsync.isLoading)
          const _NoHistory(),
      ],
    );
  }
}

/// The long look back.
class _AllTime extends StatelessWidget {
  const _AllTime();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 24) + barInsets(context),
      children: const [
        TotalsSection(),
        ActivityHeatmap(),
        // Beside the year grid: the grid says how the year went, the
        // calendar what happened on a given day.
        TrainingCalendar(),
        GoalsLink(),
        RankSection(),
        StreakCard(),
      ],
    );
  }
}

/// What your body is doing.
class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 24) + barInsets(context),
      children: const [BodyMapSection(), _BodyLinks()],
    );
  }
}

/// The two things about your body the app stores rather than derives.
class _BodyLinks extends StatelessWidget {
  const _BodyLinks();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: l10n.progressTrackedByHand),
        AppTile(
          icon: LucideIcons.ruler,
          title: l10n.progressMeasurementsTitle,
          subtitle: l10n.progressMeasurementsSubtitle,
          onTap: () => context.go('/progress/measurements'),
        ),
        AppTile(
          icon: LucideIcons.images,
          title: l10n.progressPhotosTitle,
          subtitle: l10n.progressPhotosSubtitle,
          onTap: () => context.go('/progress/photos'),
        ),
      ],
    );
  }
}

class _NoHistory extends StatelessWidget {
  const _NoHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
      child: Column(
        children: [
          Icon(
            LucideIcons.chartLine,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.progressNoHistoryTitle,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.progressNoHistoryMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
