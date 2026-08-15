// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rest_timer_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide access to the [RestTimerRepository].

@ProviderFor(restTimerRepository)
final restTimerRepositoryProvider = RestTimerRepositoryProvider._();

/// App-wide access to the [RestTimerRepository].

final class RestTimerRepositoryProvider
    extends
        $FunctionalProvider<
          RestTimerRepository,
          RestTimerRepository,
          RestTimerRepository
        >
    with $Provider<RestTimerRepository> {
  /// App-wide access to the [RestTimerRepository].
  RestTimerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restTimerRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restTimerRepositoryHash();

  @$internal
  @override
  $ProviderElement<RestTimerRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RestTimerRepository create(Ref ref) {
    return restTimerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RestTimerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RestTimerRepository>(value),
    );
  }
}

String _$restTimerRepositoryHash() =>
    r'9e984eed87f378f5d3c86f5861190ae9a83afb67';
