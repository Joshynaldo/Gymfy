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
      icon: Icons.checklist,
      title: 'Habits',
      subtitle: 'Daily checklist and streaks',
      route: '/more/habits',
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
