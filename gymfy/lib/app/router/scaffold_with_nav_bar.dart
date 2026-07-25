import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The persistent shell that wraps the five main tabs.
///
/// [navigationShell] is supplied by [StatefulShellRoute.indexedStack] in
/// `app_router.dart`. Switching tabs is done through
/// [StatefulNavigationShell.goBranch].
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the tab you're already on pops it back to its first screen.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The shell renders whichever branch (tab) is currently active.
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        // Colours (active tint, indicator) come from navigationBarTheme,
        // which is driven by the accent — see app_theme.dart.
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book),
            label: 'Exercises',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Muscles',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
