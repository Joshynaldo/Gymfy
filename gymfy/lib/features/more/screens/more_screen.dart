import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';

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
      icon: Icons.donut_large_outlined,
      title: 'Plate calculator',
      subtitle: 'What to put on the bar for any weight',
      route: '/more/plates',
    ),
    _Tool(
      icon: Icons.military_tech_outlined,
      title: 'Strength rank',
      subtitle: 'How your big lifts compare to your bodyweight',
      route: '/more/rank',
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
    final accent = ref.watch(accentColorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView.separated(
        itemCount: _tools.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final tool = _tools[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: accent.withValues(alpha: 0.15),
              child: Icon(tool.icon, color: accent),
            ),
            title: Text(tool.title),
            subtitle: Text(tool.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(tool.route),
          );
        },
      ),
    );
  }
}
