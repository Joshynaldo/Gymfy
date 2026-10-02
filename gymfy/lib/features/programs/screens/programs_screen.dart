import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/weekday.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../overload/data/percent_target.dart';
import '../../plan_share/data/plan_document.dart';
import '../../plan_share/widgets/plan_import_flow.dart';
import '../data/program_catalog.dart';

/// The programme browser: ready-made splits that ship with the app.
///
/// For the person who opens the Workout tab with no idea what to put in it. A
/// blank split and an exercise library is a lot of decisions to make before
/// your first workout; picking a known programme is one.
class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GlassScaffold(
      appBar: GlassAppBar(title: Text(l10n.programsTitle)),
      body: (context) => ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 24) + barInsets(context),
        children: [
          const _Intro(),
          for (final (index, program) in bundledPrograms.indexed)
            FadeSlideIn(
              delay: Duration(milliseconds: 25 * (index > 6 ? 6 : index)),
              child: AppTile(
                icon: Icons.event_note_outlined,
                title: program.name,
                subtitle:
                    '${programFacts(program, l10n: l10n)}\n'
                    '${program.localizedSummary(l10n)}',
                onTap: () => context.go('/workout/programs/${program.id}'),
              ),
            ),
        ],
      ),
    );
  }
}

/// "3 days a week · Beginner" — the two facts that decide whether a programme
/// is worth reading about. In [l10n]'s language when given, else English.
String programFacts(BundledProgram program, {AppLocalizations? l10n}) {
  final strings = l10n ?? englishLocalizations;
  return strings.programsFacts(
    program.daysPerWeek,
    program.level.localizedLabel(strings),
  );
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Text(
        // Says up front that nothing here touches what you already have: the
        // fear with a "load a programme" button is that it replaces yours.
        context.l10n.programsIntro,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// One programme: what it is for, every day and exercise in it, and the button
/// that adds it as a split.
///
/// The whole plan is shown before you commit, read from the same file the
/// import will use — so what you see here is exactly what you get.
class ProgramDetailScreen extends ConsumerStatefulWidget {
  const ProgramDetailScreen({super.key, required this.programId});

  final String programId;

  @override
  ConsumerState<ProgramDetailScreen> createState() =>
      _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends ConsumerState<ProgramDetailScreen> {
  /// True while the import runs, so a double tap can't add the split twice.
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final program = bundledPrograms
        .where((p) => p.id == widget.programId)
        .firstOrNull;

    if (program == null) {
      return GlassScaffold(
        appBar: GlassAppBar(title: Text(l10n.programsFallbackTitle)),
        body: (context) => Center(child: Text(l10n.programsNotFound)),
      );
    }

    final documentAsync = ref.watch(bundledProgramProvider(program.id));

    return GlassScaffold(
      appBar: GlassAppBar(title: Text(program.name)),
      body: (context) => documentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.programsOpenFailed('$error'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (document) => ListView(
          padding:
              const EdgeInsets.fromLTRB(12, 4, 12, 24) + barInsets(context),
          children: [
            AppPanel(
              title: program.name,
              subtitle: programFacts(program, l10n: l10n),
              child: Text(program.localizedDescription(l10n)),
            ),
            const SizedBox(height: 8),
            AppButton(
              label: l10n.programsAddToSplits,
              icon: Icons.add,
              onPressed: _busy ? null : () => _add(program, document),
            ),
            const SizedBox(height: 8),
            for (final split in document.splits)
              for (final day in split.days) _DayPanel(day: day),
          ],
        ),
      ),
    );
  }

  Future<void> _add(BundledProgram program, PlanDocument document) async {
    setState(() => _busy = true);
    final l10n = context.l10n;
    try {
      final messenger = ScaffoldMessenger.of(context);
      final ids = await importPlanDocument(context, ref, document);
      if (!mounted || ids.isEmpty) return;

      messenger.showSnackBar(
        SnackBar(content: Text(l10n.programsAdded(program.name))),
      );
      // Straight to the new split, where "Set active" is — adding a programme
      // and then hunting for it in the split list would be a strange reward.
      context.go('/workout/split/${ids.first}');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.programsAddFailed('$error'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// One day of a programme, with its schedule and exercises.
class _DayPanel extends ConsumerWidget {
  const _DayPanel({required this.day});

  final SharedDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = ref.watch(accentColorProvider);
    final schedule = weekdaySummary(day.weekdays, l10n: l10n);

    return AppPanel(
      title: day.name,
      subtitle: schedule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, exercise) in day.exercises.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A thin accent rule beside superset members, so a pair
                  // reads as one block before you have read either name.
                  Container(
                    width: 3,
                    height: 20,
                    margin: const EdgeInsets.only(right: 10, top: 1),
                    decoration: BoxDecoration(
                      color: _inSuperset(index)
                          ? accent
                          : theme.colorScheme.onSurface.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      exercise.name,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    exerciseTarget(exercise, l10n: l10n),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          if (day.exercises.any((e) => e.supersetGroup != null))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.programsSupersetNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Whether the exercise at [index] shares its superset group with a
  /// neighbour — the same adjacency rule `supersetBlocks` applies.
  bool _inSuperset(int index) {
    final group = day.exercises[index].supersetGroup;
    if (group == null) return false;
    bool sameAt(int i) =>
        i >= 0 &&
        i < day.exercises.length &&
        day.exercises[i].supersetGroup == group;
    return sameAt(index - 1) || sameAt(index + 1);
  }
}

/// "5 × 5 @ 75%", "3 × 8–12" — the target as it reads on a programme sheet.
String exerciseTarget(SharedExercise exercise, {AppLocalizations? l10n}) {
  final target = formatSetTarget(
    exercise.sets,
    exercise.reps,
    exercise.repsMax,
  );
  final percent = exercise.targetPercent;
  return percent == null
      ? target
      : '$target @ ${formatPercent(percent, l10n: l10n)}';
}
