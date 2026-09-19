import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/glass.dart';
import '../../../app/theme/motion.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/utils/units.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_sheet.dart';
import '../../../shared/widgets/pressable.dart';
import '../../overload/data/overload_math.dart';
import '../../plates/widgets/plate_stacker.dart';

/// What a finished trip through the sheet produces.
typedef LoggedSetInput = ({double weight, int reps, bool isWarmup});

/// Asks for the weight and reps of one set.
///
/// A bottom sheet rather than a dialog, and a keypad rather than a text field.
/// Both follow from where this is used: standing at a rack, one-handed, phone
/// propped or held low. A dialog puts its inputs in the middle of the screen
/// where the thumb does not reach, and a text field summons the system keyboard
/// — which is a grid of forty small keys, thirty-eight of which cannot appear
/// in a weight.
///
/// Weights are spoken in [unit] throughout and returned in kilograms, so the
/// screen behind never has to think about which unit is on.
Future<LoggedSetInput?> showLogSetSheet({
  required BuildContext context,
  required Exercise exercise,
  required bool isWarmup,
  required double initialWeight,
  required int initialReps,
  required WeightUnit unit,
  OverloadSuggestion? suggestion,
  String? phaseLabel,
  LoggedSet? repeatable,
}) {
  return showGlassSheet<LoggedSetInput>(
    context: context,
    handle: true,
    child: _LogSetSheet(
      exercise: exercise,
      isWarmup: isWarmup,
      initialWeight: initialWeight,
      initialReps: initialReps,
      unit: unit,
      suggestion: suggestion,
      phaseLabel: phaseLabel,
      repeatable: repeatable,
    ),
  );
}

/// The backspace key's internal label.
///
/// A constant rather than a literal in three places: the pad builds it, the key
/// widget tests for it, and the handler compares against it.
const backspaceKey = 'backspace';

/// Which half of the set is being entered.
enum _Step { weight, reps }

class _LogSetSheet extends ConsumerStatefulWidget {
  const _LogSetSheet({
    required this.exercise,
    required this.isWarmup,
    required this.initialWeight,
    required this.initialReps,
    required this.unit,
    required this.suggestion,
    required this.phaseLabel,
    required this.repeatable,
  });

  final Exercise exercise;
  final bool isWarmup;

  /// In kilograms, as stored.
  final double initialWeight;
  final int initialReps;
  final WeightUnit unit;

  /// Why the weight is prefilled the way it is, when progressive overload had
  /// something to say. Null for the ordinary case.
  final OverloadSuggestion? suggestion;

  /// "Set 3 · working set", or the ramp-up equivalent.
  final String? phaseLabel;

  /// The last set logged in this phase, if there is one — the shortcut that
  /// makes a straight-sets workout two taps a set instead of five.
  final LoggedSet? repeatable;

  @override
  ConsumerState<_LogSetSheet> createState() => _LogSetSheetState();
}

class _LogSetSheetState extends ConsumerState<_LogSetSheet> {
  _Step _step = _Step.weight;
  late bool _warmup = widget.isWarmup;

  /// Both values are held as the text on the display rather than as numbers.
  ///
  /// A keypad edits a string — "10" after one key, "102" after two, "102." on
  /// the way to "102.5" — and a number cannot hold a trailing decimal point or
  /// tell an empty field from a zero.
  late String _weight = _initialWeightText;
  String _reps = '';

  /// Stacking stays available on a barbell exercise: on a bar you know what you
  /// put on it, not what the total came to.
  ///
  /// It is an alternative way to enter the *weight*, not a mode the whole sheet
  /// goes into — see the build method, where it replaces the keypad only while
  /// the weight step is the one showing.
  bool _plates = false;

  String get _initialWeightText =>
      _weightText(weightIn(widget.initialWeight, widget.unit));

  /// A weight, as the readout should spell it.
  ///
  /// Whole numbers lose the ".0" — a pad showing "100.0" invites a tap on the
  /// decimal point that does nothing, and the next digit typed would land after
  /// it and turn 100 into 100.05.
  static String _weightText(double shown) {
    if (shown <= 0) return '';
    return shown == shown.roundToDouble()
        ? shown.round().toString()
        : shown.toString();
  }

  double get _weightValue => double.tryParse(_weight) ?? 0;
  int get _repsValue => int.tryParse(_reps) ?? 0;

