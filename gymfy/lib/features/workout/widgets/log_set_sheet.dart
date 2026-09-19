import 'dart:async';

import 'package:clock/clock.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
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
///
/// [seconds] is non-null only for a set held rather than counted, and then
/// [reps] is zero. A set is one or the other, never both.
typedef LoggedSetInput = ({
  double weight,
  int reps,
  bool isWarmup,
  int? seconds,
});

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
///
/// [time] stands in for [reps] on an exercise measured in seconds. It is a
/// third *step*, not a mode of the second one: the sheet decides which of the
/// two it needs from the exercise, and the user is never asked to choose.
enum _Step { weight, reps, time }

/// Which half of `m:ss` the keypad is typing into.
enum _TimeField { minutes, seconds }

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

  /// The hold, as the two numbers a person actually thinks in.
  ///
  /// Kept as minutes and seconds rather than as one total, because that is
  /// how they are entered: you pick a field and type into it. Typing the
  /// total in raw seconds meant "three and a half minutes" was 210 — a sum
  /// you have to do in your head, at the end of a hard set, to use a control
  /// whose whole job is to be easier than remembering a number.
  int _minutes = 0;
  int _secondsPart = 0;

  /// Which half of the clock the keypad is filling.
  _TimeField _field = _TimeField.minutes;

  /// Ticks the readout while the work timer runs; null when it is stopped.
  Timer? _ticker;

  /// When the current hold began. Elapsed time is measured from this rather
  /// than counted in ticks: a ticker that misses a beat (and one will, the
  /// moment the screen sleeps or the phone is busy) would quietly under-count
  /// the hold, and the whole point of the timer is that the number is real.
  DateTime? _startedAt;

  bool get _running => _startedAt != null;

  /// The second step for this exercise: time for a plank, reps for a press.
  _Step get _secondStep => widget.exercise.isTimed ? _Step.time : _Step.reps;

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

  /// The hold so far — the running clock while timing, the typed value once
  /// stopped.
  int get _secondsValue => _running
      ? clock.now().difference(_startedAt!).inSeconds
      : _minutes * 60 + _secondsPart;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    HapticFeedback.selectionClick();
    if (_running) {
      // Read the clock once, here, so the stored number is the one that was
      // on screen rather than whatever the next tick would have said.
      final held = clock.now().difference(_startedAt!).inSeconds;
      _ticker?.cancel();
      setState(() {
        _ticker = null;
        _startedAt = null;
        _minutes = held ~/ 60;
        _secondsPart = held % 60;
        // Land on seconds, because a hold you then want to nudge is almost
        // always off by a few of them rather than by whole minutes.
        _field = _TimeField.seconds;
      });
      return;
    }

    setState(() {
      _startedAt = clock.now();
      // One tick a second is all a seconds readout can show. The value is
      // recomputed from the start time on every tick, so a missed beat
      // corrects itself on the next one instead of accumulating.
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    });
  }

  void _key(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_step == _Step.time) {
        final onMinutes = _field == _TimeField.minutes;

        if (key == backspaceKey) {
          if (onMinutes) {
            _minutes ~/= 10;
          } else {
            _secondsPart ~/= 10;
          }
          return;
        }

        final next =
            (onMinutes ? _minutes : _secondsPart) * 10 + int.parse(key);
        if (onMinutes) {
          // Ninety-nine minutes is past any hold anyone logs, and short of a
          // stuck thumb turning a plank into a day.
          if (next > 99) return;
          _minutes = next;
        } else {
          // Refused rather than carried into the minutes. Sixty-one seconds
          // silently becoming 1:01 would be a number the user never typed,
          // and on a field this small the mistake is invisible.
          if (next > 59) return;
          _secondsPart = next;
        }
        return;
      }

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

  void _toSecondStep() {
    HapticFeedback.selectionClick();
    setState(() => _step = _secondStep);
  }

  void _save() {
    final timed = widget.exercise.isTimed;
    // Stop first, so saving mid-hold keeps the time that was on screen
    // instead of discarding it. Tapping Save while the clock runs is the
    // obvious thing to do when the plank ends.
    final held = _secondsValue;

    Navigator.of(context).pop((
      weight: weightToKilograms(_weightValue, widget.unit),
      // One or the other, never both.
      reps: timed ? 0 : _repsValue,
      isWarmup: _warmup,
      seconds: timed ? held : null,
    ));
  }

  void _repeat() {
    final last = widget.repeatable!;
    Navigator.of(context).pop((
      weight: last.weight,
      reps: last.reps,
      isWarmup: _warmup,
      seconds: last.seconds,
    ));
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
              if (_step == _Step.time)
                _TimeReadout(
                  // Split off the live value while running, so the clock
                  // fills both halves as it climbs past a minute.
                  minutes: _running ? _secondsValue ~/ 60 : _minutes,
                  seconds: _running ? _secondsValue % 60 : _secondsPart,
                  field: _field,
                  // Nothing to pick while the clock is running: the value is
                  // the hold, not something being typed.
                  onPick: _running
                      ? null
                      : (field) {
                          HapticFeedback.selectionClick();
                          setState(() => _field = field);
                        },
                  running: _running,
                )
              else
                _Readout(
                  value: _step == _Step.weight
                      ? (_weight.isEmpty ? '0' : _weight)
                      : (_reps.isEmpty ? '—' : _reps),
                  unit: _step == _Step.weight ? widget.unit.label : 'reps',
                  dimmed: _step == _Step.reps && _reps.isEmpty,
                ),
              const SizedBox(height: 8),
              Text(
                switch (_step) {
                  _Step.weight => 'STEP 1 — WEIGHT',
                  _Step.reps => 'STEP 2 — REPS',
                  _Step.time => 'STEP 2 — TIME',
                },
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),

              // While the clock runs there is nothing to type, so the pad
              // makes way for the one control that matters. That keeps this
              // to a single visible input at a time without a mode the user
              // has to manage — the mistake the plate stacker made.
              if (_step == _Step.time) ...[
                _WorkTimerButton(running: _running, onPressed: _toggleTimer),
                if (!_running) ...[
                  const SizedBox(height: 14),
                  _Keypad(withDecimal: false, onKey: _key),
                ],
              ] else
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
                    label: onWeight
                        ? (widget.exercise.isTimed
                              ? 'Next: time'
                              : 'Next: reps')
                        : 'Save set',
                    icon: onWeight ? Icons.chevron_right : Icons.check,
                    // The chevron points at the step after this one; the tick
                    // describes the tap itself.
                    iconAfter: onWeight,
                    height: 52,
                    // The template saved the set on the first digit of the rep
                    // count. That is one tap quicker and makes twelve reps
                    // impossible to log, on an app whose own targets read
                    // "6–8" and "12–15" — so this asks for the tap.
                    //
                    // A timed set saves on any hold longer than nothing,
                    // including one still running: ending the plank and
                    // reaching for Save is the natural move, and refusing it
                    // until you also tapped Stop would be a second dead end.
                    onPressed: switch (_step) {
                      // Blank passes on a timed exercise. Most holds carry no
                      // load at all, and requiring a deliberate "0" would add
                      // a meaningless tap to every plank you ever log — on a
                      // sheet whose whole point is being two taps. On a lift
                      // counted in reps the weight is the content, so there
                      // it still has to be said.
                      _Step.weight =>
                        widget.exercise.isTimed ||
                                _weightValue > 0 ||
                                _weight.isNotEmpty
                            ? _toSecondStep
                            : null,
                      _Step.reps => _repsValue > 0 ? _save : null,
                      _Step.time => _secondsValue > 0 ? _save : null,
                    },
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

/// `3:30` as two things you can tap, rather than one number to work out.
///
/// Minutes and seconds are entered separately because that is how people hold
/// a duration in their heads. Typing the total in raw seconds meant "three
/// and a half minutes" was 210 — arithmetic, at the end of a hard set, to use
/// a control whose whole purpose is to save you remembering a number.
///
/// The selected half is underlined in the accent rather than boxed: this sits
/// at 66px, and a box around a character that size is a slab. The colon stays
/// neutral and untappable — it belongs to neither field, and making it a
/// target would put a dead zone between the two live ones.
class _TimeReadout extends ConsumerWidget {
  const _TimeReadout({
    required this.minutes,
    required this.seconds,
    required this.field,
    required this.onPick,
    required this.running,
  });

  final int minutes;
  final int seconds;
  final _TimeField field;

  /// Null while the clock runs, which disables picking.
  final ValueChanged<_TimeField>? onPick;

  final bool running;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final muted = theme.colorScheme.onSurfaceVariant;

    final digits = theme.textTheme.displayMedium?.copyWith(
      fontSize: 66,
      height: 1,
      fontWeight: FontWeight.w600,
      letterSpacing: -2.5,
      // Tabular, so the pair does not shuffle sideways as digits land under
      // your thumb — and so the colon stays put while the clock runs.
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    Widget half(_TimeField which, String text, String label) {
      final selected = !running && field == which;
      return Pressable(
        borderRadius: BorderRadius.circular(10),
        splash: false,
        haptic: false,
        onTap: onPick == null ? null : () => onPick!(which),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                // Keyed so a test can read one half without the keypad's own
                // digits answering to the same finder — there is a "0" key
                // on screen at the same time as a "0" in the clock.
                key: ValueKey('time-${which.name}'),
                style: digits?.copyWith(
                  color: running || selected ? null : muted,
                ),
              ),
              const SizedBox(height: 6),
              // The label doubles as the selection indicator: it brightens
              // and gains a rule under it. Two signals, one element, so the
              // readout does not grow furniture it only sometimes needs.
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? accent : muted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: motionOf(context, AppDurations.quick),
                curve: AppCurves.settle,
                height: 2,
                width: selected ? 26 : 0,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        half(_TimeField.minutes, '$minutes', running ? 'HOLDING' : 'MIN'),
        Padding(
          // Nudged up so the colon sits on the digits' centre line rather
          // than on the baseline of the labels underneath them.
          padding: const EdgeInsets.only(top: 2),
          child: Text(':', style: digits?.copyWith(color: muted)),
        ),
        half(
          _TimeField.seconds,
          seconds.toString().padLeft(2, '0'),
          running ? '' : 'SEC',
        ),
      ],
    );
  }
}

/// Starts and stops the hold.
///
/// The reason timed exercises are worth building rather than just letting
/// people type a number: nobody counts a plank accurately while holding one,
/// and the phone is already in front of you. One target, the width of the
/// sheet, because it is pressed with a shaking hand at the end of a set.
class _WorkTimerButton extends StatelessWidget {
  const _WorkTimerButton({required this.running, required this.onPressed});

  final bool running;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: running ? 'Stop' : 'Start timer',
      icon: running ? Icons.stop_rounded : Icons.play_arrow_rounded,
      // Stopping is the destructive-looking half only in the sense that it
      // ends something; it is still the primary action while running, since
      // it is the one thing you will reach for.
      kind: running ? AppButtonKind.secondary : AppButtonKind.primary,
      height: 52,
      onPressed: onPressed,
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
