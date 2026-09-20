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

String _$wearSyncHash() => r'6271508c94957f368bbce2fc18b41a4de4fc0390';

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
