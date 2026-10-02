import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../app/theme/glass.dart';
import '../../../app/theme/motion.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/pressable.dart';
import '../data/personal_records.dart';

/// A record's value as it reads on screen, in the record's own unit.
///
/// In [l10n]'s language when given ("12 Wdh.", "102,5 kg"), else English.
String formatRecordValue(
  RecordKind kind,
  double value,
  WeightUnit unit, {
  AppLocalizations? l10n,
}) {
  return switch (kind) {
    RecordKind.weight ||
    RecordKind.oneRm ||
    RecordKind.volume => formatWeightUnit(value, unit, l10n: l10n),
    RecordKind.reps => (l10n ?? englishLocalizations).workoutReps(
      value.round(),
    ),
    RecordKind.hold => formatSetDuration(value.round()),
  };
}

/// "Heaviest weight · 102.5 kg, was 100 kg".
String describeRecord(
  BrokenRecord record,
  WeightUnit unit, {
  AppLocalizations? l10n,
}) {
  final strings = l10n ?? englishLocalizations;
  return strings.workoutRecordLine(
    record.kind.localizedLabel(strings),
    formatRecordValue(record.kind, record.value, unit, l10n: l10n),
    formatRecordValue(record.kind, record.previous, unit, l10n: l10n),
  );
}

/// The moment a set beats your best.
///
/// Shown over the active workout the instant the set is saved, alongside a
/// heavy haptic — the screen is often propped against a rack, and the buzz is
/// what tells you to look. The pane springs in on the emphasis curve, the one
/// the motion vocabulary keeps for moments worth emphasising; with reduced
/// motion it simply appears, because the news matters and the movement does
/// not.
///
/// Says what was beaten and by how much, rather than just "PR!": a number you
/// can read back is the reward, and it is also how you catch a mistyped set
/// that only *looks* like a record.
class RecordCelebration extends ConsumerWidget {
  const RecordCelebration({
    super.key,
    required this.exerciseName,
    required this.records,
    this.onDismiss,
  });

  final String exerciseName;
  final List<BrokenRecord> records;

  /// Tapping the pane dismisses it early. Null for a pane that only waits.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final unit = ref.watch(weightUnitProvider);
    final radius = BorderRadius.circular(20);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: motionOf(context, AppDurations.slow),
      curve: AppCurves.emphasis,
      builder: (context, t, child) => Opacity(
        // The spring overshoots past 1, which an opacity cannot.
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.86 + 0.14 * t, child: child),
      ),
      child: Semantics(
        liveRegion: true,
        child: Pressable(
          borderRadius: radius,
          splash: false,
          onTap: onDismiss,
          child: GlassSurface(
            borderRadius: radius,
            tier: GlassTier.sheet,
            fallbackColor: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 18, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.emoji_events, color: accent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.workoutRecordNew,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          exerciseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        for (final record in records)
                          Text(
                            describeRecord(record, unit, l10n: context.l10n),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The records a finished workout set, for the summary screen.
///
/// Renders nothing when there are none: "0 records" under an ordinary session
/// would read as a verdict on it, and most sessions set none.
class SessionRecordsList extends ConsumerWidget {
  const SessionRecordsList({
    super.key,
    required this.records,
    required this.nameById,
  });

  final List<ExerciseRecords> records;

  /// Exercise names; an id with no name falls back to the id.
  final Map<String, String> nameById;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (records.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final unit = ref.watch(weightUnitProvider);
    final count = records.fold<int>(0, (sum, e) => sum + e.records.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emoji_events, color: accent, size: 20),
            const SizedBox(width: 8),
            Text(
              context.l10n.workoutRecordCount(count),
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final exercise in records)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameById[exercise.exerciseId] ?? exercise.exerciseId,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                for (final record in exercise.records)
                  Text(
                    describeRecord(record, unit, l10n: context.l10n),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
