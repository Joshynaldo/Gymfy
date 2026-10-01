// Training block settings on a split: how many weeks of training before a
// deload week, how light the deload is, and when week 1 began — plus the line
// on the split that says which week this is.
//
// The arithmetic lives in overload/data/training_block.dart; this file only
// shows it and writes the three split columns through TrainingPlanRepository.

// Material exports an animation curve also named `Split`; hide it so `Split`
// here unambiguously means our Drift row class.
import 'package:clock/clock.dart';
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/utils/dates.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/glass_sheet.dart';
import '../../overload/data/percent_target.dart';
import '../../overload/data/training_block.dart';
import '../data/training_plan_repository.dart';

/// Deload loads offered as chips. A split storing something else (an imported
/// value, an older build) gets its own chip added, so it is never silently
/// changed by opening the sheet.
const _deloadChoices = [50.0, 60.0, 70.0, 80.0, 90.0];

/// Block length a new block starts from: three hard weeks and a deload is the
/// most common shape in written programmes.
const _defaultBlockWeeks = 3;

/// The app bar button that opens the block settings for [split].
class TrainingBlockAction extends ConsumerWidget {
  const TrainingBlockAction({super.key, required this.split});

  final Split split;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasBlock = split.blockWeeks != null;
    return IconButton(
      // Tinted while a block runs, so the button also answers "is this split
      // on a block?" without being opened.
      icon: Icon(
        Icons.event_repeat,
        color: hasBlock ? ref.watch(accentColorProvider) : null,
      ),
      tooltip: 'Training block',
      onPressed: () => editTrainingBlock(context, ref, split),
    );
  }
}

/// Opens the block settings for [split] and saves whatever comes back.
Future<void> editTrainingBlock(
  BuildContext context,
  WidgetRef ref,
  Split split,
) async {
  final choice = await showGlassSheet<TrainingBlockChoice>(
    context: context,
    title: 'Training block',
    child: TrainingBlockSheet(split: split),
  );
  if (choice == null) return;

  final repository = ref.read(trainingPlanRepositoryProvider);
  if (choice.isOff) {
    await repository.clearTrainingBlock(split.id);
  } else {
    await repository.setTrainingBlock(
      split.id,
      blockWeeks: choice.blockWeeks!,
      deloadPercent: choice.deloadPercent!,
      startedAt: choice.startedAt!,
    );
  }
}

/// What the block sheet hands back: a block to save, or "no block".
class TrainingBlockChoice {
  const TrainingBlockChoice.block({
    required int this.blockWeeks,
    required double this.deloadPercent,
    required DateTime this.startedAt,
  });

  const TrainingBlockChoice.off()
    : blockWeeks = null,
      deloadPercent = null,
      startedAt = null;

  final int? blockWeeks;
  final double? deloadPercent;
  final DateTime? startedAt;

  bool get isOff => blockWeeks == null;
}

/// Edits one split's training block. Pops a [TrainingBlockChoice], or nothing
/// when cancelled.
class TrainingBlockSheet extends StatefulWidget {
  const TrainingBlockSheet({super.key, required this.split});

  final Split split;

  @override
  State<TrainingBlockSheet> createState() => _TrainingBlockSheetState();
}

class _TrainingBlockSheetState extends State<TrainingBlockSheet> {
  late bool _enabled = widget.split.blockWeeks != null;
  late int _weeks = (widget.split.blockWeeks ?? _defaultBlockWeeks).clamp(
    1,
    maxBlockWeeks,
  );
  late double _deload = deloadPercentFor(widget.split);

  /// Today for a new block: "start a block" almost always means "from now".
  late DateTime _startedAt = dateOnly(
    widget.split.blockStartedAt ?? clock.now(),
  );

  List<double> get _deloadOptions =>
      {..._deloadChoices, _deload}.toList()..sort();

  Future<void> _pickStart() async {
    final today = dateOnly(clock.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _startedAt,
      // A year back covers "I started this block a while ago and forgot to
      // tell the app"; a month ahead covers "next block starts Monday".
      firstDate: DateTime(today.year - 1, today.month, today.day),
      lastDate: DateTime(today.year, today.month, today.day + 28),
      helpText: 'Week 1 began on',
    );
    if (picked != null) setState(() => _startedAt = dateOnly(picked));
  }

  void _save() {
    Navigator.of(context).pop(
      _enabled
          ? TrainingBlockChoice.block(
              blockWeeks: _weeks,
              deloadPercent: _deload,
              startedAt: _startedAt,
            )
          : const TrainingBlockChoice.off(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Train for a set number of weeks, then take one lighter deload '
            'week, then start again. During the deload week the suggested '
            'weights drop to the deload load.',
            style: muted,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Run in training blocks'),
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          if (_enabled) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Training weeks',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove),
                  tooltip: 'Fewer weeks',
                  onPressed: _weeks > 1 ? () => setState(() => _weeks--) : null,
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    _weeks == 1 ? '1 week' : '$_weeks weeks',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'More weeks',
                  onPressed: _weeks < maxBlockWeeks
                      ? () => setState(() => _weeks++)
                      : null,
                ),
              ],
            ),
            Text('then 1 deload week', style: muted),
            const SizedBox(height: 16),
            Text('Deload load', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final percent in _deloadOptions)
                  AppChip(
                    label: formatPercent(percent),
                    selected: _deload == percent,
                    onTap: () => setState(() => _deload = percent),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text('of your usual working weights', style: muted),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Week 1 began'),
              subtitle: Text(_preview()),
              trailing: TextButton(
                onPressed: _pickStart,
                child: Text(formatShortDate(_startedAt)),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ],
      ),
    );
  }

  /// Where today falls under the settings as they stand in the sheet, so the
  /// effect of moving the start date is visible before saving.
  String _preview() {
    final week = trainingBlockWeek(
      blockWeeks: _weeks,
      startedAt: _startedAt,
      on: clock.now(),
    );
    if (week == null) return 'Starts ${formatShortDate(_startedAt)}';
    return 'Today: ${blockWeekLabel(week)}';
  }
}

/// "Week 2 of 4", or "Deload week".
String blockWeekLabel(TrainingBlockWeek week) {
  return week.isDeload
      ? 'Deload week'
      : 'Week ${week.week} of ${week.blockWeeks}';
}

/// The line under a split's title saying which week of the block this is.
///
/// Renders nothing for a split without a block, or one whose block starts in
/// the future — there is no week to report yet, and the action in the app bar
/// is where the block is set up.
class TrainingBlockBanner extends ConsumerWidget {
  const TrainingBlockBanner({super.key, required this.split});

  final Split split;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = trainingBlockWeekForSplit(split, clock.now());
    if (week == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final deload = formatPercent(deloadPercentFor(split));
    final weeksToDeload = week.blockWeeks - week.week + 1;

    final detail = week.isDeload
        ? 'Suggested weights at $deload. A new block starts next week.'
        : weeksToDeload == 1
        ? 'Deload week at $deload next week · block ${week.cycle}'
        : 'Deload at $deload in $weeksToDeload weeks · block ${week.cycle}';

    return AppCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      outlined: true,
      onTap: () => editTrainingBlock(context, ref, split),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                week.isDeload ? Icons.trending_down : Icons.event_repeat,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  blockWeekLabel(week),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          // One segment per week of the cycle, the last one the deload: where
          // you are reads at a glance, before the words do.
          Row(
            children: [
              for (var i = 1; i <= week.blockWeeks + 1; i++) ...[
                if (i > 1) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= week.week
                          ? accent.withValues(
                              alpha: i > week.blockWeeks ? 0.5 : 1,
                            )
                          : theme.colorScheme.onSurface.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