  void _key(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_step == _Step.weight) {
        if (key == backspaceKey) {
          _weight = _weight.isEmpty
              ? _weight
              : _weight.substring(0, _weight.length - 1);
          return;
        }
        if (key == '.' && _weight.contains('.')) return;
        if (key == '.' && _weight.isEmpty) {
          _weight = '0.';
          return;
        }
        if (_weight.length >= 6) return;
        _weight += key;
        return;
      }

      if (key == backspaceKey) {
        _reps = _reps.isEmpty ? _reps : _reps.substring(0, _reps.length - 1);
        return;
      }
      // Two digits is every rep count anyone logs. Without the cap a stuck
      // thumb turns eight reps into eight hundred and the set is silently
      // nonsense.
      if (_reps.length >= 2) return;
      if (_reps.isEmpty && key == '0') return;
      _reps += key;
    });
  }

  void _toReps() {
    HapticFeedback.selectionClick();
    setState(() => _step = _Step.reps);
  }

  void _save() {
    Navigator.of(context).pop((
      weight: weightToKilograms(_weightValue, widget.unit),
      reps: _repsValue,
      isWarmup: _warmup,
    ));
  }

  void _repeat() {
    final last = widget.repeatable!;
    Navigator.of(
      context,
    ).pop((weight: last.weight, reps: last.reps, isWarmup: _warmup));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onWeight = _step == _Step.weight;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.exercise.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _warmup
                            ? 'Warm-up · ramping up'
                            : (widget.phaseLabel ?? 'Working set'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // A toggle here rather than two different buttons on the card
                // behind: whether a set was a ramp-up is something you often
                // only decide once the bar is in your hands.
                _WarmupToggle(
                  on: _warmup,
                  onChanged: (value) => setState(() => _warmup = value),
                ),
              ],
            ),

            // Not for warm-ups: the suggestion is a target for the working
            // sets, and putting it on the bar for a ramp-up makes the ramp-up
            // pointless.
            if (widget.suggestion != null && !_warmup) ...[
              const SizedBox(height: 14),
              _SuggestionNote(
                suggestion: widget.suggestion!,
                unit: widget.unit,
              ),
            ],

            const SizedBox(height: 22),

            // The stacker stands in for the keypad on the weight step only.
            // Wiring it as a mode for the whole sheet was the original bug:
            // step two showed the stacker again, there was no way to enter a
            // rep count, and "Save set" stayed disabled — you loaded the bar,
            // tapped through, and nothing was ever written.
            if (_plates && onWeight)
              PlateStacker(
                initialWeight: _weightValue,
                exerciseId: widget.exercise.id,
                // Through `setState`, because this is the value the readout
                // shows the moment you switch back to typing. Spelled the same
                // way the keypad spells it, so the next digit appends to "60"
                // rather than to "60.0".
                onChanged: (weight) =>
                    setState(() => _weight = _weightText(weight)),
              )
            else ...[
              _Readout(
                value: onWeight
                    ? (_weight.isEmpty ? '0' : _weight)
                    : (_reps.isEmpty ? '—' : _reps),
                unit: onWeight ? widget.unit.label : 'reps',
                dimmed: !onWeight && _reps.isEmpty,
              ),
              const SizedBox(height: 8),
              Text(
                onWeight ? 'STEP 1 — WEIGHT' : 'STEP 2 — REPS',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              _Keypad(withDecimal: onWeight, onKey: _key),
            ],

            // Only alongside the weight. On the reps step it would offer to
            // switch an input that is not on screen, and the sheet would grow
            // a control that does nothing visible.
            if (widget.exercise.isPlateLoaded && onWeight) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _plates = !_plates),
                  icon: Icon(
                    _plates ? Icons.dialpad : Icons.donut_large_outlined,
                    size: 18,
                  ),
                  label: Text(_plates ? 'Type a weight' : 'Stack plates'),
                ),
              ),
            ],

            const SizedBox(height: 14),
            Row(
              children: [
                if (widget.repeatable != null) ...[
                  Expanded(
                    child: AppButton(
                      label: 'Repeat last set',
                      kind: AppButtonKind.secondary,
                      height: 52,
                      onPressed: _repeat,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: AppButton(
                    // Two steps, two buttons in one place. The primary action
                    // never moves, so the thumb goes to the same spot twice.
                    label: onWeight ? 'Next: reps' : 'Save set',
                    icon: onWeight ? Icons.chevron_right : Icons.check,
                    // The chevron points at the step after this one; the tick
                    // describes the tap itself.
                    iconAfter: onWeight,
                    height: 52,
                    // The template saved the set on the first digit of the rep
                    // count. That is one tap quicker and makes twelve reps
                    // impossible to log, on an app whose own targets read
                    // "6–8" and "12–15" — so this asks for the tap.
                    onPressed: onWeight
                        ? (_weightValue > 0 || _weight.isNotEmpty
                              ? _toReps
                              : null)
                        : (_repsValue > 0 ? _save : null),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The number being entered, at the size you can read from an arm's length.
class _Readout extends StatelessWidget {
  const _Readout({
    required this.value,
    required this.unit,
    required this.dimmed,
  });

  final String value;
  final String unit;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.displayMedium?.copyWith(
              fontSize: 66,
              height: 1,
              fontWeight: FontWeight.w600,
              letterSpacing: -2.5,
              color: dimmed ? theme.colorScheme.onSurfaceVariant : null,
              // Tabular, so the number does not shuffle sideways as digits
              // land under your thumb.
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          unit,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Twelve keys: the digits, a decimal point while entering a weight, and a
/// backspace.
///
/// 56px tall with 9px between them — comfortably past the 48dp target size, and
/// the whole grid sits in the bottom half of the screen where a thumb reaches
/// without the phone being re-gripped.
class _Keypad extends StatelessWidget {
  const _Keypad({required this.withDecimal, required this.onKey});

  final bool withDecimal;
  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    // The blank holds the grid's shape while entering reps, where a decimal
    // point would be meaningless. Without it the zero and the backspace slide
    // left between the two steps.
    final keys = [
      '1', '2', '3', //
      '4', '5', '6', //
      '7', '8', '9', //
      withDecimal ? '.' : '', '0', backspaceKey, //
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 9,
      crossAxisSpacing: 9,
      childAspectRatio: 2.1,
      children: [
        for (final key in keys)
          key.isEmpty
              ? const SizedBox.shrink()
              : _Key(label: key, onPressed: () => onKey(key)),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(17);

    // Backspace as an icon rather than as the character U+232B. The app's
    // typeface has no glyph for it, so it came out as the browser's
    // last-resort box — which is what a missing glyph always looks like, and
    // exactly the sort of thing that only shows up once it is on a screen.
    if (label == backspaceKey) {
      return Pressable(
        borderRadius: radius,
        onTap: onPressed,
        splash: false,
        child: GlassSurface(
          borderRadius: radius,
          tier: GlassTier.quiet,
          fallbackColor: theme.colorScheme.surfaceContainerHighest,
          child: const Center(child: Icon(Icons.backspace_outlined, size: 21)),
        ),
      );
    }

    return Pressable(
      borderRadius: radius,
      onTap: onPressed,
      splash: false,
      child: GlassSurface(
        borderRadius: radius,
        // A key is a row-weight surface, not a card: twelve of them at card
        // brightness would out-shout the number they are entering.
        tier: GlassTier.quiet,
        fallbackColor: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// The chip that marks this set as a ramp-up.
class _WarmupToggle extends StatelessWidget {
  const _WarmupToggle({required this.on, required this.onChanged});

  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(13);

    return Pressable(
      borderRadius: radius,
      onTap: () => onChanged(!on),
      splash: false,
      child: AnimatedContainer(
        duration: motionOf(context, AppDurations.quick),
        curve: AppCurves.settle,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(
            alpha: on ? 0.16 : 0.05,
          ),
          borderRadius: radius,
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(
              alpha: on ? 0.24 : 0.10,
            ),
          ),
        ),
        child: Text(
          'Warm-up',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: on ? null : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// One line saying where the prefilled weight came from.
///
/// A suggested number with no explanation is either obeyed blindly or ignored;
/// saying why makes it something you can agree or disagree with. The weight
/// stays fully editable either way — the app proposes, it doesn't decide.
class _SuggestionNote extends StatelessWidget {
  const _SuggestionNote({required this.suggestion, required this.unit});

  final OverloadSuggestion suggestion;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (icon, text) = switch (suggestion.reason) {
      OverloadReason.earned => (
        Icons.trending_up,
        'You hit every set last time — going up to '
            '${formatWeightUnit(suggestion.weight, unit)}.',
      ),
      OverloadReason.deload => (
        Icons.trending_down,
        'Several increases in a row. A lighter week at '
            '${formatWeightUnit(suggestion.weight, unit)} is suggested.',
      ),
      _ => (
        Icons.remove,
        "Same weight as last time — the rep target wasn't met yet.",
      ),
    };

    return GlassSurface(
      borderRadius: BorderRadius.circular(15),
      tier: GlassTier.quiet,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
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
