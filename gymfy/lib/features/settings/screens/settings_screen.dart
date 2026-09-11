import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/data/body_profile.dart';
import '../../../shared/data/lifter_sex.dart';
import '../../../shared/data/settings_repository.dart';
import '../../../shared/widgets/app_picker.dart';
import '../../../shared/widgets/accent_swatch.dart';
import '../../../shared/utils/units.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../../overload/widgets/overload_settings.dart';
import '../../plates/widgets/plate_inventory_picker.dart';
import '../../workout/data/rest_timer_repository.dart';
import '../../workout/widgets/rest_length_picker.dart';
import '../data/notification_preferences.dart';
import '../../../shared/widgets/fade_slide_in.dart';
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
    return GlassScaffold(
      appBar: GlassAppBar(title: const Text('Settings')),
      // One animation for the whole screen rather than one per section: a
      // settings list is read top to bottom in a glance, and eight staggered
      // sections would draw the eye down the page instead of letting it land.
      body: (context) => FadeSlideIn(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32) + barInsets(context),
          children: const [
            _SectionHeader('Theme'),
            ThemePicker(),
            Divider(height: 1),
            _SectionHeader('Accent'),
            _AccentPicker(),
            Divider(height: 1),
            _SectionHeader('Units'),
            _UnitPicker(),
            Divider(height: 1),
            _SectionHeader('Plates'),
            PlateInventoryPicker(),
            Divider(height: 1),
            _SectionHeader('Progressive overload'),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: OverloadSettingsPanel(),
            ),
            Divider(height: 1),
            _SectionHeader('You'),
            _NameTile(),
            _LifterSexTile(),
            _BodyProfileTiles(),
            Divider(height: 1),
            _SectionHeader('Rest timer'),
            _RestTimerPreferences(),
            Divider(height: 1),
            _SectionHeader('Data'),
            _ExportTile(),
          ],
        ),
      ),
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
    return ListTile(
      leading: const Icon(Icons.save_alt),
      title: const Text('Export data'),
      subtitle: const Text('Save your whole log as a spreadsheet or JSON'),
      trailing: const Icon(Icons.chevron_right),
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
            'Drives buttons, highlights and charts.',
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
            'Weights are always stored in kilograms, so switching back and '
            'forth never changes what you logged.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
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

    return ListTile(
      leading: const Icon(Icons.person_outline),
      title: const Text('Name'),
      subtitle: Text(name ?? 'Not set'),
      trailing: const Icon(Icons.chevron_right),
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
    return GlassDialog(
      title: const Text('Your name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Leave empty to remove',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
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

    return ListTile(
      leading: const Icon(Icons.timer_outlined),
      title: const Text('Default rest'),
      subtitle: Text('${formatRest(seconds)} between sets'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final chosen = await showRestLengthPicker(
          context,
          current: seconds,
          title: 'Default rest',
        );
        if (chosen == null || chosen == clearRestLength) return;
        await setDefaultRest(ref, chosen);
      },
    );
  }
}

/// Rest timer alert preferences.
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

    return Column(
      children: [
        const _DefaultRestTile(),
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: const Text('Rest timer notifications'),
          subtitle: const Text(
            'Show the countdown in the notification shade and alert you when '
            'it runs out',
          ),
          value: alerts,
          onChanged: (value) => setFlag(ref, restTimerAlertsSetting, value),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.vibration),
          title: const Text('Vibrate'),
          subtitle: const Text('Useful with the phone in a pocket'),
          value: vibrate,
          onChanged: alerts
              ? (value) => setFlag(ref, restTimerVibrateSetting, value)
              : null,
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
class _LifterSexTile extends ConsumerWidget {
  const _LifterSexTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sex = ref.watch(lifterSexProvider).value;

    return ListTile(
      leading: const Icon(Icons.accessibility_new),
      title: const Text('Body diagram'),
      subtitle: Text(
        sex == null
            // Named as the consequence rather than as "not set": the map is
            // drawing something either way, and this says which.
            ? 'Not set — showing the male diagram, no strength ranks'
            : '${sex.label} diagram and strength standards',
      ),
      trailing: SegmentedButton<LifterSex?>(
        segments: [
          for (final option in LifterSex.values)
            ButtonSegment(value: option, label: Text(option.label)),
        ],
        selected: {sex},
        emptySelectionAllowed: true,
        showSelectedIcon: false,
        onSelectionChanged: (selection) => ref
            .read(settingsRepositoryProvider)
            .write(lifterSexSetting, selection.first!.name),
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

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.height),
          title: const Text('Height'),
          subtitle: Text(
            height == null ? 'Not set' : formatHeight(height, unit),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final picked = await showNumberPicker(
              context: context,
              title: 'How tall are you?',
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
          leading: const Icon(Icons.cake_outlined),
          title: const Text('Age'),
          subtitle: Text(age == null ? 'Not set' : '$age'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final picked = await showNumberPicker(
              context: context,
              title: 'How old are you?',
              min: minAge,
              max: maxAge,
              initial: age ?? 30,
              helper: 'Kept as your year of birth, so it stays correct.',
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
