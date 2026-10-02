// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_connect_bridge.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(healthConnectBridge)
final healthConnectBridgeProvider = HealthConnectBridgeProvider._();

final class HealthConnectBridgeProvider
    extends
        $FunctionalProvider<
          HealthConnectBridge,
          HealthConnectBridge,
          HealthConnectBridge
        >
    with $Provider<HealthConnectBridge> {
  HealthConnectBridgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthConnectBridgeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthConnectBridgeHash();

  @$internal
  @override
  $ProviderElement<HealthConnectBridge> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HealthConnectBridge create(Ref ref) {
    return healthConnectBridge(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthConnectBridge value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthConnectBridge>(value),
    );
  }
}

String _$healthConnectBridgeHash() =>
    r'a2223a45844b7a2cff804f529a2cb8bac16f96eb';

/// Whether Health Connect can be used, asked once per screen visit.
///
/// Not kept alive: the answer changes behind the app's back — installing
/// Health Connect from the Play Store and coming back is the normal way to
/// fix "not installed" — so the settings panel invalidates it on resume.

@ProviderFor(healthConnectAvailability)
final healthConnectAvailabilityProvider = HealthConnectAvailabilityProvider._();

/// Whether Health Connect can be used, asked once per screen visit.
///
/// Not kept alive: the answer changes behind the app's back — installing
/// Health Connect from the Play Store and coming back is the normal way to
/// fix "not installed" — so the settings panel invalidates it on resume.

final class HealthConnectAvailabilityProvider
    extends
        $FunctionalProvider<
          AsyncValue<HealthConnectAvailability>,
          HealthConnectAvailability,
          FutureOr<HealthConnectAvailability>
        >
    with
        $FutureModifier<HealthConnectAvailability>,
        $FutureProvider<HealthConnectAvailability> {
  /// Whether Health Connect can be used, asked once per screen visit.
  ///
  /// Not kept alive: the answer changes behind the app's back — installing
  /// Health Connect from the Play Store and coming back is the normal way to
  /// fix "not installed" — so the settings panel invalidates it on resume.
  HealthConnectAvailabilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthConnectAvailabilityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthConnectAvailabilityHash();

  @$internal
  @override
  $FutureProviderElement<HealthConnectAvailability> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HealthConnectAvailability> create(Ref ref) {
    return healthConnectAvailability(ref);
  }
}

String _$healthConnectAvailabilityHash() =>
    r'e701d50789954aa6562b91fee4d1104ac5444f80';

/// The Gymfy permissions Health Connect grants right now.

@ProviderFor(healthConnectGranted)
final healthConnectGrantedProvider = HealthConnectGrantedProvider._();

/// The Gymfy permissions Health Connect grants right now.

final class HealthConnectGrantedProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          FutureOr<Set<String>>
        >
    with $FutureModifier<Set<String>>, $FutureProvider<Set<String>> {
  /// The Gymfy permissions Health Connect grants right now.
  HealthConnectGrantedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthConnectGrantedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthConnectGrantedHash();

  @$internal
  @override
  $FutureProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Set<String>> create(Ref ref) {
    return healthConnectGranted(ref);
  }
}

String _$healthConnectGrantedHash() =>
    r'855ba0d394dfac7c3a83154025c17bb0822b6f7f';
