import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/models/equipment.dart';
import '../../../app/theme/glass.dart';
import '../../../shared/widgets/glass_sheet.dart';
import '../../../shared/widgets/pressable.dart';

/// Picks which equipment the library should be narrowed to.
///
/// A sheet behind a button rather than a second row of chips. The first
/// version was a chip bar under the muscle one, and stacking them put two
/// identical "All" chips directly above each other, meaning different things
/// — the kind of thing that reads as a rendering fault rather than a control.
/// It also cost 44px of a screen whose job is showing a list.
///
/// Toggling applies immediately rather than behind an "Apply" button: there
/// is no half-made state worth protecting here, and a sheet you can dismiss
/// by swiping must not have changes that a swipe would throw away.
Future<void> showEquipmentFilterSheet({
  required BuildContext context,
  required List<Equipment> available,
  required Set<Equipment> selected,
  required ValueChanged<Equipment> onToggle,
  required VoidCallback onClear,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // The sheet paints nothing itself; GlassSheet is the surface, and an
    // opaque background here would sit in front of its blur.
    backgroundColor: Colors.transparent,
    builder: (context) => _EquipmentSheet(
      available: available,
      selected: selected,
      onToggle: onToggle,
      onClear: onClear,
    ),
  );
}

/// The equipment filter, as one chip-shaped button with a count on it.
///
/// Lives next to the sheet it opens, because two screens show it: the
/// Exercises tab and the picker that adds exercises to a day. They filter the
/// same library and should offer the same controls — "the library found it
/// but the picker didn't" is a confusing bug to be on the wrong end of.
///
/// The count is the whole trick. A filter you cannot see is a filter you
/// forget you set, and then the list looks broken; a badge reading "2"
/// explains a short list without taking any room from it.
class EquipmentFilterButton extends ConsumerWidget {
  const EquipmentFilterButton({
    super.key,
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    final active = count > 0;
    final radius = BorderRadius.circular(13);

    // Shaped like the chips it sits among rather than like an app-bar icon.
    // It is one of the filters; up in the chrome it read as an unrelated
    // action that happened to change the results.
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: active ? 'Equipment ($count)' : 'Filter by equipment',
        child: Pressable(
          borderRadius: radius,
          onTap: onPressed,
          splash: false,
          child: GlassSurface(
            borderRadius: radius,
            tier: GlassTier.quiet,
            selected: active,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Badge(
                  isLabelVisible: active,
                  label: Text('$count'),
                  backgroundColor: accent,
                  // Against the accent, which is a light colour on several
                  // themes — white on yellow would be unreadable at badge
                  // size.
                  textColor:
                      ThemeData.estimateBrightnessForColor(accent) ==
                          Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  child: Icon(
                    active ? Icons.filter_alt : Icons.filter_alt_outlined,
                    size: 19,
                    color: active
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EquipmentSheet extends StatefulWidget {
  const _EquipmentSheet({
    required this.available,
    required this.selected,
    required this.onToggle,
    required this.onClear,
  });

  final List<Equipment> available;
  final Set<Equipment> selected;
  final ValueChanged<Equipment> onToggle;
  final VoidCallback onClear;

  @override
  State<_EquipmentSheet> createState() => _EquipmentSheetState();
}

class _EquipmentSheetState extends State<_EquipmentSheet> {
  /// Its own copy of the selection, kept in step with the screen behind.
  ///
  /// The sheet has to redraw its own ticks when one is tapped, and the screen
  /// behind has to refilter — two rebuilds, so two pieces of state. Reading
  /// `widget.selected` instead would show stale ticks, because the parent
  /// rebuilding does not rebuild a route that is already on the stack.
  late final Set<Equipment> _selected = {...widget.selected};

  void _toggle(Equipment equipment) {
    setState(() {
      if (!_selected.remove(equipment)) _selected.add(equipment);
    });
    widget.onToggle(equipment);
  }

  void _clear() {
    setState(_selected.clear);
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    return GlassSheet(
      title: 'Equipment',
      handle: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AllRow(active: _selected.isEmpty, onTap: _clear),
            const Divider(height: 1),
            for (final equipment in widget.available)
              _EquipmentRow(
                equipment: equipment,
                selected: _selected.contains(equipment),
                onTap: () => _toggle(equipment),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// The "no restriction" row, above a rule.
///
/// Separated rather than sitting in the list, because it is not a seventh
/// kind of equipment — it is the absence of a choice, and a row that toggles
/// like the others would invite tapping it *alongside* one of them.
class _AllRow extends ConsumerWidget {
  const _AllRow({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);

    return ListTile(
      title: const Text('All equipment'),
      trailing: active ? Icon(Icons.check, color: accent) : null,
      selected: active,
      selectedTileColor: accent.withValues(alpha: 0.10),
      // Already showing everything, so this would be a no-op tap.
      onTap: active ? null : onTap,
    );
  }
}

class _EquipmentRow extends ConsumerWidget {
  const _EquipmentRow({
    required this.equipment,
    required this.selected,
    required this.onTap,
  });

  final Equipment equipment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);

    return ListTile(
      title: Text(equipment.label),
      // A tick rather than a checkbox: the rows already behave like a
      // multi-select, and a column of empty boxes is louder than the five
      // words it decorates.
      trailing: selected ? Icon(Icons.check, color: accent) : null,
      selected: selected,
      selectedTileColor: accent.withValues(alpha: 0.10),
      onTap: onTap,
    );
  }
}
