import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_card.dart';

import '../../onboarding/data/onboarding_repository.dart';
import '../widgets/activity_heatmap.dart';
import '../widgets/last_workout_card.dart';
import '../widgets/next_up_card.dart';
import '../widgets/recap_section.dart';
import '../widgets/streak_badge.dart';
import '../widgets/today_card.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';

/// The Home tab: today first, then what's coming, then what you last did.
///
/// Deliberately in that order — the question the app is opened to answer is
/// almost always "what am I doing today?", and everything else is context for
/// it. The cards that have nothing to say render nothing rather than showing an
/// empty placeholder, so a new install is short instead of full of blanks.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.today});

  /// Overridable so tests can fix the weekday rather than depending on the day
  /// they happen to run.
  final DateTime? today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userNameProvider).value;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(name == null ? 'Gymfy' : 'Hi, $name'),
        actions: const [StreakBadge()],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 6, bottom: 24) + barInsets(context),
        children: [
          TodayCard(today: today),
          NextUpCard(today: today),
          const LastWorkoutCard(),
          const RecapSection(),
          // Last: the recap answers "how am I doing lately", and the year view
          // is the long look back you take after it, not before.
          ActivityHeatmap(today: today),
          // Progress lost its bottom-nav tab, so it needs a way in from the
          // screen people actually open. Placed at the bottom on purpose: it
          // follows the recap and the year grid, which is exactly the point at
          // which "show me the actual numbers" occurs to you.
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: _ProgressLink(),
          ),
        ],
      ),
    );
  }
}

/// The way into Progress now that it is no longer a tab.
class _ProgressLink extends StatelessWidget {
  const _ProgressLink();

  @override
  Widget build(BuildContext context) {
    return AppTile(
      icon: Icons.show_chart,
      title: 'Progress',
      subtitle: 'Charts, personal records, photos and measurements',
      // `go` rather than a push: this genuinely belongs to the More branch now,
      // and pushing it on top of Home would leave the nav bar highlighting the
      // wrong tab while you read it.
      onTap: () => context.go('/more/progress'),
    );
  }
}
