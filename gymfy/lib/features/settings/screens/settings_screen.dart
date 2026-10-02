import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/accent_color.dart';
import '../../../l10n/app_language.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/data/body_profile.dart';
import '../../../shared/data/lifter_sex.dart';
import '../../../shared/data/settings_repository.dart';
import '../../../shared/widgets/app_picker.dart';
import '../../../shared/widgets/accent_swatch.dart';
import '../../../shared/utils/units.dart';
import '../../health_connect/data/health_connect_bridge.dart';
import '../../health_connect/widgets/health_connect_settings_panel.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../../overload/widgets/overload_settings.dart';
import '../../plates/widgets/plate_inventory_picker.dart';
import '../../workout/data/rest_timer_repository.dart';
import '../../workout/widgets/logging_settings.dart';
import '../../workout/widgets/rest_length_picker.dart';
import '../../workout_notification/data/workout_notification.dart';
import '../data/notification_preferences.dart';
import '../widgets/theme_picker.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';
import '../../../shared/widgets/glass_dialog.dart';

/// Everything the user can change about the app.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return GlassScaffold(
      appBar: GlassAppBar(title: Text(l10n.settingsTitle)),
      // No entrance of its own. The push already slides and fades this screen
      // in, and a settings list is read top to bottom in a glance — a second
      // animation underneath the first only made the content arrive late and
      // from a different direction. Staggering the sections would be worse
      // still: it draws the eye down the page instead of letting it land.
      body: (context) => ListView(
        padding: const EdgeInsets.only(bottom: 32) + barInsets(context),
        children: [
          _SectionHeader(l10n.settingsSectionTheme),
          const ThemePicker(),
          const Divider(height: 1),
          _SectionHeader(l10n.settingsSectionAccent),
          const _AccentPicker(),
          const Divider(height: 1),
          _SectionHeader(l10n.settingsSectionUnits),
          const _UnitPicker(),
          const Divider(height: 1),
          // Beside the units: both are about where you are rather than how
          // you train.
          _SectionHeader(l10n.settingsSectionLanguage),
          const _LanguageTile(),
          const Divider(height: 1),
          _SectionHeader(l10n.settingsSectionPlates),
          const PlateInventoryPicker(),
          const Divider(height: 1),
          _SectionHeader(l10n.settingsSectionOverload),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: OverloadSettingsPanel(),
          ),
          const Divider(height: 1),
          _SectionHeader(l10n.settingsSectionLogging),
          const LoggingSettingsPanel(),
          const Divider(height: 1),
          _SectionHeader(l10n.settingsSectionYou),
          const _NameTile(),
          const _LifterSexTile(),
          const _BodyProfileTiles(),
          const Divider(height: 1),
          _SectionHeader(l10n.settingsSectionRestTimer),
          const _RestTimerPreferences(),
          const Divider(height: 1),
          _SectionHeader(l10n.settingsSectionData),
          const _BackupTile(),
          const _ExportTile(),
          const _HealthConnectSection(),
        ],
      ),
    );
  }
}

/// Health Connect, last so it never pushes anything above it around, and only
/// on Android — elsewhere there is no Health Connect to describe.
class _HealthConnectSection extends StatelessWidget {
  const _HealthConnectSection();

  @override
  Widget build(BuildContext context) {
    if (!HealthConnectBridge.supported) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        _SectionHeader(context.l10n.settingsSectionHealthConnect),
        const HealthConnectSettingsPanel(),
      ],
    );
  }
}

/// Way in to backup & restore. Above the export because it is the one most
/// people moving phones actually need: the export can't be imported back.
class _BackupTile extends StatelessWidget {
  const _BackupTile();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      leading: const Icon(LucideIcons.archiveRestore),
      title: Text(l10n.settingsBackupTitle),
      subtitle: Text(l10n.settingsBackupSubtitle),
      trailing: const Icon(LucideIcons.chevronRight),
      onTap: () => context.go('/more/settings/backup'),
    );
  }
}

