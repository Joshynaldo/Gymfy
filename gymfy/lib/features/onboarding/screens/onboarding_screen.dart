import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/data/body_profile.dart';
import '../../../shared/data/lifter_sex.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/accent_swatch.dart';
import '../../../shared/widgets/app_picker.dart';
import '../../../shared/widgets/weight_wheel.dart';
import '../../overload/widgets/overload_settings.dart';
import '../data/onboarding_repository.dart';

/// First-launch setup: name, bodyweight, progressive overload, accent colour.
///
/// Shown instead of the app until it's finished. Every answer is skippable —
/// nothing here is needed to log a workout, and a wall of required fields is a
/// bad first impression. The screens that genuinely need a number (strength
/// ranks need a bodyweight) already ask for it themselves.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  final _name = TextEditingController();

  /// Bodyweight in the *display* unit. Zero means "skipped" — the page says
  /// bodyweight is optional, and a wheel always has some value under it, so
  /// leaving it at the bottom has to mean the same as leaving a field blank.
  double _weight = 0;

  /// The lifter's sex, or null for skipped / "rather not say".
  LifterSex? _sex;

  /// Height in centimetres and age in years, or null for skipped.
  int? _heightCm;
  int? _age;

  /// Which page is showing, so the buttons and dots can follow along.
  int _page = 0;

  /// Guards the finish button against a double tap while the writes run.
  bool _saving = false;

  static const _lastPage = 3;

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    super.dispose();
  }

  void _next() {
    FocusScope.of(context).unfocus();
    _pages.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _back() {
    FocusScope.of(context).unfocus();
    _pages.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    // No navigation afterwards: finishing flips onboardingCompleteProvider,
    // and the app root swaps this screen out for the router.
    await ref
        .read(onboardingRepositoryProvider)
        .finish(
          name: _name.text,
          // Picked in whichever unit the page was showing; stored as kilograms.
          bodyweightKg: _weight <= 0
              ? null
              : weightToKilograms(_weight, ref.read(weightUnitProvider)),
          sex: _sex,
          heightCm: _heightCm,
          birthYear: _age == null ? null : birthYearForAge(_age!),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _NamePage(
                    controller: _name,
                    sex: _sex,
                    onSexChanged: (value) => setState(() => _sex = value),
                  ),
                  _BodyweightPage(
                    weight: _weight,
                    onChanged: (value) => _weight = value,
                    heightCm: _heightCm,
                    onHeightChanged: (value) =>
                        setState(() => _heightCm = value),
                    age: _age,
                    onAgeChanged: (value) => setState(() => _age = value),
                  ),
                  const _OverloadPage(),
                  const _AccentPage(),
                ],
              ),
            ),
            _Dots(count: _lastPage + 1, current: _page, accent: accent),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  // Holds the row's shape steady so "Next" doesn't jump sideways
                  // when Back appears on the second page.
                  SizedBox(
                    width: 88,
                    child: _page == 0
                        ? null
                        : TextButton(
                            onPressed: _saving ? null : _back,
                            child: const Text('Back'),
                          ),
                  ),
                  const Spacer(),
                  if (_page == _lastPage)
                    FilledButton(
                      onPressed: _saving ? null : _finish,
                      child: Text(_saving ? 'Saving…' : 'Start lifting'),
                    )
                  else
                    FilledButton(onPressed: _next, child: const Text('Next')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'You can change any of this later in Settings.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared layout for a step, so every page reads as one flow.
class _Step extends StatelessWidget {
  const _Step({required this.title, required this.body, required this.child});

  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}

class _NamePage extends StatelessWidget {
  const _NamePage({
    required this.controller,
    required this.sex,
    required this.onSexChanged,
  });

  final TextEditingController controller;

  /// Null until answered, and answering stays optional.
  final LifterSex? sex;
  final ValueChanged<LifterSex?> onSexChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _Step(
      title: 'Welcome to Gymfy',
      body:
          'Everything you log stays on this phone — there is no account and '
          'nothing gets uploaded. What should we call you?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Your name',
              hintText: 'Optional',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Body diagram and strength standards',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            // Says what it is *for*, because that's the only reason it is
            // asked. Strength standards genuinely differ by sex — a 1.0×
            // bodyweight bench is intermediate for men and advanced for women
            // — and the muscle map ships two different anatomical drawings.
            'Picks which body the muscle map draws, and which strength table '
            'your lifts are compared against. Optional — skip it and the app '
            'works the same, minus the ranks.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<LifterSex?>(
            segments: [
              for (final option in LifterSex.values)
                ButtonSegment(value: option, label: Text(option.label)),
              // An explicit way out, so skipping is a choice you can see rather
              // than the absence of one. Without it the only way past is to
              // leave a control untouched, which reads as an unanswered
              // question rather than a declined one.
              const ButtonSegment(value: null, label: Text('Rather not say')),
            ],
            selected: {sex},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => onSexChanged(selection.first),
          ),
        ],
      ),
    );
  }
}

