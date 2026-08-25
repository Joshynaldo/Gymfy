// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide access to the [ExportRepository].

@ProviderFor(exportRepository)
final exportRepositoryProvider = ExportRepositoryProvider._();

/// App-wide access to the [ExportRepository].

final class ExportRepositoryProvider
    extends
        $FunctionalProvider<
          ExportRepository,
          ExportRepository,
          ExportRepository
        >
    with $Provider<ExportRepository> {
  /// App-wide access to the [ExportRepository].
  ExportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportRepositoryHash();

  @$internal
  @override
  $ProviderElement<ExportRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ExportRepository create(Ref ref) {
    return exportRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExportRepository>(value),
    );
  }
}

String _$exportRepositoryHash() => r'1497775b77c75fdfcbbf9e008e9fc59627be594b';
