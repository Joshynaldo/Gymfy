// A gallery of the app's chrome and input controls, with no database behind it.
//
//   flutter run -d windows -t lib/design_preview.dart
//   flutter build web -t lib/design_preview.dart
//
// Not part of the app — nothing imports it and it ships in no build. It exists
// because visual work was being done blind: the only feedback on four rounds of
// "polish" was whether it compiled, which is not a process that converges on
// something that looks good.
//
// Every widget here is the real one. That rule was learned the hard way: an
// earlier version fed the accent into the theme but not into the provider the
// controls actually read, so the preview showed purple panes with blue wheels —
// a combination the app cannot produce — and the design was judged on it.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router/scaffold_with_nav_bar.dart';
import 'app/theme/accent_color.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/glass.dart';
import 'app/theme/hyper_backdrop.dart';
import 'features/overload/data/overload_math.dart';
import 'features/workout/data/rest_timer_controller.dart';
import 'features/workout/widgets/log_set_sheet.dart';
import 'features/workout/widgets/rest_timer_bar.dart';
import 'shared/database/app_database.dart' show Exercise;
import 'shared/utils/units.dart';
import 'shared/widgets/animated_count.dart';
import 'shared/widgets/app_card.dart';
import 'shared/widgets/app_picker.dart';
import 'shared/widgets/glass_app_bar.dart';
import 'shared/widgets/glass_dialog.dart';
import 'shared/widgets/glass_nav_bar.dart';
import 'shared/widgets/glass_scaffold.dart';
import 'shared/widgets/number_wheel.dart';
import 'shared/widgets/weight_wheel.dart';

void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();

  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  AppTheme _theme = AppTheme.hyper;
  Color _accent = const Color(0xFF7C6BFF);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      // The accent is fed through the *provider*, not just into the theme —
      // see the note at the top of the file.
      overrides: [
        storedAccentProvider.overrideWith((ref) => Stream.value(_accent)),
        storedWeightUnitProvider.overrideWith((ref) => Stream.value(null)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(_theme, _accent),
        // A phone's status bar and gesture inset, faked. Without this the
        // harness renders a device that does not exist: the app bar came out
        // ~44px shorter than it is on any real phone, and the bar is exactly
        // the thing whose height was being judged. Same lesson as the accent —
        // a harness you are using to judge a design has to be honest about the
        // conditions the design ships in.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 44, bottom: 24),
            viewPadding: const EdgeInsets.only(top: 44, bottom: 24),
          ),
          child: HyperBackdrop(child: child!),
        ),
        home: _Shell(
          theme: _theme,
          onTheme: (value) => setState(() => _theme = value),
          accent: _accent,
          onAccent: (value) => setState(() => _accent = value),
        ),
      ),
    );
  }
}

/// The app's chrome around the gallery: real app bar, real navigation bar.
///
/// The bars are most of what you look at all day and the hardest part to judge
/// from a widget on its own, so the harness wears them.
class _Shell extends StatefulWidget {
  const _Shell({
    required this.theme,
    required this.onTheme,
    required this.accent,
    required this.onAccent,
  });

  final AppTheme theme;
  final ValueChanged<AppTheme> onTheme;
  final Color accent;
  final ValueChanged<Color> onAccent;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The app reaches this through GlassScaffold (behind the app bar) and the
      // navigation shell (behind the pill). The harness has both bars on one
      // Scaffold, so it sets both here — the layout the screens end up with is
      // the same, and it is the layout the gallery has to be judged in.
      extendBodyBehindAppBar: glassOf(context).enabled,
      extendBody: glassOf(context).enabled,
      appBar: const GlassAppBar(title: Text('Input gallery')),
      body: TabTransition(
        index: _tab,
        child: _Gallery(
          theme: widget.theme,
          onTheme: widget.onTheme,
          accent: widget.accent,
          onAccent: widget.onAccent,
        ),
      ),
      bottomNavigationBar: GlassNavBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: mainDestinations,
      ),
    );
  }
}