/// Bodyweight, plus the unit picker.
///
/// The unit belongs on this page rather than a page of its own: this is the
/// first weight the user ever types, and reading "180" as kilograms when they
/// meant pounds would put a wrong bodyweight behind every strength rank. Picking
/// it here also sets the app-wide preference, so the rest of the app is right
/// from the first screen.
class _BodyweightPage extends ConsumerWidget {
  const _BodyweightPage({
    required this.weight,
    required this.onChanged,
    required this.heightCm,
    required this.onHeightChanged,
    required this.age,
    required this.onAgeChanged,
  });

  /// In the display unit; zero means skipped.
  final double weight;
  final ValueChanged<double> onChanged;

  /// Null until given — the same "skipped" the other answers use.
  final int? heightCm;
  final ValueChanged<int?> onHeightChanged;

  final int? age;
  final ValueChanged<int?> onAgeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(weightUnitProvider);

    return _Step(
      title: 'How much do you weigh?',
      body:
          'Used to rank your lifts against your own bodyweight, and it becomes '
          'the first point on your weight chart. Leave it at zero to skip — '
          'nothing else depends on it.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const SizedBox(height: 16),
          WeightWheel(
            // Keyed on the unit so switching kg/lbs above rebuilds the drums
            // with that unit's steps and range, rather than keeping kilogram
            // quarters on a pound wheel.
            key: ValueKey(unit),
            initialWeight: weight,
            unit: unit,
            label: 'Bodyweight',
            onChanged: onChanged,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppPickerField(
                  icon: Icons.height,
                  label: 'Height',
                  value: heightCm == null
                      ? 'Skip'
                      : formatHeight(heightCm!, unit),
                  onTap: () async {
                    final picked = await showNumberPicker(
                      context: context,
                      title: 'How tall are you?',
                      min: minHeightCm,
                      max: maxHeightCm,
                      initial: heightCm ?? 175,
                      format: (cm) => formatHeight(cm, unit),
                    );
                    if (picked != null) onHeightChanged(picked);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppPickerField(
                  icon: Icons.cake_outlined,
                  label: 'Age',
                  value: age == null ? 'Skip' : '$age',
                  onTap: () async {
                    final picked = await showNumberPicker(
                      context: context,
                      title: 'How old are you?',
                      min: minAge,
                      max: maxAge,
                      initial: age ?? 30,
                      // Stored as a year of birth, so it stays right after
                      // your next birthday.
                      helper:
                          'Kept as your year of birth, so it stays '
                          'correct.',
                    );
                    if (picked != null) onAgeChanged(picked);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The accent picker. Tapping a swatch writes it immediately, so the whole app
/// — including this screen's own buttons and dots — re-themes on the spot. That
/// is the preview, so there is no separate "apply" step and nothing to undo.
/// Progressive overload, on or off.
///
/// Asked here rather than left to be discovered, because it changes what the
/// app does every single session — and asked once for everything rather than
/// per exercise, since it's a decision about how you train, not about a
/// particular lift.
///
/// Writes straight through like the accent picker: there is no "save" step in
/// onboarding, and a switch that only takes effect at the end would be a
/// promise the screen can't show you keeping.
class _OverloadPage extends StatelessWidget {
  const _OverloadPage();

  @override
  Widget build(BuildContext context) {
    return const _Step(
      title: 'Should Gymfy suggest heavier weights?',
      body:
          'When you hit every set at the top of your rep range, the next '
          'session opens with a bit more on the bar. It only ever suggests — '
          'the weight stays yours to change.',
      // The same panel Settings shows, minus the deload option: that's a
      // question about month three, and asking it before workout one would be
      // asking someone to plan a stall they haven't hit yet.
      child: OverloadSettingsPanel(showDeload: false),
    );
  }
}

class _AccentPage extends ConsumerWidget {
  const _AccentPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(accentColorProvider);

    return _Step(
      title: 'Pick your colour',
      body:
          'Drives buttons, highlights and charts across the app. Tap one to try '
          'it — the app changes as you go.',
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final option in AccentPalette.options)
            AccentSwatch(
              color: option,
              selected: option == selected,
              onTap: () =>
                  ref.read(accentColorProvider.notifier).setAccent(option),
            ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.current,
    required this.accent,
  });

  final int count;
  final int current;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: i == current ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == current
                    ? accent
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
      ],
    );
  }
}
