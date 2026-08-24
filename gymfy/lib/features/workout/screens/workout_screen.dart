// Material exports an animation curve also named `Split`; hide it so `Split`
// here unambiguously means our Drift row class.
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/database/app_database.dart';
import '../data/workout_repository.dart';
import '../widgets/split_day_list.dart';
import 'split_days_screen.dart' show addDayTo;
import 'split_list_screen.dart' show createSplit;

/// The Workout tab: the split you're actually following, with its days on first
/// sight.
///
/// It used to open on a list of splits, which meant two taps stood between the
/// tab and the programme — and for most people that list has exactly one entry.
/// The active split is the answer to "what am I training?", so it's what the tab
/// shows; the other splits live one tap away behind the switcher in the app bar.
class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitsAsync = ref.watch(splitListProvider);
    final activeAsync = ref.watch(activeSplitProvider);

    // One loading state for both streams: showing the app bar before we know
    // whether there is a split at all would flash the wrong title.
    if (splitsAsync.isLoading || activeAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final error = splitsAsync.error ?? activeAsync.error;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load your splits.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final splits = splitsAsync.value ?? const <Split>[];
    final active = activeAsync.value;

    if (splits.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: _NoSplitsYet(onCreate: () => createSplit(context, ref)),
      );
    }

    // Splits exist but none is marked active — only reachable by deleting the
    // active one. There is nothing sensible to show until one is chosen, so we
    // ask instead of guessing.
    if (active == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Workout'),
          actions: [_SwitcherAction(splits: splits, activeId: null)],
        ),
        body: _NoActiveSplit(
          onChoose: () => _openSwitcher(context, ref, splits, null),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(active.name),
        actions: [_SwitcherAction(splits: splits, activeId: active.id)],
      ),
      body: SplitDayList(splitId: active.id),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => addDayTo(context, ref, active.id),
        icon: const Icon(Icons.add),
        label: const Text('Add day'),
      ),
    );
  }
}

/// The app bar button that opens the split switcher.
///
/// Shown even with a single split, because the sheet is also the only way to
/// reach "New split" and "Manage splits" from this tab — with it hidden, a
/// one-split user could never make a second one.
class _SwitcherAction extends ConsumerWidget {
  const _SwitcherAction({required this.splits, required this.activeId});

  final List<Split> splits;
  final int? activeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.swap_horiz),
      tooltip: 'Switch split',
      onPressed: () => _openSwitcher(context, ref, splits, activeId),
    );
  }
}

/// Opens the switcher sheet and carries out whatever was picked.
Future<void> _openSwitcher(
  BuildContext context,
  WidgetRef ref,
  List<Split> splits,
  int? activeId,
) async {
  final choice = await showModalBottomSheet<_SwitcherChoice>(
    context: context,
    showDragHandle: true,
    builder: (context) =>
        _SwitcherSheet(splits: splits, activeId: activeId),
  );
  if (choice == null || !context.mounted) return;

  switch (choice.action) {
    case _SwitcherActionKind.activate:
      await ref.read(workoutRepositoryProvider).setActiveSplit(choice.splitId!);
    case _SwitcherActionKind.create:
      await createSplit(context, ref);
    case _SwitcherActionKind.manage:
      // This is the screen's own context, not the sheet's, so it is still good
      // after the sheet closed — the `mounted` check above covers the rest.
      context.go('/workout/splits');
  }
}

/// What the user picked in the switcher sheet.
enum _SwitcherActionKind { activate, create, manage }

class _SwitcherChoice {
  const _SwitcherChoice.activate(int id)
    : action = _SwitcherActionKind.activate,
      splitId = id;
  const _SwitcherChoice.create()
    : action = _SwitcherActionKind.create,
      splitId = null;
  const _SwitcherChoice.manage()
    : action = _SwitcherActionKind.manage,
      splitId = null;

  final _SwitcherActionKind action;

  /// Only set for [_SwitcherActionKind.activate].
  final int? splitId;
}

/// The switcher: every split, with the active one ticked, plus the two ways out
/// (make a new one, or go manage them).
class _SwitcherSheet extends ConsumerWidget {
  const _SwitcherSheet({required this.splits, required this.activeId});

  final List<Split> splits;
  final int? activeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Your splits', style: theme.textTheme.titleLarge),
          ),
          // Bounded so a long list scrolls inside the sheet instead of pushing
          // the two actions below off the screen.
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final split in splits)
                  ListTile(
                    leading: Icon(
                      split.id == activeId
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: split.id == activeId ? accent : null,
                    ),
                    title: Text(split.name),
                    // Tapping the active one is a no-op, so it closes without
                    // a pointless write.
                    onTap: () => Navigator.of(context).pop(
                      split.id == activeId
                          ? null
                          : _SwitcherChoice.activate(split.id),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('New split'),
            onTap: () =>
                Navigator.of(context).pop(const _SwitcherChoice.create()),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Manage splits'),
            onTap: () =>
                Navigator.of(context).pop(const _SwitcherChoice.manage()),
          ),
        ],
      ),
    );
  }
}

/// Shown the very first time the tab is opened, before any split exists.
class _NoSplitsYet extends StatelessWidget {
  const _NoSplitsYet({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_view_week,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('No splits yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Create your first split to start planning your training.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('New split'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when splits exist but none is active — e.g. right after deleting the
/// one that was.
class _NoActiveSplit extends StatelessWidget {
  const _NoActiveSplit({required this.onChoose});

  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horiz,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('No active split', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Pick the programme you are following and its days will show up '
              'here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onChoose,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Choose a split'),
            ),
          ],
        ),
      ),
    );
  }
}
