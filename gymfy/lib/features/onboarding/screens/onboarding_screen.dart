import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/accent_swatch.dart';
import '../data/onboarding_repository.dart';

/// First-launch setup: name, bodyweight, accent colour.
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
  final _weight = TextEditingController();

  /// Which page is showing, so the buttons and dots can follow along.
  int _page = 0;

  /// Guards the finish button against a double tap while the writes run.
  bool _saving = false;

  static const _lastPage = 2;

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    _weight.dispose();
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
    await ref.read(onboardingRepositoryProvider).finish(
      name: _name.text,
      // Typed in whichever unit the page was showing; stored as kilograms.
      bodyweightKg: parseWeightAsKilograms(
        _weight.text,
        ref.read(weightUnitProvider),
      ),
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
                  _NamePage(controller: _name),
                  _BodyweightPage(controller: _weight),
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

/// Shared layout for a step, so all three read as one flow.
class _Step extends StatelessWidget {
  const _Step({
    required this.title,
    required this.body,
    required this.child,
  });

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
  const _NamePage({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _Step(
      title: 'Welcome to Gymfy',
      body:
          'Everything you log stays on this phone — there is no account and '
          'nothing gets uploaded. What should we call you?',
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: 'Your name',
          hintText: 'Optional',
          border: OutlineInputBorder(),
        ),
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
  const _BodyweightPage({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(weightUnitProvider);

    return _Step(
      title: 'How much do you weigh?',
      body:
          'Used to rank your lifts against your own bodyweight, and it becomes '
          'the first point on your weight chart. Skip it if you would rather '
          'not — nothing else depends on it.',
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
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: 'Bodyweight',
              hintText: 'Optional',
              suffixText: unit.label,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

/// The accent picker. Tapping a swatch writes it immediately, so the whole app
/// — including this screen's own buttons and dots — re-themes on the spot. That
/// is the preview, so there is no separate "apply" step and nothing to undo.
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
