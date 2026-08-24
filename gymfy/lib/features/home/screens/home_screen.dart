import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/data/onboarding_repository.dart';
import '../widgets/activity_heatmap.dart';
import '../widgets/last_workout_card.dart';
import '../widgets/next_up_card.dart';
import '../widgets/recap_section.dart';
import '../widgets/streak_badge.dart';
import '../widgets/today_card.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(name == null ? 'Gymfy' : 'Hi, $name'),
        actions: const [StreakBadge()],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 6, bottom: 24),
        children: [
          TodayCard(today: today),
          NextUpCard(today: today),
          const LastWorkoutCard(),
          const RecapSection(),
          // Last: the recap answers "how am I doing lately", and the year view
          // is the long look back you take after it, not before.
          ActivityHeatmap(today: today),
        ],
      ),
    );
  }
}
