// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(importRepository)
final importRepositoryProvider = ImportRepositoryProvider._();

final class ImportRepositoryProvider
    extends
        $FunctionalProvider<
          ImportRepository,
          ImportRepository,
          ImportRepository
        >
    with $Provider<ImportRepository> {
  ImportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importRepositoryHash();

  @$internal
  @override
  $ProviderElement<ImportRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImportRepository create(Ref ref) {
    return importRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportRepository>(value),
    );
  }
}

String _$importRepositoryHash() => r'ef07183f0c4e17cf77c48057543b9c6761297f5a';
