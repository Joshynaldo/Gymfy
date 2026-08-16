// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recap_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide access to the [RecapRepository].

@ProviderFor(recapRepository)
final recapRepositoryProvider = RecapRepositoryProvider._();

/// App-wide access to the [RecapRepository].

final class RecapRepositoryProvider
    extends
        $FunctionalProvider<RecapRepository, RecapRepository, RecapRepository>
    with $Provider<RecapRepository> {
  /// App-wide access to the [RecapRepository].
  RecapRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recapRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recapRepositoryHash();

  @$internal
  @override
  $ProviderElement<RecapRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecapRepository create(Ref ref) {
    return recapRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecapRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecapRepository>(value),
    );
  }
}

String _$recapRepositoryHash() => r'ff8f525ac90b58697a0ca2ee24cbac241ea60fa7';
