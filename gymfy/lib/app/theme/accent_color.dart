import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

/// Holds the currently-selected accent colour for the whole app.
///
/// Read it with:    `final accent = ref.watch(accentColorProvider);`
/// Change it with:  `ref.read(accentColorProvider.notifier).setAccent(color);`
///
/// (In-memory for now; persistence is wired in when we build the Settings
/// screen.) Kept alive so the choice survives even if briefly unwatched.
@Riverpod(keepAlive: true)
class AccentColor extends _$AccentColor {
  @override
  Color build() => AccentPalette.defaultAccent;

  void setAccent(Color color) => state = color;
}
