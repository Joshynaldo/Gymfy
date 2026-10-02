import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/glass.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/utils/weekday.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_segmented.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../data/csv_reader.dart';
import '../data/import_format.dart';
import '../data/import_plan.dart';
import '../data/import_repository.dart';
import '../../../shared/widgets/lucide_icons.dart';

/// Bringing a training history in from another app.
///
/// Three steps on one screen, because the middle one is the reason the screen
/// exists: pick a file, **look at what it says**, then import. Writing a
/// couple of years of somebody's training straight off a file picker with no
/// confirmation is the kind of thing you only get to do to a person once.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  /// The parsed file, once one has been picked and understood.
  WorkoutImport? _preview;

  /// How many of its sessions the device already has.
  int _alreadyHere = 0;

  /// How many look like workouts already here without matching exactly — the
  /// same session logged in two apps while switching between them.
  int _nearDuplicates = 0;

  /// The split the file's workout names would make, worked out for the preview
  /// so it can be shown before anything is written.
  List<PlannedDay> _plan = const [];

  /// Whether to build that split as well as the history.
  ///
  /// Set from the file in [_reparse]: on when there is a programme in it and
  /// no split of that name already, off otherwise. A history with no split is
  /// the state people were actually landing in — the year activity filled in,
  /// and nothing to press start on — so the offer is made by default, but it
  /// is made in the open, with every day it would create listed below.
  bool _buildSplit = false;

  /// The days of that split the user has kept.
  ///
  /// By name, because that is what identifies a [PlannedDay] and what
  /// [ImportRepository.createSplitFrom] filters on.
  Set<String> _chosenDays = const {};

  /// Whether a split of this file's name is already on the device.
  bool _splitExists = false;

  /// What the user says the file's weights are in, used only when the file
  /// does not say. Defaults to their own unit, which is the better guess than
  /// kilograms: someone who set the app to pounds trains in pounds.
  WeightUnit? _assumed;

  /// The raw text, kept so changing the assumed unit can re-read it without
  /// asking for the file again.
  String? _source;

  String? _error;
  ImportOutcome? _outcome;

  /// The split that was built, when one was asked for. Null when it wasn't,
  /// or when the file named no workouts to build one from.
  PlanOutcome? _planOutcome;

  /// Set when the history went in but the split did not — a different thing
  /// from the whole import failing, and the user has to be told which.
  String? _splitFailure;

  bool _busy = false;

  /// The strings for messages set after an await, when the widget may be
  /// gone; every caller checks [mounted] before showing one.
  AppLocalizations get _l10n => mounted ? context.l10n : englishLocalizations;

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await FilePicker.pickFile();
      // Backing out of the file dialog changes nothing. Clearing the outcome
      // up front instead would wipe the receipt for the import just made —
      // including the only line saying where the new split went — for someone
      // who opened the picker and thought better of it.
      if (file == null) return;

      setState(() {
        _outcome = null;
        _planOutcome = null;
        _splitFailure = null;
      });

      final source = utf8.decode(await file.readAsBytes());
      _source = source;
      _assumed ??= ref.read(weightUnitProvider);
      await _reparse();
    } on CsvException catch (error) {
      _fail(error.describe(_l10n));
    } on ImportFormatException catch (error) {
      _fail(error.describe(_l10n));
    } on FormatException {
      // utf8.decode on something that isn't text at all.
      _fail(_l10n.importErrorNotText);
    } catch (error) {
      _fail(_l10n.importErrorReadFailed('$error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Re-reads the held text. Called again when the assumed unit changes.
  Future<void> _reparse() async {
    final source = _source;
    if (source == null) return;

    final parsed = parseWorkoutCsv(
      source,
      assumedUnit: _assumed ?? WeightUnit.kg,
      untitledName: _l10n.importUntitledWorkout,
    );
    final repository = ref.read(importRepositoryProvider);
    final already = await repository.countAlreadyHere(parsed);
    final near = await repository.countNearDuplicates(parsed);
    final plan = planForImport(parsed);
    final splitName = defaultSplitName(parsed.source, l10n: _l10n);
    final exists = plan.isEmpty
        ? false
        : await repository.hasSplitNamed(splitName);
    if (!mounted) return;
    setState(() {
      _preview = parsed;
      _alreadyHere = already;
      _nearDuplicates = near;
      _plan = plan;
      _splitExists = exists;
      // Ticked to begin with: the days the file says are a programme, not the
      // ones it happens to have a name for. StrengthLog titles an untitled
      // workout after the clock, so a real export offered thirteen days of
      // which eight were one improvised session each — all-or-nothing meant
      // the only way to avoid them was to build no split at all.
      _chosenDays = {
        for (final day in plan)
          if (day.sessionCount > 1) day.name,
      };
      // And off entirely when this split has been built before, so importing
      // the same file twice — the documented reason people re-import — does
      // not quietly leave two identical splits in the switcher.
      _buildSplit = !exists && _chosenDays.isNotEmpty;
      _error = null;
    });
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _preview = null;
      _source = null;
      _plan = const [];
      _error = message;
    });
  }

  Future<void> _import() async {
    final preview = _preview;
    if (preview == null) return;

    setState(() => _busy = true);
    ImportOutcome? outcome;
    try {
      final repository = ref.read(importRepositoryProvider);
      outcome = await repository.apply(preview);

      // After the history, and in its own transaction: a split that fails to
      // build should not take a year of training down with it.
      final plan = _buildSplit && _chosenDays.isNotEmpty
          ? await repository.createSplitFrom(
              preview,
              // The name the preview showed, in the language it showed it.
              name: defaultSplitName(preview.source, l10n: _l10n),
              only: _chosenDays,
            )
          : null;

      if (!mounted) return;
      setState(() {
        _outcome = outcome;
        _planOutcome = plan;
        _splitFailure = null;
        _preview = null;
        _source = null;
        _plan = const [];
      });
    } catch (error) {
      if (!mounted) return;
      // Which half failed decides what the user is told. Losing the history
      // means nothing was written; losing only the split means a year of
      // training *is* on the device, and reporting that as "could not import
      // that file" would send someone off to import it a second time.
      setState(() {
        if (outcome == null) {
          _preview = null;
          _source = null;
          _plan = const [];
          _error = _l10n.importErrorImportFailed('$error');
        } else {
          _outcome = outcome;
          _planOutcome = null;
          _splitFailure = _l10n.importErrorSplitFailed('$error');
          _preview = null;
          _source = null;
          _plan = const [];
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preview = _preview;
    final outcome = _outcome;

    // New workouts, or a split that isn't here yet. The second half matters:
    // someone who already imported this file and now wants the split it
    // describes would otherwise be looking at a disabled button, because every
    // workout in it is already on the phone.
    final incoming = preview == null
        ? 0
        : preview.sessions.length - _alreadyHere;
    final willBuildSplit = _buildSplit && _plan.isNotEmpty;
    final canImport = incoming > 0 || willBuildSplit;

    return GlassScaffold(
      appBar: GlassAppBar(title: Text(l10n.importTitle)),
      body: (context) => ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 24) + barInsets(context),
        children: [
          const _Explainer(),
          if (_error != null) _ErrorPanel(message: _error!),
          if (outcome != null)
            _OutcomePanel(outcome: outcome, plan: _planOutcome),
          if (_splitFailure != null) _ErrorPanel(message: _splitFailure!),
          if (preview != null) ...[
            _PreviewPanel(
              preview: preview,
              alreadyHere: _alreadyHere,
              nearDuplicates: _nearDuplicates,
            ),
            if (_plan.isNotEmpty)
              _PlanPanel(
                plan: _plan,
                splitName: defaultSplitName(preview.source, l10n: l10n),
                alreadyExists: _splitExists,
                enabled: _buildSplit,
                chosen: _chosenDays,
                onChanged: (value) => setState(() => _buildSplit = value),
                onDayChanged: (name, keep) => setState(() {
                  final next = {..._chosenDays};
                  keep ? next.add(name) : next.remove(name);
                  _chosenDays = next;
                }),
              ),
            if (!preview.unitWasStated)
              _UnitPanel(
                unit: _assumed ?? WeightUnit.kg,
                // Busy for the whole re-read. The two database round-trips in
                // _reparse take long enough to tap Import in between, and
                // doing so would have written the *previous* parse — every
                // weight in the file off by a factor of 2.2, with the screen
                // showing the unit the user had just chosen.
                onChanged: _busy
                    ? null
                    : (unit) async {
                        setState(() {
                          _assumed = unit;
                          _busy = true;
                        });
                        try {
                          await _reparse();
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
              ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: AppButton(
              label: preview == null
                  ? l10n.importChooseFile
                  : l10n.importChooseAnother,
              icon: LucideIcons.folderOpen,
              kind: preview == null
                  ? AppButtonKind.primary
                  : AppButtonKind.secondary,
              onPressed: _busy ? null : _pick,
            ),
          ),
          if (preview != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: AppButton(
                // The numbers are on the button because this is the one action
                // here that changes data the user cannot see on screen.
                label: _busy
                    ? l10n.importImporting
                    : _importLabel(
                        incoming,
                        willBuildSplit ? _plan.length : 0,
                        l10n,
                      ),
                icon: LucideIcons.download,
                onPressed: _busy || !canImport ? null : _import,
              ),
            ),
        ],
      ),
    );
  }
}

/// What the import button promises.
///
/// Spelled out rather than left as "Import", because the two halves are
/// independent: a file can add eighty workouts and no split, a split and no
/// workouts, or both, and the button is the last thing read before a year of
/// training is written.
String _importLabel(int workouts, int days, AppLocalizations l10n) {
  if (workouts > 0 && days > 0) return l10n.importButtonBoth(workouts, days);
  if (workouts > 0) return l10n.importButtonWorkouts(workouts);
  if (days > 0) return l10n.importButtonSplit(days);
  return l10n.importButton;
}

class _Explainer extends StatelessWidget {
  const _Explainer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return AppPanel(
      icon: LucideIcons.inbox,
      title: l10n.importExplainerTitle,
      child: Text(
        l10n.importExplainerMessage,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );
  }
}

/// What the file turned out to contain, before anything is written.
class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.preview,
    required this.alreadyHere,
    required this.nearDuplicates,
  });

  final WorkoutImport preview;
  final int alreadyHere;
  final int nearDuplicates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final sessions = preview.sessions;
    final incoming = sessions.length - alreadyHere;

    if (sessions.isEmpty) {
      // Naming the date is the whole point of this branch. The one time this
      // panel appeared on a real file, every row had been dropped for an
      // unreadable date and the message below talked about reps and weights —
      // so it read as "your export is empty" and there was nothing to act on.
      final dates = preview.skippedNoDate;
      final sample = preview.unreadableDate;

      return AppPanel(
        icon: LucideIcons.circleHelp,
        title: l10n.importNothingTitle,
        child: SelectableText(
          dates > 0 && sample != null
              ? l10n.importNothingUnreadableDates(dates, sample)
              : l10n.importNothingNoSets,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      );
    }

    return AppPanel(
      icon: LucideIcons.listChecks,
      title: l10n.importPreviewTitle,
      // Naming the app is reassurance at the one moment it is worth
      // something: just before committing a year of training on the strength
      // of a preview. Recognition only — the import does not depend on it.
      subtitle: preview.source == null
          ? null
          : l10n.importPreviewSource(preview.source!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Line(l10n.importPreviewWorkouts, '${sessions.length}'),
          _Line(l10n.importPreviewSets, '${preview.setCount}'),
          _Line(l10n.importPreviewExercises, '${preview.exerciseNames.length}'),
          _Line(
            l10n.importPreviewFrom,
            formatDate(sessions.first.start, l10n: l10n),
          ),
          _Line(
            l10n.importPreviewTo,
            formatDate(sessions.last.start, l10n: l10n),
          ),
          if (alreadyHere > 0)
            _Line(
              l10n.importAlreadyHere,
              l10n.importPreviewWillSkip(alreadyHere),
            ),
          if (preview.skippedRows > 0)
            _Line(l10n.importPreviewNotSets, '${preview.skippedRows}'),
          if (preview.skippedNoDate > 0 && preview.unreadableDate != null) ...[
            const SizedBox(height: 10),
            SelectableText(
              // Shown on a *partial* import, not only on an empty one. A file
              // whose dates are readable for ten months and not for two would
              // otherwise import silently short, with the missing weeks
              // counted under "rows that were not sets" — which names the
              // wrong cause and hides the only fact that could fix it.
              l10n.importPreviewDatesSkipped(
                preview.skippedNoDate,
                preview.unreadableDate!,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            incoming == 0
                ? l10n.importPreviewAllHere
                : l10n.importPreviewWillAdd(incoming),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (nearDuplicates > 0) ...[
            const SizedBox(height: 10),
            Text(
              // Said before the import rather than after, because afterwards
              // the only fix is deleting them one at a time. Someone moving
              // between apps logs the same session in both for a while, and
              // the two exports disagree by a minute — enough that the
              // skip-what-is-already-here rule does not catch them.
              l10n.importPreviewNearDuplicates(nearDuplicates),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The split the file's workout names would make, and the switch to build it.
///
/// Listed day by day rather than summarised as "8 days", because this is the
/// part of an import the user has an opinion about: "Push — 3 workouts, 7
/// exercises" is checkable at a glance against what they know they train, and
/// a wrong-looking row is the cue to turn the switch off.
class _PlanPanel extends StatelessWidget {
  const _PlanPanel({
    required this.plan,
    required this.splitName,
    required this.alreadyExists,
    required this.enabled,
    required this.chosen,
    required this.onChanged,
    required this.onDayChanged,
  });

  final List<PlannedDay> plan;
  final String splitName;

  /// Whether a split of this name is already on the device.
  final bool alreadyExists;

  final bool enabled;
  final Set<String> chosen;
  final ValueChanged<bool> onChanged;
  final void Function(String name, bool keep) onDayChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return AppPanel(
      icon: LucideIcons.calendarDays,
      title: l10n.importPlanTitle,
      subtitle: enabled ? l10n.importPlanWillBeCalled(splitName) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.importPlanExplainer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (alreadyExists) ...[
            const SizedBox(height: 10),
            Text(
              // Said rather than silently prevented: a second split is a
              // reasonable thing to want, being handed one unasked is not.
              // The two would be indistinguishable in the split switcher,
              // which lists them by name.
              l10n.importPlanExists(splitName),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                height: 1.4,
              ),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.importPlanCreate),
            value: enabled,
            onChanged: onChanged,
          ),
          if (enabled)
            for (final day in plan)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                value: chosen.contains(day.name),
                onChanged: (keep) => onDayChanged(day.name, keep ?? false),
                title: Text(
                  day.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // The workout count is what separates a programme from an
                // accident. StrengthLog names an untitled workout after the
                // clock, so "Saturday Evening: Machine Shoulder Press — 1
                // workout" reads as the one-off it is next to "Push — 7".
                subtitle: Text(_dayLine(day, l10n)),
              ),
        ],
      ),
    );
  }
}

/// The line under a day in the plan panel: how often, how much, and when.
String _dayLine(PlannedDay day, AppLocalizations l10n) {
  final parts = [
    l10n.importPlanDayWorkouts(day.sessionCount),
    l10n.importPlanDayExercises(day.exercises.length),
    if (day.weekdays.isNotEmpty)
      day.weekdays.map((d) => weekdayShort(d, l10n: l10n)).join(', '),
  ];
  return parts.join(' · ');
}

/// Only shown when the file does not say what unit its weights are in.
class _UnitPanel extends StatelessWidget {
  const _UnitPanel({required this.unit, required this.onChanged});

  final WeightUnit unit;

  /// Null while the file is being re-read, so the control cannot be moved
  /// again before the last change has landed.
  final ValueChanged<WeightUnit>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return AppPanel(
      icon: LucideIcons.scale,
      title: l10n.importUnitTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // Said plainly, because it is the one thing on this screen that
            // cannot be checked afterwards by looking: 100 kg and 100 lbs are
            // both plausible numbers, and the wrong choice rewrites a whole
            // history by a factor of 2.2.
            l10n.importUnitMessage,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          AppSegmented<WeightUnit>(
            segments: [
              (
                value: WeightUnit.kg,
                label: l10n.importUnitKilograms,
                leading: null,
              ),
              (
                value: WeightUnit.lbs,
                label: l10n.importUnitPounds,
                leading: null,
              ),
            ],
            selected: unit,
            // A no-op rather than a disabled control: AppSegmented has no
            // disabled state, and the Import button is already off for the
            // same moment, which is the half that matters.
            onChanged: (value) => onChanged?.call(value),
          ),
        ],
      ),
    );
  }
}

class _OutcomePanel extends StatelessWidget {
  const _OutcomePanel({required this.outcome, this.plan});

  final ImportOutcome outcome;

  /// The split that was built, when one was asked for.
  final PlanOutcome? plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return AppPanel(
      icon: LucideIcons.circleCheck,
      title: l10n.importOutcomeTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Line(l10n.importOutcomeWorkoutsAdded, '${outcome.sessionsAdded}'),
          _Line(l10n.importOutcomeSetsAdded, '${outcome.setsAdded}'),
          if (outcome.sessionsSkipped > 0)
            _Line(
              l10n.importAlreadyHere,
              l10n.importOutcomeSkipped(outcome.sessionsSkipped),
            ),
          if (plan != null) ...[
            _Line(l10n.importOutcomeSplitCreated, plan!.splitName),
            _Line(
              l10n.importOutcomeDays,
              l10n.importOutcomeDaysValue(plan!.days, plan!.exercises),
            ),
            const SizedBox(height: 10),
            Text(
              // Where to find it, because the split list is not on the way
              // back from here and a split nobody can find is not one.
              l10n.importOutcomeFindSplit,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          if (outcome.exercisesCreated.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              // Said rather than hidden, because these rows are incomplete in
              // a way that shows up later: no muscles means they are missing
              // from the muscle map and from every muscle filter.
              l10n.importOutcomeNewExercises(outcome.exercisesCreated.length),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPanel(
      icon: LucideIcons.circleAlert,
      title: context.l10n.importErrorTitle,
      child: SelectableText(
        // Selectable so the header line can be copied out of it. When a file
        // will not load, what its columns are called is the one piece of
        // information that turns this into a fix.
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );
  }
}
