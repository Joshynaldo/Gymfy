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
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/accent_color.dart';
import '../../../l10n/l10n.dart';
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
        LucideIcons.calendarSync,
        color: hasBlock ? ref.watch(accentColorProvider) : null,
      ),
      tooltip: context.l10n.programsBlockTitle,
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
    title: context.l10n.programsBlockTitle,
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
      helpText: context.l10n.programsBlockPickerHelp,
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
    final l10n = context.l10n;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.programsBlockIntro, style: muted),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.programsBlockSwitch),
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          if (_enabled) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.programsBlockWeeksLabel,
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.minus),
                  tooltip: l10n.programsBlockFewerWeeks,
                  onPressed: _weeks > 1 ? () => setState(() => _weeks--) : null,
                ),
                // Wide enough for "10 Wochen", and scaled down rather than
                // wrapped past that: a two-line count between the buttons
                // would push them apart every time the number changed.
                SizedBox(
                  width: 84,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.programsBlockWeeks(_weeks),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.plus),
                  tooltip: l10n.programsBlockMoreWeeks,
                  onPressed: _weeks < maxBlockWeeks
                      ? () => setState(() => _weeks++)
                      : null,
                ),
              ],
            ),
            Text(l10n.programsBlockThenDeload, style: muted),
            const SizedBox(height: 16),
            Text(
              l10n.programsBlockDeloadLoad,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final percent in _deloadOptions)
                  AppChip(
                    label: formatPercent(percent, l10n: l10n),
                    selected: _deload == percent,
                    onTap: () => setState(() => _deload = percent),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(l10n.programsBlockOfWorkingWeights, style: muted),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.programsBlockWeekOneBegan),
              subtitle: Text(_preview(l10n)),
              trailing: TextButton(
                onPressed: _pickStart,
                child: Text(formatShortDate(_startedAt, l10n: l10n)),
              ),
            ),
          ],
          const SizedBox(height: 8),
          // An OverflowBar, like a dialog's actions: side by side while they
          // fit, stacked when a longer language or a large text size makes
          // them not.
          OverflowBar(
            alignment: MainAxisAlignment.end,
            overflowAlignment: OverflowBarAlignment.end,
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(onPressed: _save, child: Text(l10n.commonSave)),
            ],
          ),
        ],
      ),
    );
  }

  /// Where today falls under the settings as they stand in the sheet, so the
  /// effect of moving the start date is visible before saving.
  String _preview(AppLocalizations l10n) {
    final week = trainingBlockWeek(
      blockWeeks: _weeks,
      startedAt: _startedAt,
      on: clock.now(),
    );
    if (week == null) {
      return l10n.programsBlockStarts(formatShortDate(_startedAt, l10n: l10n));
    }
    return l10n.programsBlockToday(blockWeekLabel(week, l10n: l10n));
  }
}

/// "Week 2 of 4", or "Deload week". In [l10n]'s language when given.
String blockWeekLabel(TrainingBlockWeek week, {AppLocalizations? l10n}) {
  final strings = l10n ?? englishLocalizations;
  return week.isDeload
      ? strings.programsBlockDeloadWeek
      : strings.programsBlockWeekOf(week.week, week.blockWeeks);
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
    final l10n = context.l10n;
    final accent = ref.watch(accentColorProvider);
    final deload = formatPercent(deloadPercentFor(split), l10n: l10n);
    final weeksToDeload = week.blockWeeks - week.week + 1;

    final detail = week.isDeload
        ? l10n.programsBlockBannerDeload(deload)
        : weeksToDeload == 1
        ? l10n.programsBlockBannerNextWeek(deload, week.cycle)
        : l10n.programsBlockBannerInWeeks(deload, weeksToDeload, week.cycle);

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
                week.isDeload
                    ? LucideIcons.trendingDown
                    : LucideIcons.calendarSync,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  blockWeekLabel(week, l10n: l10n),
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
