import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/data/settings_repository.dart';
import '../data/rank_inputs.dart';

/// Asks for whatever a strength rank still needs.
///
/// Shown in place of ranks when either input is missing. Two separate asks,
/// because they're answered in different places: sex is a one-tap choice that
/// belongs right here, while bodyweight lives in the measurements screen and
/// this only links there — copying it into a second place would let the two
/// drift apart.
class RankSetupPrompt extends ConsumerWidget {
  const RankSetupPrompt({super.key, required this.inputs});

  final RankInputs inputs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Before we can rank you', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'A rank compares your lifts to your own bodyweight, so it needs two '
          'things from you.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (inputs.sex == null) const _SexPrompt(),
        if (inputs.sex == null && inputs.bodyweightKg == null)
          const SizedBox(height: 12),
        if (inputs.bodyweightKg == null) const _BodyweightPrompt(),
      ],
    );
  }
}

/// The one-tap sex choice, with the reason it's being asked.
class _SexPrompt extends ConsumerWidget {
  const _SexPrompt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return _PromptCard(
      icon: Icons.people_outline,
      title: 'Which standards should we use?',
      // Being explicit about why beats a bare question — this is the sort of
      // field people are (rightly) suspicious of an app asking for.
      body:
          'Published strength standards differ by sex: a bodyweight bench '
          'press is intermediate for men and advanced for women. Picking the '
          'wrong table would just give you a wrong rank.',
      action: Row(
        children: [
          for (final sex in LifterSex.values) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => ref
                    .read(settingsRepositoryProvider)
                    .write(lifterSexSetting, sex.name),
                child: Text(sex.label),
              ),
            ),
            if (sex != LifterSex.values.last) const SizedBox(width: 12),
          ],
        ],
      ),
      theme: theme,
    );
  }
}

/// Sends the user to the measurements screen to log a bodyweight.
class _BodyweightPrompt extends ConsumerWidget {
  const _BodyweightPrompt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return _PromptCard(
      icon: Icons.monitor_weight_outlined,
      title: 'Log your bodyweight',
      body:
          'Ranks are a ratio of what you lift to what you weigh. Add your '
          'weight under Progress → Measurements and it shows up here.',
      action: Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: () => context.go('/progress/measurements'),
          icon: const Icon(Icons.straighten),
          label: const Text('Open measurements'),
        ),
      ),
      theme: theme,
    );
  }
}

/// Shared shell so both asks look like one thing.
class _PromptCard extends ConsumerWidget {
  const _PromptCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.theme,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget action;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          action,
        ],
      ),
    );
  }
}
