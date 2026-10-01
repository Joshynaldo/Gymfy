import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';

/// A tool the "More" hub links to.
class _Tool {
  const _Tool({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}

/// The "More" tab: a hub of extra tools that don't warrant their own bottom-nav
/// slot. Entries are added here as later phases build their screens.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  /// The hub's entries, worded in the app's language. Built per frame rather
  /// than held as a constant, because the words change with the language.
  static List<_Tool> _toolsFor(AppLocalizations l10n) => [
    // First, because it is the one people come to More looking for. It had a
    // bottom-nav tab of its own until four tabs left no room: you reach the
    // library when you are building a day or checking a movement, and both of
    // those start somewhere else in the app.
    _Tool(
      icon: Icons.menu_book,
      title: l10n.moreExerciseLibraryTitle,
      subtitle: l10n.moreExerciseLibrarySubtitle,
      route: '/exercises',
    ),
    _Tool(
      icon: Icons.restaurant,
      title: l10n.moreCalorieLogTitle,
      subtitle: l10n.moreCalorieLogSubtitle,
      route: '/more/calories',
    ),
    _Tool(
      icon: Icons.bar_chart,
      title: l10n.moreWeeklyTitle,
      subtitle: l10n.moreWeeklySubtitle,
      route: '/more/weekly',
    ),
    _Tool(
      icon: Icons.calculate_outlined,
      title: l10n.moreOneRmTitle,
      subtitle: l10n.moreOneRmSubtitle,
      route: '/more/one-rm',
    ),
    _Tool(
      icon: Icons.military_tech_outlined,
      title: l10n.moreStrengthRankTitle,
      subtitle: l10n.moreStrengthRankSubtitle,
      route: '/more/rank',
    ),
    _Tool(
      icon: Icons.ios_share,
      title: l10n.moreSharePlanTitle,
      subtitle: l10n.moreSharePlanSubtitle,
      route: '/more/share-plan',
    ),
    _Tool(
      icon: Icons.move_to_inbox_outlined,
      title: l10n.moreImportTitle,
      subtitle: l10n.moreImportSubtitle,
      route: '/more/import',
    ),
    _Tool(
      icon: Icons.help_outline,
      title: l10n.moreHelpTitle,
      subtitle: l10n.moreHelpSubtitle,
      route: '/more/help',
    ),
    _Tool(
      icon: Icons.settings_outlined,
      title: l10n.moreSettingsTitle,
      subtitle: l10n.moreSettingsSubtitle,
      route: '/more/settings',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tools = _toolsFor(l10n);
    return GlassScaffold(
      appBar: GlassAppBar(title: Text(l10n.moreTitle)),
      body: (context) => ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24) + barInsets(context),
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final tool = tools[index];
          return FadeSlideIn(
            // A short stagger down a fixed, always-visible list: the hub
            // assembles itself as it opens. Capped so the last row isn't still
            // arriving after you've decided what to tap.
            delay: Duration(milliseconds: 25 * (index > 6 ? 6 : index)),
            child: AppTile(
              icon: tool.icon,
              title: tool.title,
              subtitle: tool.subtitle,
              onTap: () => context.go(tool.route),
            ),
          );
        },
      ),
    );
  }
}
