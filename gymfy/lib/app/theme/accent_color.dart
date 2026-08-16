import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../shared/data/settings_repository.dart';
import 'app_theme.dart';

part 'accent_color.g.dart';

/// The small set of accent colours the user can pick from (later, in a
/// Settings screen). Kept here so the palette lives in one place.
class AccentPalette {
  const AccentPalette._();

  static const Color blue = Color(0xFF4F8CFF);
  static const Color green = Color(0xFF35C56A);
  static const Color orange = Color(0xFFFF8A3D);
  static const Color pink = Color(0xFFFF5C8A);
  static const Color purple = Color(0xFF9B6BFF);
  static const Color teal = Color(0xFF2FD8C6);

  /// All options, in display order (used by the future Settings picker).
  static const List<Color> options = [blue, green, orange, pink, purple, teal];

  /// The colour used on first launch.
  static const Color defaultAccent = blue;
}

/// Setting key for the chosen accent.
const accentColorSetting = 'accent_color';

/// Every accent that may legitimately be stored.
///
/// The six palette options, plus the accent each editor theme was designed
/// around. The theme accents aren't in [AccentPalette.options] on purpose —
/// several are near-duplicates of the base six, and a picker with two similar
/// purples in it is worse than one — but they still have to survive a
/// round-trip once a theme suggests one.
List<Color> get selectableAccents => [
  ...AccentPalette.options,
  for (final theme in AppTheme.values)
    if (theme.suggestedAccent != null) theme.suggestedAccent!,
];

/// Reads a stored accent back, or null when there isn't a usable one.
///
/// The stored number is only honoured if it still matches a colour the app can
/// actually offer, so a value left behind by an older build (or a hand-edited
/// database) degrades to the default instead of theming the app some colour
/// nothing can select again.
Color? parseAccentColor(String? raw) {
  if (raw == null) return null;
  final value = int.tryParse(raw);
  if (value == null) return null;
  for (final option in selectableAccents) {
    if (option.toARGB32() == value) return option;
  }
  return null;
}

/// The accent as stored on disk: null while the first read is in flight, and
/// null again if nothing valid was ever saved.
final storedAccentProvider = StreamProvider<Color?>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchRaw(accentColorSetting)
      .map(parseAccentColor);
});

/// The currently-selected accent colour for the whole app.
///
/// Read it with:    `final accent = ref.watch(accentColorProvider);`
/// Change it with:  `ref.read(accentColorProvider.notifier).setAccent(color);`
///
/// Backed by the settings table, so the choice survives a restart. There is no
/// in-memory copy: [setAccent] only writes, and the new colour arrives back
/// through [storedAccentProvider]. That means the stored value and the themed
/// value cannot drift apart, and the picker needs no state of its own.
///
/// The colour is stored as its ARGB integer rather than a palette index, so
/// reordering [AccentPalette.options] later can't silently change someone's
/// chosen colour.
@Riverpod(keepAlive: true)
class AccentColor extends _$AccentColor {
  @override
  Color build() {
    return ref.watch(storedAccentProvider).value ?? AccentPalette.defaultAccent;
  }

  Future<void> setAccent(Color color) {
    return ref
        .read(settingsRepositoryProvider)
        .write(accentColorSetting, color.toARGB32().toString());
  }
}
