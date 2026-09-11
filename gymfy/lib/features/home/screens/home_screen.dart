import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../onboarding/data/onboarding_repository.dart';

import '../../progress/widgets/activity_heatmap.dart';
import '../widgets/last_workout_card.dart';

import '../../../shared/widgets/glass_icon_button.dart';
import '../widgets/streak_badge.dart';
import '../widgets/week_card.dart';
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
        actions: [
          const StreakBadge(),
          // The way into the library from the screen people actually open.
          // It moved under More when the bar went to four tabs, and a
          // reference you reach from wherever you happen to be needs a door
          // on the tab you are most often standing on.
          GlassIconButton(
            icon: Icons.search,
            tooltip: 'Find an exercise',
            onPressed: () => context.go('/exercises'),
          ),
        ],
      ),
      body: (context) => ListView(
        padding: const EdgeInsets.only(top: 6, bottom: 24) + barInsets(context),
        children: [
          TodayCard(today: today),
          // No "up next" card: the template's Home is today, the last
          // session, and the week — and the Workout tab shows the whole split
          // anyway. The widget is kept; it was the second accent on a tab whose
          // accent belongs to Start workout.
          const LastWorkoutCard(),
          const WeekCard(),
          // The year grid. It also lives in Progress → All-time, where it is
          // the long look back; here it is the short one — how the last few
          // weeks have actually gone, under the week you are in.
          ActivityHeatmap(today: today),
        ],
      ),
    );
  }
}
