import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  static const _tools = [
    // First, and by some distance the most used thing here — it was a
    // bottom-nav tab until the bar got too crowded to read.
    _Tool(
      icon: Icons.show_chart,
      title: 'Progress',
      subtitle: 'Charts, personal records, photos and measurements',
      route: '/more/progress',
    ),
    _Tool(
      icon: Icons.restaurant,
      title: 'Calorie log',
      subtitle: 'Track meals, calories and macros',
      route: '/more/calories',
    ),
    _Tool(
      icon: Icons.bar_chart,
      title: 'This week',
      subtitle: 'Calories over the last 7 days',
      route: '/more/weekly',
    ),
    _Tool(
      icon: Icons.calculate_outlined,
      title: '1RM calculator',
      subtitle: 'Estimate your one-rep max from any set',
      route: '/more/one-rm',
    ),
    _Tool(
      icon: Icons.military_tech_outlined,
      title: 'Strength rank',
      subtitle: 'How your big lifts compare to your bodyweight',
      route: '/more/rank',
    ),
    _Tool(
      icon: Icons.ios_share,
      title: 'Share a plan',
      subtitle: 'Send your splits to someone, or import theirs',
      route: '/more/share-plan',
    ),
    _Tool(
      icon: Icons.help_outline,
      title: 'Help',
      subtitle: 'About Gymfy and who made it',
      route: '/more/help',
    ),
    _Tool(
      icon: Icons.settings_outlined,
      title: 'Settings',
      subtitle: 'Accent colour, your name, rest timer alerts',
      route: '/more/settings',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassScaffold(
      appBar: GlassAppBar(title: const Text('More')),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24) + barInsets(context),
        itemCount: _tools.length,
        itemBuilder: (context, index) {
          final tool = _tools[index];
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
