// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accent_color.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the currently-selected accent colour for the whole app.
///
/// Read it with:    `final accent = ref.watch(accentColorProvider);`
/// Change it with:  `ref.read(accentColorProvider.notifier).setAccent(color);`
///
/// (In-memory for now; persistence is wired in when we build the Settings
/// screen.) Kept alive so the choice survives even if briefly unwatched.

@ProviderFor(AccentColor)
final accentColorProvider = AccentColorProvider._();

/// Holds the currently-selected accent colour for the whole app.
///
/// Read it with:    `final accent = ref.watch(accentColorProvider);`
/// Change it with:  `ref.read(accentColorProvider.notifier).setAccent(color);`
///
/// (In-memory for now; persistence is wired in when we build the Settings
/// screen.) Kept alive so the choice survives even if briefly unwatched.
final class AccentColorProvider extends $NotifierProvider<AccentColor, Color> {
  /// Holds the currently-selected accent colour for the whole app.
  ///
  /// Read it with:    `final accent = ref.watch(accentColorProvider);`
  /// Change it with:  `ref.read(accentColorProvider.notifier).setAccent(color);`
  ///
  /// (In-memory for now; persistence is wired in when we build the Settings
  /// screen.) Kept alive so the choice survives even if briefly unwatched.
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

String _$accentColorHash() => r'02c0424e06dbcf602bdccfee30c8b6f8aeed32a5';

/// Holds the currently-selected accent colour for the whole app.
///
/// Read it with:    `final accent = ref.watch(accentColorProvider);`
/// Change it with:  `ref.read(accentColorProvider.notifier).setAccent(color);`
///
/// (In-memory for now; persistence is wired in when we build the Settings
/// screen.) Kept alive so the choice survives even if briefly unwatched.

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