/// Way out to the data export.
///
/// In Settings rather than on the More tab: exporting is something you do once
/// before switching phones or when you want your numbers in a spreadsheet, not
/// a tool you reach for mid-session like the plate calculator.
class _ExportTile extends StatelessWidget {
  const _ExportTile();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      leading: const Icon(LucideIcons.download),
      title: Text(l10n.settingsExportTitle),
      subtitle: Text(l10n.settingsExportSubtitle),
      trailing: const Icon(LucideIcons.chevronRight),
      onTap: () => context.go('/more/settings/export'),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// The accent picker. Same widget as onboarding uses, and the same immediate
/// apply — there is no save button because there is nothing to save later.
class _AccentPicker extends ConsumerWidget {
  const _AccentPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = ref.watch(accentColorProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.settingsAccentCaption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              // The six house colours, plus the current one if a theme
              // suggested something outside them — otherwise the row would
              // show nothing selected and look broken.
              for (final option in {...AccentPalette.options, selected})
                AccentSwatch(
                  color: option,
                  selected: option == selected,
                  onTap: () =>
                      ref.read(accentColorProvider.notifier).setAccent(option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chooses the unit weights are shown and entered in.
///
/// Deliberately says out loud that nothing is converted in the database. This is
/// the one setting a user might reasonably fear touching — "will this mangle two
/// years of logs?" — and the answer is no, so the screen should say so.
class _UnitPicker extends ConsumerWidget {
  const _UnitPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<WeightUnit>(
            segments: [
              for (final option in WeightUnit.values)
                ButtonSegment(value: option, label: Text(option.label)),
            ],
            selected: {unit},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                setWeightUnit(ref, selection.first),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.settingsUnitsCaption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The language the app is shown in: the phone's, or one picked here.
///
/// A row that opens a sheet rather than a segmented button: three options
/// with "System default" among them don't fit across a phone in German, and
/// the sheet has room to say what "system default" currently resolves to.
/// Applies the moment it is picked, like the theme — the screen it is on
/// re-renders in the new language under your finger.
class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(appLanguageProvider);
    final phone = AppLanguage.endonymFor(
      resolveSystemLocale(View.of(context).platformDispatcher.locales),
    );

    String labelOf(AppLanguage language) => switch (language.locale) {
      null => l10n.settingsLanguageSystem,
      final locale => AppLanguage.endonymFor(locale),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(LucideIcons.languages),
          title: Text(l10n.settingsLanguageTitle),
          subtitle: Text(labelOf(current)),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () async {
            final chosen = await showOptionPicker<AppLanguage>(
              context: context,
              title: l10n.settingsLanguageTitle,
              selected: current,
              options: [
                for (final language in AppLanguage.values)
                  (
                    value: language,
                    label: labelOf(language),
                    subtitle: language == AppLanguage.system
                        ? l10n.settingsLanguageSystemSubtitle(phone)
                        : null,
                  ),
              ],
            );
            if (chosen != null) await setAppLanguage(ref, chosen);
          },
        ),
        // Said once, here, so nobody files the English exercise names as a
        // missed translation: the library is seed data with English names,
        // and those are the words printed on gym equipment anyway.
        if (l10n.localeName != 'en')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              l10n.settingsLanguageExerciseNames,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// Shows the stored name and lets it be changed or cleared.
class _NameTile extends ConsumerWidget {
  const _NameTile();

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    String? current,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NameDialog(initial: current ?? ''),
    );

    // Null means cancelled, which is different from an empty string — that is
    // an explicit "remove my name".
    if (name == null) return;
    final settings = ref.read(settingsRepositoryProvider);
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      await settings.clear(userNameSetting);
    } else {
      await settings.write(userNameSetting, trimmed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userNameProvider).value;

    final l10n = context.l10n;
    return ListTile(
      leading: const Icon(LucideIcons.user),
      title: Text(l10n.settingsNameTitle),
      subtitle: Text(name ?? l10n.commonNotSet),
      trailing: const Icon(LucideIcons.chevronRight),
      onTap: () => _edit(context, ref, name),
    );
  }
}

/// Asks for a new name, returning it, or null if the user cancelled.
///
/// A StatefulWidget purely so the dialog owns its controller and disposes it
/// when it is really gone. Creating the controller outside and disposing it as
/// soon as `showDialog` returns tears it out from under the TextField, which is
/// still on screen for the dismiss animation.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GlassDialog(
      title: Text(l10n.settingsNameDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          hintText: l10n.settingsNameDialogHint,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

/// The rest length used by every exercise that hasn't been given its own.
///
/// Per-exercise overrides are set on the exercise's own screen, where you can
/// see which exercise you're changing — a list of every exercise here would be
/// a worse version of the exercise library.
class _DefaultRestTile extends ConsumerWidget {
  const _DefaultRestTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seconds = ref.watch(defaultRestProvider).value ?? defaultRestSeconds;
    final l10n = context.l10n;

    return ListTile(
      leading: const Icon(LucideIcons.timer),
      title: Text(l10n.settingsDefaultRestTitle),
      subtitle: Text(l10n.settingsDefaultRestSubtitle(formatRest(seconds))),
      trailing: const Icon(LucideIcons.chevronRight),
      onTap: () async {
        final chosen = await showRestLengthPicker(
          context,
          current: seconds,
          title: l10n.settingsDefaultRestTitle,
        );
        if (chosen == null || chosen == clearRestLength) return;
        await setDefaultRest(ref, chosen);
      },
    );
  }
}

/// Rest timer alert preferences, and the ongoing workout notification.
///
/// Stored here and read by the rest timer itself, which is the next thing built.
/// Vibration is nested under alerts because it has no meaning on its own — with
/// alerts off there is nothing to vibrate for, so the switch disables rather
/// than silently doing nothing.
class _RestTimerPreferences extends ConsumerWidget {
  const _RestTimerPreferences();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(restTimerAlertsProvider).value ?? true;
    final vibrate = ref.watch(restTimerVibrateProvider).value ?? true;
    final workout = ref.watch(workoutNotificationProvider).value ?? true;
    final l10n = context.l10n;

    return Column(
      children: [
        const _DefaultRestTile(),
        SwitchListTile(
          secondary: const Icon(LucideIcons.bell),
          title: Text(l10n.settingsRestAlertsTitle),
          subtitle: Text(l10n.settingsRestAlertsSubtitle),
          value: alerts,
          onChanged: (value) => setFlag(ref, restTimerAlertsSetting, value),
        ),
        SwitchListTile(
          secondary: const Icon(LucideIcons.vibrate),
          title: Text(l10n.settingsVibrateTitle),
          subtitle: Text(l10n.settingsVibrateSubtitle),
          value: vibrate,
          onChanged: alerts
              ? (value) => setFlag(ref, restTimerVibrateSetting, value)
              : null,
        ),
        // Beside the rest switches because it takes over part of their job:
        // while it is up, the rest countdown is drawn inside it, and the
        // first switch above only decides the alert at the end. Independent
        // of them otherwise — it is about the workout, not the rest. Android
        // only, so nowhere else offers a switch that does nothing.
        if (WorkoutNotificationBridge.supported)
          SwitchListTile(
            secondary: const Icon(LucideIcons.dumbbell),
            title: Text(l10n.settingsWorkoutNotificationTitle),
            subtitle: Text(l10n.settingsWorkoutNotificationSubtitle),
            value: workout,
            onChanged: (value) =>
                setFlag(ref, workoutNotificationSetting, value),
          ),
      ],
    );
  }
}

/// Which body diagram the muscle map draws, and which strength table ranks
/// your lifts.
///
/// Asked during onboarding, but changeable here — and it has to be, because
/// every install that predates the onboarding question has it unset, and
/// because "rather not say" is an answer someone may want to revise.
///
/// The choice sits under the text rather than beside it. As a trailing
/// widget it took whatever width "Male | Female" needed, and in German at a
/// larger text size "Männlich | Weiblich" needed the whole row.
class _LifterSexTile extends ConsumerWidget {
  const _LifterSexTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sex = ref.watch(lifterSexProvider).value;
    final l10n = context.l10n;

    return ListTile(
      leading: const Icon(LucideIcons.personStanding),
      title: Text(l10n.settingsBodyDiagramTitle),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sex == null
                // Named as the consequence rather than as "not set": the map
                // is drawing something either way, and this says which.
                ? l10n.settingsBodyDiagramNotSet
                // One whole sentence per sex rather than the label spliced
                // in: German declines the adjective ("Weibliches Diagramm").
                : l10n.settingsBodyDiagramSubtitle(sex.name),
          ),
          const SizedBox(height: 8),
          SegmentedButton<LifterSex?>(
            segments: [
              for (final option in LifterSex.values)
                ButtonSegment(
                  value: option,
                  label: Text(option.localizedLabel(l10n)),
                ),
            ],
            selected: {sex},
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            onSelectionChanged: (selection) => ref
                .read(settingsRepositoryProvider)
                .write(lifterSexSetting, selection.first!.name),
          ),
        ],
      ),
    );
  }
}

