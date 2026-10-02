import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/accent_color.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/utils/dates.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/weight_wheel.dart';
import '../../calculator/data/one_rm_math.dart';
import '../../calculator/data/tested_one_rm_repository.dart';
import '../../exercises/data/exercise_repository.dart';
import '../data/progress_repository.dart';
import '../widgets/exercise_progress_chart.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';
import '../../../shared/widgets/glass_dialog.dart';

/// Shows one exercise's progress over time: personal records, an estimated
/// one-rep max from the best set logged, and a chart of top-set weight per
/// session.
class ExerciseProgressScreen extends ConsumerWidget {
  const ExerciseProgressScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final exerciseAsync = ref.watch(exerciseProvider(exerciseId));
    final historyAsync = ref.watch(exerciseHistoryProvider(exerciseId));
    final title = exerciseAsync.value?.name ?? l10n.progressTitle;

    return GlassScaffold(
      appBar: GlassAppBar(title: Text(title)),
      body: (context) => historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.progressExerciseLoadFailed('$error'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (points) {
          if (points.isEmpty) {
            return Center(child: Text(l10n.progressExerciseNoSessions));
          }
          final records = personalRecordsFrom(points);
          final bestOneRm = bestEstimatedOneRm(points);

          // An exercise logged by time. Everything below that talks about
          // weight has to say something else, or say nothing.
          final holds = points.any((p) => p.isHold);

          return ListView(
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 32) + barInsets(context),
            children: [
              if (records != null) ...[
                Text(
                  l10n.progressExerciseRecords,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _RecordsRow(records: records),
                const SizedBox(height: 24),
              ],
              // No one-rep max on a hold. There is no rep to take a maximum
              // of, and the whole panel — including the "test your 1RM"
              // prompt inside it — would be asking about a number that does
              // not exist for a plank.
              if (!holds) ...[
                _OneRmBadge(exerciseId: exerciseId, best: bestOneRm),
                const SizedBox(height: 24),
              ],
              Text(
                holds
                    ? l10n.progressExerciseLongestHold
                    : l10n.progressExerciseTopSetWeight,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                holds
                    ? l10n.progressExerciseLongestHoldCaption
                    : l10n.progressExerciseTopSetCaption,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 260,
                child: ExerciseProgressChart(points: points),
              ),
              if (points.length == 1) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.progressExerciseTrendHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// What the dialog hands back. A null [weightKg] means "clear it", which is
/// different from the dialog being dismissed (null result).
typedef _TestedInput = ({double? weightKg, DateTime testedOn});

/// The exercise's one-rep max: the one you tested if there is one, otherwise
/// estimated from the best set you've logged. Tap to enter or change a tested
/// max.
///
/// An outline rather than a filled card while it's only an estimate — it sits
/// next to measured PRs and shouldn't look equally solid. A tested max fills
/// the outline in, because that one is a fact.
class _OneRmBadge extends ConsumerWidget {
  const _OneRmBadge({required this.exerciseId, required this.best});

  final String exerciseId;

  /// Derived from logged sets. Null when nothing usable has been logged.
  final BestOneRm? best;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = ref.watch(accentColorProvider);
    final tested = ref.watch(testedOneRmProvider(exerciseId)).value;
    final unit = ref.watch(weightUnitProvider);

    final label = tested != null
        ? l10n.progressOneRmTested
        : l10n.progressOneRmEstimated;
    final value = tested != null
        ? formatWeightUnit(tested.weightKg, unit, l10n: l10n)
        : best != null
        ? '≈ ${formatWeightUnit(best!.oneRm, unit, l10n: l10n)}'
        : '—';

    return InkWell(
      onTap: () => _edit(context, ref, tested),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
          // Filled once it's a tested fact rather than a calculation.
          color: tested != null ? accent.withValues(alpha: 0.12) : null,
        ),
        child: Row(
          children: [
            Icon(
              tested != null ? LucideIcons.trophy : LucideIcons.trendingUp,
              size: 20,
              color: accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        value,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(tested, unit, l10n),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.pencil,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(
    TestedOneRm? tested,
    WeightUnit unit,
    AppLocalizations l10n,
  ) {
    if (tested != null) {
      final date = formatShortDate(tested.testedOn, l10n: l10n);
      // Keep the estimate visible as a second opinion — if your log implies
      // more than your last test, it's time to retest.
      if (best == null) return l10n.progressOneRmTestedOn(date);
      return l10n.progressOneRmTestedOnSuggests(
        date,
        formatWeightUnit(best!.oneRm, unit, l10n: l10n),
      );
    }
    if (best == null) return l10n.progressOneRmTapToEnter;
    final date = formatShortDate(best!.date, l10n: l10n);
    return best!.reps == 1
        ? l10n.progressOneRmSingle(date)
        : l10n.progressOneRmFrom(
            formatWeightUnit(best!.weight, unit, l10n: l10n),
            best!.reps,
            date,
          );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    TestedOneRm? tested,
  ) async {
    final input = await showDialog<_TestedInput>(
      context: context,
      builder: (context) => _TestedOneRmDialog(
        current: tested,
        // Pre-fill with the estimate: it's the best guess at what they just
        // tested, and it saves typing when it's close.
        suggestion: best == null ? null : roundToPlate(best!.oneRm),
        unit: ref.read(weightUnitProvider),
      ),
    );
    if (input == null) return;

    final repository = ref.read(testedOneRmRepositoryProvider);
    if (input.weightKg == null) {
      await repository.clearForExercise(exerciseId);
    } else {
      await repository.setForExercise(
        exerciseId: exerciseId,
        weightKg: input.weightKg!,
        testedOn: input.testedOn,
      );
    }
  }
}

/// Enter (or clear) a tested one-rep max for this exercise.
///
/// Talks to the user in [unit]; everything it hands back is kilograms.
class _TestedOneRmDialog extends StatefulWidget {
  const _TestedOneRmDialog({
    required this.current,
    required this.suggestion,
    required this.unit,
  });

  final TestedOneRm? current;

  /// In kilograms, as stored.
  final double? suggestion;
  final WeightUnit unit;

  @override
  State<_TestedOneRmDialog> createState() => _TestedOneRmDialogState();
}

class _TestedOneRmDialogState extends State<_TestedOneRmDialog> {
  /// The weight in the *display* unit, since that's what the wheel offers.
  /// Rounded on the way in so a prefilled pounds figure isn't a converted
  /// kilogram value with a trailing decimal.
  late double _weight = () {
    final start = widget.current?.weightKg ?? widget.suggestion ?? 0;
    return weightIn(roundToLoadable(start, widget.unit), widget.unit);
  }();

  late DateTime _testedOn =
      widget.current?.testedOn ?? dateOnly(DateTime.now());

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _testedOn,
      firstDate: DateTime(now.year - 5),
      // A max you'll test next week isn't a max you have.
      lastDate: dateOnly(now),
    );
    if (picked != null) setState(() => _testedOn = dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final weight = _weight > 0 ? weightToKilograms(_weight, widget.unit) : null;

    return GlassDialog(
      title: Text(l10n.progressOneRmTested),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WeightWheel(
            initialWeight: _weight,
            unit: widget.unit,
            onChanged: (value) => setState(() => _weight = value),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(LucideIcons.calendar),
            title: Text(formatDayLabel(_testedOn, l10n: l10n)),
            trailing: const Icon(LucideIcons.calendarCog),
            onTap: _pickDate,
          ),
        ],
      ),
      actions: [
        if (widget.current != null)
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pop((weightKg: null, testedOn: _testedOn)),
            child: Text(l10n.progressClear),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          // Disabled rather than silently rejecting an unparseable number.
          onPressed: weight == null
              ? null
              : () => Navigator.of(
                  context,
                ).pop((weightKg: weight, testedOn: _testedOn)),
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

class _RecordsRow extends ConsumerWidget {
  const _RecordsRow({required this.records});

  final PersonalRecords records;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final unit = ref.watch(weightUnitProvider);

    // IntrinsicHeight gives the Row a finite height so the tiles can stretch to
    // match each other; without it, `stretch` inside a scrolling list forces an
    // infinite height and the screen fails to lay out.
    // A hold has different records. "Heaviest 0 kg × 0 reps" under a plank is
    // not a missing feature, it is a wrong statement — and the numbers behind
    // it are real, they are just seconds.
    final hold = records.isHold;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: hold
                ? _RecordTile(
                    icon: LucideIcons.timer,
                    label: l10n.progressExerciseLongestHold,
                    value: formatSetDuration(records.longestHold!),
                    detail: formatShortDate(
                      records.longestHoldDate!,
                      l10n: l10n,
                    ),
                  )
                : _RecordTile(
                    icon: LucideIcons.dumbbell,
                    label: l10n.progressRecordHeaviest,
                    value: formatWeightUnit(
                      records.heaviestWeight,
                      unit,
                      l10n: l10n,
                    ),
                    detail:
                        '× ${records.repsAtHeaviest} '
                        '• ${formatShortDate(records.heaviestDate, l10n: l10n)}',
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _RecordTile(
              icon: LucideIcons.chartColumn,
              label: hold
                  ? l10n.progressRecordMostTime
                  : l10n.progressRecordBestVolume,
              value: hold
                  ? formatSetDuration(records.bestSeconds)
                  : formatWeightUnit(records.bestVolume, unit, l10n: l10n),
              detail: l10n.progressRecordInASession(
                formatShortDate(
                  hold ? records.bestSecondsDate! : records.bestVolumeDate,
                  l10n: l10n,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordTile extends ConsumerWidget {
  const _RecordTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(
            detail,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