class _Gallery extends ConsumerStatefulWidget {
  const _Gallery({
    required this.theme,
    required this.onTheme,
    required this.accent,
    required this.onAccent,
  });

  final AppTheme theme;
  final ValueChanged<AppTheme> onTheme;
  final Color accent;
  final ValueChanged<Color> onAccent;

  @override
  ConsumerState<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends ConsumerState<_Gallery> {
  final _sets = FixedExtentScrollController(initialItem: 2);
  final _reps = FixedExtentScrollController(initialItem: 7);
  int _height = 183;
  int _age = 30;
  double _volume = 12450;

  @override
  void dispose() {
    _sets.dispose();
    _reps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 40) + barInsets(context),
      children: [
        // The switches are the point of the harness: these controls have to
        // hold up on every theme and accent, not just the one they were drawn
        // against.
        AppPanel(
          icon: Icons.palette_outlined,
          title: 'Preview against',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<AppTheme>(
                initialValue: widget.theme,
                decoration: const InputDecoration(labelText: 'Theme'),
                items: [
                  for (final option in AppTheme.values)
                    DropdownMenuItem(value: option, child: Text(option.label)),
                ],
                onChanged: (value) =>
                    value == null ? null : widget.onTheme(value),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final option in AccentPalette.options)
                    GestureDetector(
                      onTap: () => widget.onAccent(option),
                      child: CircleAvatar(radius: 14, backgroundColor: option),
                    ),
                ],
              ),
            ],
          ),
        ),

        const AppSectionHeader(title: 'Motion'),
        AppTile(
          icon: Icons.open_in_new,
          title: 'Push a screen',
          subtitle: 'The transition every route in the app uses',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const _PushedScreen()),
          ),
        ),
        AppTile(
          icon: Icons.chat_bubble_outline,
          title: 'Open a dialog',
          subtitle: 'The one surface where the blur is unarguable',
          onTap: () => showDialog<void>(
            context: context,
            builder: (context) => GlassDialog(
              title: const Text('Delete this split?'),
              content: const Text(
                'The days and exercises in it go with it. Sessions you have '
                'already logged are kept.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ),
        ),
        AppPanel(
          icon: Icons.speed,
          title: 'Counting',
          subtitle: 'Tap Change — the number travels rather than jumps.',
          trailing: FilledButton(
            onPressed: () => setState(() => _volume = 6000 + _volume % 9000),
            child: const Text('Change'),
          ),
          child: AnimatedCount(
            value: _volume,
            format: (value) => '${value.round()} kg',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        const AppSectionHeader(title: 'Logging a set'),
        AppTile(
          icon: Icons.dialpad,
          title: 'Log a set',
          subtitle: 'The sheet and keypad the workout screen opens',
          onTap: () => showLogSetSheet(
            context: context,
            exercise: _previewExercise,
            isWarmup: false,
            initialWeight: 102.5,
            initialReps: 8,
            unit: WeightUnit.kg,
            phaseLabel: 'Set 3 · working set',
            suggestion: const OverloadSuggestion(
              weight: 102.5,
              reason: OverloadReason.earned,
            ),
          ),
        ),
        // Two nested scopes rather than one: the pane reads the timer from a
        // provider, and the only honest way to show both of its states is to
        // hand each one a timer of its own.
        const _RestPanePreview(remaining: 67, label: 'Counting down'),
        const _RestPanePreview(remaining: 0, label: 'Rest over'),

        const AppSectionHeader(title: 'Sets & reps wheels'),
        AppPanel(
          child: Row(
            children: [
              Expanded(
                child: NumberWheel(
                  label: 'Sets',
                  controller: _sets,
                  itemCount: 15,
                  labelAt: (i) => '${i + 1}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NumberWheel(
                  label: 'Reps',
                  controller: _reps,
                  itemCount: 50,
                  labelAt: (i) => '${i + 1}',
                ),
              ),
            ],
          ),
        ),

        const AppSectionHeader(title: 'Weight wheel'),
        AppPanel(
          child: WeightWheel(
            initialWeight: 82.5,
            unit: WeightUnit.kg,
            label: 'Bodyweight',
            onChanged: (_) {},
          ),
        ),

        const AppSectionHeader(title: 'Picker fields'),
        AppPanel(
          child: Column(
            children: [
              AppPickerField(
                icon: Icons.height,
                label: 'Height',
                value: formatHeightPreview(_height),
                onTap: () async {
                  final picked = await showNumberPicker(
                    context: context,
                    title: 'How tall are you?',
                    min: 120,
                    max: 230,
                    initial: _height,
                    format: formatHeightPreview,
                  );
                  if (picked != null) setState(() => _height = picked);
                },
              ),
              const SizedBox(height: 10),
              AppPickerField(
                icon: Icons.cake_outlined,
                label: 'Age',
                value: '$_age',
                onTap: () async {
                  final picked = await showNumberPicker(
                    context: context,
                    title: 'How old are you?',
                    min: 13,
                    max: 100,
                    initial: _age,
                    helper: 'Kept as your year of birth.',
                  );
                  if (picked != null) setState(() => _age = picked);
                },
              ),
              const SizedBox(height: 10),
              AppPickerField(
                icon: Icons.fitness_center,
                label: 'Bar',
                value: '20 kg',
                onTap: () => showOptionPicker<int>(
                  context: context,
                  title: 'Bar',
                  selected: 20,
                  options: const [
                    (value: 20, label: '20 kg', subtitle: null),
                    (value: 15, label: '15 kg', subtitle: null),
                    (value: 0, label: 'None', subtitle: 'Plates only'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Somewhere to go, so the page transition has something to transition to.
class _PushedScreen extends StatelessWidget {
  const _PushedScreen();

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: const GlassAppBar(title: Text('Pushed screen')),
      body: (context) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 8) + barInsets(context),
        children: [
          for (var i = 0; i < 8; i++)
            AppTile(
              icon: Icons.fitness_center,
              title: 'Row ${i + 1}',
              subtitle: 'Press and hold to feel the surface give',
              onTap: () {},
            ),
        ],
      ),
    );
  }
}

/// Height for the gallery only — the real one lives in `body_profile.dart` and
/// needs the unit setting this harness does not load.
String formatHeightPreview(int cm) => '$cm cm';

/// A stand-in exercise for the sheet demo.
///
/// A real [Exercise] row rather than a lookalike: the sheet asks it whether it
/// is plate-loaded, and a preview that answers that question differently from
/// the database is a preview of a screen the app cannot produce.
final _previewExercise = Exercise(
  id: 'barbell_bench_press',
  name: 'Barbell bench press',
  muscleIds: const ['chest', 'front_deltoid', 'triceps'],
  isPlateLoaded: true,
  isCustom: false,
  isArchived: false,
);

/// The rest pane with a timer that does not tick.
///
/// The real [RestTimerBar] reading a real provider — only the countdown behind
/// it is held still, so both of its states can be looked at side by side
/// instead of waited for.
class _RestPanePreview extends StatelessWidget {
  const _RestPanePreview({required this.remaining, required this.label});

  final int remaining;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: ProviderScope(
        overrides: [
          restTimerProvider.overrideWith(() => _StillTimer(remaining)),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 6),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const RestTimerBar(),
          ],
        ),
      ),
    );
  }
}

class _StillTimer extends RestTimer {
  _StillTimer(this.remaining);

  final int remaining;

  @override
  RestTimerState? build() => (
    exerciseId: 'barbell_bench_press',
    exerciseName: 'Barbell bench press',
    totalSeconds: 150,
    remainingSeconds: remaining,
  );
}
