// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wear_bridge.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(wearBridge)
final wearBridgeProvider = WearBridgeProvider._();

final class WearBridgeProvider
    extends $FunctionalProvider<WearBridge, WearBridge, WearBridge>
    with $Provider<WearBridge> {
  WearBridgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wearBridgeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wearBridgeHash();

  @$internal
  @override
  $ProviderElement<WearBridge> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WearBridge create(Ref ref) {
    return wearBridge(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WearBridge value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WearBridge>(value),
    );
  }
}

String _$wearBridgeHash() => r'b639cd08ec6a8d7db40b51b885cd5e6d14ba3aac';
