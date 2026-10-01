// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_connect_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide access to the [HealthConnectSync].

@ProviderFor(healthConnectSync)
final healthConnectSyncProvider = HealthConnectSyncProvider._();

/// App-wide access to the [HealthConnectSync].

final class HealthConnectSyncProvider
    extends
        $FunctionalProvider<
          HealthConnectSync,
          HealthConnectSync,
          HealthConnectSync
        >
    with $Provider<HealthConnectSync> {
  /// App-wide access to the [HealthConnectSync].
  HealthConnectSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthConnectSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthConnectSyncHash();

  @$internal
  @override
  $ProviderElement<HealthConnectSync> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HealthConnectSync create(Ref ref) {
    return healthConnectSync(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthConnectSync value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthConnectSync>(value),
    );
  }
}

String _$healthConnectSyncHash() => r'a3f53b4821f695d5f1f7b8f19a9c18263c83bba3';

/// Runs Health Connect syncs at the moments that matter.
///
/// Watched from the app root, like the watch sync and automatic backups,
/// because those moments — opening the app, finishing or deleting a workout —
/// happen on screens that have nothing to do with Health Connect.
///
/// There is no background job: that would need WorkManager, a new plugin,
/// and Health Connect only lets an app read while it is in the foreground
/// anyway. So weigh-ins arrive when the app is opened.

@ProviderFor(HealthConnectWatcher)
final healthConnectWatcherProvider = HealthConnectWatcherProvider._();

/// Runs Health Connect syncs at the moments that matter.
///
/// Watched from the app root, like the watch sync and automatic backups,
/// because those moments — opening the app, finishing or deleting a workout —
/// happen on screens that have nothing to do with Health Connect.
///
/// There is no background job: that would need WorkManager, a new plugin,
/// and Health Connect only lets an app read while it is in the foreground
/// anyway. So weigh-ins arrive when the app is opened.
final class HealthConnectWatcherProvider
    extends $NotifierProvider<HealthConnectWatcher, void> {
  /// Runs Health Connect syncs at the moments that matter.
  ///
  /// Watched from the app root, like the watch sync and automatic backups,
  /// because those moments — opening the app, finishing or deleting a workout —
  /// happen on screens that have nothing to do with Health Connect.
  ///
  /// There is no background job: that would need WorkManager, a new plugin,
  /// and Health Connect only lets an app read while it is in the foreground
  /// anyway. So weigh-ins arrive when the app is opened.
  HealthConnectWatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthConnectWatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthConnectWatcherHash();

  @$internal
  @override
  HealthConnectWatcher create() => HealthConnectWatcher();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$healthConnectWatcherHash() =>
    r'4aa8b015fd93c6d4fa37ccb98fa94fc8ca5f0736';

/// Runs Health Connect syncs at the moments that matter.
///
/// Watched from the app root, like the watch sync and automatic backups,
/// because those moments — opening the app, finishing or deleting a workout —
/// happen on screens that have nothing to do with Health Connect.
///
/// There is no background job: that would need WorkManager, a new plugin,
/// and Health Connect only lets an app read while it is in the foreground
/// anyway. So weigh-ins arrive when the app is opened.

abstract class _$HealthConnectWatcher extends $Notifier<void> {
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
