import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets/app_card.dart';
import '../../home/data/recap_repository.dart';
import '../data/review.dart';

/// The two ways into the reviews, under the recap on Progress → Trends.
///
/// Under the recap because they are its long form: the recap's Month and
/// Year segments are the last few weeks and the last twelve months as charts;
/// these are a calendar month and a calendar year written up, compared with
/// the one before, and ready to send.
///
/// Hidden until something has been logged, like the recap above them.
class ReviewLinks extends ConsumerWidget {
  const ReviewLinks({super.key, this.today});

  /// Overridable so tests don't depend on the day they run.
  final DateTime? today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(recapSetsProvider).value;
    if (sets == null || sets.isEmpty) return const SizedBox.shrink();

    final l10n = context.l10n;
    final now = today ?? DateTime.now();
    final month = defaultReviewPeriod(ReviewSpan.month, now, sets);
    final year = defaultReviewPeriod(ReviewSpan.year, now, sets);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: l10n.reviewsTitle),
        AppTile(
          icon: Icons.calendar_view_month,
          title: l10n.reviewsMonthlyTitle,
          subtitle: l10n.reviewsMonthlySubtitle(month.localizedLabel(l10n)),
          onTap: () => context.go(
            '/progress/review/month/${month.start.year}/${month.start.month}',
          ),
        ),
        AppTile(
          icon: Icons.auto_awesome_outlined,
          title: l10n.reviewsYearTitle,
          subtitle: l10n.reviewsYearSubtitle(year.localizedLabel(l10n)),
          onTap: () => context.go('/progress/review/year/${year.start.year}'),
        ),
      ],
    );
  }
}
