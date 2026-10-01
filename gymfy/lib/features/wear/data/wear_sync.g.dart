// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wear_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps the watch in step with the phone.
///
/// Watched, not polled: the providers below already push, and a timer here
/// would send the same payload over and over for the length of a workout —
/// on two batteries.
///
/// Nothing reads this provider's value; it exists for the side effect, so it
/// has to be kept alive explicitly or it would be disposed the moment the
/// screen that created it went away, which is exactly when the phone goes in
/// a pocket and the watch matters most.

@ProviderFor(WearSync)
final wearSyncProvider = WearSyncProvider._();

/// Keeps the watch in step with the phone.
///
/// Watched, not polled: the providers below already push, and a timer here
/// would send the same payload over and over for the length of a workout —
/// on two batteries.
///
/// Nothing reads this provider's value; it exists for the side effect, so it
/// has to be kept alive explicitly or it would be disposed the moment the
/// screen that created it went away, which is exactly when the phone goes in
/// a pocket and the watch matters most.
final class WearSyncProvider extends $NotifierProvider<WearSync, WearWorkout> {
  /// Keeps the watch in step with the phone.
  ///
  /// Watched, not polled: the providers below already push, and a timer here
  /// would send the same payload over and over for the length of a workout —
  /// on two batteries.
  ///
  /// Nothing reads this provider's value; it exists for the side effect, so it
  /// has to be kept alive explicitly or it would be disposed the moment the
  /// screen that created it went away, which is exactly when the phone goes in
  /// a pocket and the watch matters most.
  WearSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wearSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wearSyncHash();

  @$internal
  @override
  WearSync create() => WearSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WearWorkout value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WearWorkout>(value),
    );
  }
}

String _$wearSyncHash() => r'e53d06db576c67d3ebcfba680d3b8ee74cb7cf8e';

/// Keeps the watch in step with the phone.
///
/// Watched, not polled: the providers below already push, and a timer here
/// would send the same payload over and over for the length of a workout —
/// on two batteries.
///
/// Nothing reads this provider's value; it exists for the side effect, so it
/// has to be kept alive explicitly or it would be disposed the moment the
/// screen that created it went away, which is exactly when the phone goes in
/// a pocket and the watch matters most.

abstract class _$WearSync extends $Notifier<WearWorkout> {
  WearWorkout build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WearWorkout, WearWorkout>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WearWorkout, WearWorkout>,
              WearWorkout,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Acts on the commands the watch sends back — and the buttons on the
/// ongoing workout notification, which arrive through the same door.
///
/// Kept apart from [WearSync], which is one-way. This is the reverse
/// channel, and separating them keeps the rule visible: the phone owns the
/// state, the watch asks it to change.

@ProviderFor(WearCommands)
final wearCommandsProvider = WearCommandsProvider._();

/// Acts on the commands the watch sends back — and the buttons on the
/// ongoing workout notification, which arrive through the same door.
///
/// Kept apart from [WearSync], which is one-way. This is the reverse
/// channel, and separating them keeps the rule visible: the phone owns the
/// state, the watch asks it to change.
final class WearCommandsProvider extends $NotifierProvider<WearCommands, void> {
  /// Acts on the commands the watch sends back — and the buttons on the
  /// ongoing workout notification, which arrive through the same door.
  ///
  /// Kept apart from [WearSync], which is one-way. This is the reverse
  /// channel, and separating them keeps the rule visible: the phone owns the
  /// state, the watch asks it to change.
  WearCommandsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wearCommandsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wearCommandsHash();

  @$internal
  @override
  WearCommands create() => WearCommands();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$wearCommandsHash() => r'adec32445adbf6ff96f03583b23770d8f33d667c';

/// Acts on the commands the watch sends back — and the buttons on the
/// ongoing workout notification, which arrive through the same door.
///
/// Kept apart from [WearSync], which is one-way. This is the reverse
/// channel, and separating them keeps the rule visible: the phone owns the
/// state, the watch asks it to change.

abstract class _$WearCommands extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
