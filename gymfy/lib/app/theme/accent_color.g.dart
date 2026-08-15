// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accent_color.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(AccentColor)
final accentColorProvider = AccentColorProvider._();

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
final class AccentColorProvider extends $NotifierProvider<AccentColor, Color> {
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
  AccentColorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accentColorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accentColorHash();

  @$internal
  @override
  AccentColor create() => AccentColor();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Color value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Color>(value),
    );
  }
}

String _$accentColorHash() => r'f924dda9f0de8becf2f9a9b5ddbf951ff847dbe2';

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

abstract class _$AccentColor extends $Notifier<Color> {
  Color build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Color, Color>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Color, Color>,
              Color,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
