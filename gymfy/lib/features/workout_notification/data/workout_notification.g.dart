// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_notification.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workoutNotificationBridge)
final workoutNotificationBridgeProvider = WorkoutNotificationBridgeProvider._();

final class WorkoutNotificationBridgeProvider
    extends
        $FunctionalProvider<
          WorkoutNotificationBridge,
          WorkoutNotificationBridge,
          WorkoutNotificationBridge
        >
    with $Provider<WorkoutNotificationBridge> {
  WorkoutNotificationBridgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutNotificationBridgeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutNotificationBridgeHash();

  @$internal
  @override
  $ProviderElement<WorkoutNotificationBridge> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkoutNotificationBridge create(Ref ref) {
    return workoutNotificationBridge(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkoutNotificationBridge value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkoutNotificationBridge>(value),
    );
  }
}

String _$workoutNotificationBridgeHash() =>
    r'2875e11499e20f36cea614a48e9f4ef1078e46b7';

/// Keeps the notification in step with the workout.
///
/// Updates when a set is logged, the exercise changes, a rest starts, is
/// extended or ends, and removes the notification when the workout is
/// finished or discarded (the in-progress session goes away either way) or
/// the setting is switched off.
///
/// Kept alive from the app root for the same reason as [WearSync]: it is
/// needed most when every screen is gone.

@ProviderFor(WorkoutNotificationSync)
final workoutNotificationSyncProvider = WorkoutNotificationSyncProvider._();

/// Keeps the notification in step with the workout.
///
/// Updates when a set is logged, the exercise changes, a rest starts, is
/// extended or ends, and removes the notification when the workout is
/// finished or discarded (the in-progress session goes away either way) or
/// the setting is switched off.
///
/// Kept alive from the app root for the same reason as [WearSync]: it is
/// needed most when every screen is gone.
final class WorkoutNotificationSyncProvider
    extends
        $NotifierProvider<
          WorkoutNotificationSync,
          WorkoutNotificationContent?
        > {
  /// Keeps the notification in step with the workout.
  ///
  /// Updates when a set is logged, the exercise changes, a rest starts, is
  /// extended or ends, and removes the notification when the workout is
  /// finished or discarded (the in-progress session goes away either way) or
  /// the setting is switched off.
  ///
  /// Kept alive from the app root for the same reason as [WearSync]: it is
  /// needed most when every screen is gone.
  WorkoutNotificationSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutNotificationSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutNotificationSyncHash();

  @$internal
  @override
  WorkoutNotificationSync create() => WorkoutNotificationSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkoutNotificationContent? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkoutNotificationContent?>(value),
    );
  }
}

String _$workoutNotificationSyncHash() =>
    r'f6977eaa549991916819f89bba6df8fe5ed4e384';

/// Keeps the notification in step with the workout.
///
/// Updates when a set is logged, the exercise changes, a rest starts, is
/// extended or ends, and removes the notification when the workout is
/// finished or discarded (the in-progress session goes away either way) or
/// the setting is switched off.
///
/// Kept alive from the app root for the same reason as [WearSync]: it is
/// needed most when every screen is gone.

abstract class _$WorkoutNotificationSync
    extends $Notifier<WorkoutNotificationContent?> {
  WorkoutNotificationContent? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<WorkoutNotificationContent?, WorkoutNotificationContent?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                WorkoutNotificationContent?,
                WorkoutNotificationContent?
              >,
              WorkoutNotificationContent?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
