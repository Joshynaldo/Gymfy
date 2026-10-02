// Material exports an animation curve also named `Split`; hide it so `Split`
// here unambiguously means our Drift row class.
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/name_prompt_dialog.dart';
import '../../programs/widgets/training_block_settings.dart';
import '../data/workout_repository.dart';
import '../widgets/split_day_list.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../shared/widgets/lucide_icons.dart';

/// The overview of *one* split: every day shown as a card, each listing its
/// planned exercises inline so the whole programme is visible at a glance.
///
/// The active split is already on the Workout tab, so this screen is where you
/// end up when you open a split you are *not* currently following — to edit it,
/// or to make it the active one.
class SplitDaysScreen extends ConsumerWidget {
  const SplitDaysScreen({super.key, required this.splitId});

  final int splitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitAsync = ref.watch(splitProvider(splitId));

    // Title follows the split's name; falls back gracefully while loading or
    // if the split was deleted out from under us.
    final split = splitAsync.value;
    final title = split?.name ?? context.l10n.workoutSplitFallbackTitle;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(title),
        actions: [
          if (split != null) ...[
            TrainingBlockAction(split: split),
            ActiveSplitAction(split: split),
          ],
        ],
      ),
      body: (context) => SplitDayList(
        splitId: splitId,
        header: split == null ? null : TrainingBlockBanner(split: split),
      ),
      // Centred, and in the shape the design gives an action: the navigation
      // pill below it is centred too, and a button tucked into the corner
      // between them read as something that had been left there.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AppButton(
        label: context.l10n.workoutAddDay,
        icon: LucideIcons.plus,
        expand: false,
        onPressed: () => addDayTo(context, ref, splitId),
      ),
    );
  }
}

/// Prompts for a day name and adds it to [splitId]. Does nothing if cancelled.
///
/// Shared with the Workout tab, which offers the same action for the active
/// split.
Future<void> addDayTo(BuildContext context, WidgetRef ref, int splitId) async {
  final name = await showNamePromptDialog(
    context,
    title: context.l10n.workoutAddDay,
    label: context.l10n.workoutDayNameLabel,
    hint: context.l10n.workoutDayNameHint,
    confirmLabel: context.l10n.commonAdd,
  );
  if (name == null) return;

  await ref.read(workoutRepositoryProvider).createDay(splitId, name);
}

/// Marks this split as the one being followed.
///
/// Lives in the app bar rather than on the split list, because activating is a
/// decision you make while looking at a programme, not while scanning past it.
class ActiveSplitAction extends ConsumerWidget {
  const ActiveSplitAction({super.key, required this.split});

  final Split split;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);

    if (split.isActive) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Center(
          child: Row(
            children: [
              Icon(LucideIcons.circleCheck, size: 18, color: accent),
              const SizedBox(width: 6),
              Text(
                context.l10n.commonActive,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: accent),
              ),
            ],
          ),
        ),
      );
    }

    return TextButton(
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        final l10n = context.l10n;
        await ref.read(workoutRepositoryProvider).setActiveSplit(split.id);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.workoutNowFollowing(split.name))),
        );
      },
      child: Text(context.l10n.workoutSetActive),
    );
  }
}
