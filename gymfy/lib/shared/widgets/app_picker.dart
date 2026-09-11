import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/accent_color.dart';
import '../../app/theme/glass.dart';
import 'number_wheel.dart';

/// The shared look for "pick a value" controls.
///
/// One component rather than a dropdown here, a wheel there and a segmented
/// button somewhere else. The app had all three doing the same job in different
/// shapes, which is the drift `app_card.dart` was built to end for surfaces —
/// this is the same argument for inputs.
///
/// The closed control is a rounded field showing the label and the current
/// answer; tapping opens a sheet. A sheet rather than a menu because the values
/// here are long lists (fifty reps, a hundred and fifty centimetres) and a
/// dropdown that overflows the screen is worse than one that never opens.
class AppPickerField extends ConsumerWidget {
  const AppPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
    this.enabled = true,
  });

  /// What is being chosen, e.g. "Reps".
  final String label;

  /// The current answer, already formatted.
  final String value;

  final VoidCallback onTap;
  final IconData? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        // `shape` rather than `borderRadius` — Material asserts if given both.
        // The outline is a hairline in the accent, strong enough to read as an
        // edge and no more: without it the field melts into the panel behind
        // it on the flatter themes, and a control whose edge you cannot see
        // does not look tappable.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: accent.withValues(alpha: 0.22)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              children: [
                if (icon != null) ...[
                  // The glyph sits in its own tinted square, the same shape
                  // AppGlyph uses down the left edge of every card list.
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 17, color: accent),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: accent.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One choice in [showOptionPicker].
typedef PickerOption<T> = ({T value, String label, String? subtitle});

/// Asks for one of [options], returning null if dismissed.
///
/// A sheet rather than a `PopupMenuButton`: a menu anchors to the control and
/// can open half off-screen next to something near an edge, and its rows are
/// too tight to hit reliably with a thumb mid-workout.
Future<T?> showOptionPicker<T>({
  required BuildContext context,
  required String title,
  required List<PickerOption<T>> options,
  required T? selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    // The sheet paints nothing itself; _PickerSheet is the surface, and an
    // opaque background here would sit in front of its blur.
    backgroundColor: Colors.transparent,
    builder: (context) => _PickerSheet(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in options)
            _OptionRow(
              option: option,
              selected: option.value == selected,
              onTap: () => Navigator.of(context).pop(option.value),
            ),
        ],
      ),
    ),
  );
}

/// Asks for a number from a scrolling wheel, returning null if dismissed.
///
/// [format] renders each value, so the same wheel serves reps ("12"), height
/// ("180 cm") and a year of birth shown as an age.
Future<int?> showNumberPicker({
  required BuildContext context,
  required String title,
  required int min,
  required int max,
  required int initial,
  String Function(int value)? format,
  String? helper,
}) {
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PickerSheet(
      title: title,
      child: _NumberWheelSheet(
        min: min,
        max: max,
        initial: initial.clamp(min, max),
        format: format ?? (value) => '$value',
        helper: helper,
      ),
    ),
  );
}

/// The shell every picker sheet shares: a title, the content, and safe-area
/// padding so the last row isn't under the gesture bar.
///
/// This is the one place in the app where glass actually earns itself. A
/// blurred, translucent surface only reads as glass when there is something
/// behind it to distort — on a flat dark list it is just a slightly different
/// grey. A sheet sits over the screen you came from, so here the blur has
/// something to do, and the light along its top edge has a reason to be there.
class _PickerSheet extends StatelessWidget {
  const _PickerSheet({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        // A Material rather than a DecoratedBox: the option rows are
        // ListTiles, and they paint their selection tint and ink splashes on
        // the nearest Material ancestor. With a plain coloured box in between,
        // Flutter asserts and the highlight on the chosen row never appears.
        child: Material(
          // Translucent rather than opaque, or the blur behind it would be
          // painted over and the whole effect wasted.
          color: theme.colorScheme.surface.withValues(alpha: 0.82),
          // The edge comes from the material now rather than a hand-picked
          // white. This sheet predates GlassStyle and was carrying its own
          // idea of what a glass edge looks like — which is exactly how two
          // surfaces in one app drift apart.
          shape: Border(top: BorderSide(color: glassOf(context).edge)),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Flexible(child: SingleChildScrollView(child: child)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionRow<T> extends ConsumerWidget {
  const _OptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PickerOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);

    return ListTile(
      title: Text(option.label),
      subtitle: option.subtitle == null ? null : Text(option.subtitle!),
      // A tick only on the chosen row rather than a radio on every one: the
      // question is "which is it", not "here are six switches".
      trailing: selected ? Icon(Icons.check, color: accent) : null,
      selected: selected,
      selectedTileColor: accent.withValues(alpha: 0.10),
      onTap: onTap,
    );
  }
}

/// A single scrolling wheel with a Done button.
class _NumberWheelSheet extends ConsumerStatefulWidget {
  const _NumberWheelSheet({
    required this.min,
    required this.max,
    required this.initial,
    required this.format,
    required this.helper,
  });

  final int min;
  final int max;
  final int initial;
  final String Function(int) format;
  final String? helper;

  @override
  ConsumerState<_NumberWheelSheet> createState() => _NumberWheelSheetState();
}

class _NumberWheelSheetState extends ConsumerState<_NumberWheelSheet> {
  late final _controller = FixedExtentScrollController(
    initialItem: widget.initial - widget.min,
  );
  late int _value = widget.initial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final accent = ref.watch(accentColorProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The chosen value, large, above the drum. The wheel shows it too, but
        // small and among its neighbours — this is the sheet's answer, and it
        // should be readable without picking it out of a column.
        Text(
          widget.format(_value),
          style: theme.textTheme.displaySmall?.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          // The same drum the sets/reps dialog and the weight wheels use, so
          // a wheel behaves identically wherever it turns up.
          child: NumberWheel(
            controller: _controller,
            itemCount: widget.max - widget.min + 1,
            labelAt: (index) => widget.format(widget.min + index),
            height: 180,
            onChanged: (index) => setState(() => _value = widget.min + index),
          ),
        ),
        if (widget.helper != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              widget.helper!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_value),
              child: const Text('Done'),
            ),
          ),
        ),
      ],
    );
  }
}