/// Height and age — the two body facts that aren't measurements.
///
/// Here rather than on the Measurements screen because neither is something you
/// re-measure: your height is your height, and an age that needs logging over
/// time is a birthday, not a data point. Both are asked once during onboarding
/// and this is where they get corrected.
class _BodyProfileTiles extends ConsumerWidget {
  const _BodyProfileTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(weightUnitProvider);
    final height = ref.watch(heightCmProvider).value;
    final age = ref.watch(ageProvider);
    final settings = ref.read(settingsRepositoryProvider);
    final l10n = context.l10n;

    return Column(
      children: [
        ListTile(
          leading: const Icon(LucideIcons.ruler),
          title: Text(l10n.bodyProfileHeightLabel),
          subtitle: Text(
            height == null ? l10n.commonNotSet : formatHeight(height, unit),
          ),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () async {
            final picked = await showNumberPicker(
              context: context,
              title: l10n.bodyProfileHeightQuestion,
              min: minHeightCm,
              max: maxHeightCm,
              initial: height ?? 175,
              format: (cm) => formatHeight(cm, unit),
            );
            if (picked != null) {
              await settings.write(heightCmSetting, '$picked');
            }
          },
        ),
        ListTile(
          leading: const Icon(LucideIcons.cake),
          title: Text(l10n.bodyProfileAgeLabel),
          subtitle: Text(age == null ? l10n.commonNotSet : '$age'),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () async {
            final picked = await showNumberPicker(
              context: context,
              title: l10n.bodyProfileAgeQuestion,
              min: minAge,
              max: maxAge,
              initial: age ?? 30,
              helper: l10n.bodyProfileAgeHelper,
            );
            if (picked != null) {
              // Stored as a year, never as an age: "31" would be wrong on the
              // next birthday and nothing would ever fix it.
              await settings.write(
                birthYearSetting,
                '${birthYearForAge(picked)}',
              );
            }
          },
        ),
      ],
    );
  }
}
