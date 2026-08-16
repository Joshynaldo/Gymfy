// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overload_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide access to the [OverloadRepository].

@ProviderFor(overloadRepository)
final overloadRepositoryProvider = OverloadRepositoryProvider._();

/// App-wide access to the [OverloadRepository].

final class OverloadRepositoryProvider
    extends
        $FunctionalProvider<
          OverloadRepository,
          OverloadRepository,
          OverloadRepository
        >
    with $Provider<OverloadRepository> {
  /// App-wide access to the [OverloadRepository].
  OverloadRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'overloadRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$overloadRepositoryHash();

  @$internal
  @override
  $ProviderElement<OverloadRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OverloadRepository create(Ref ref) {
    return overloadRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OverloadRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OverloadRepository>(value),
    );
  }
}

String _$overloadRepositoryHash() =>
    r'6ff9c4b8cb53f449dce7c84b5dca14dad338a1bc';
