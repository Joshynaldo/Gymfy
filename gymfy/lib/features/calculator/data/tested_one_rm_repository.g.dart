// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tested_one_rm_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide access to the [TestedOneRmRepository].

@ProviderFor(testedOneRmRepository)
final testedOneRmRepositoryProvider = TestedOneRmRepositoryProvider._();

/// App-wide access to the [TestedOneRmRepository].

final class TestedOneRmRepositoryProvider
    extends
        $FunctionalProvider<
          TestedOneRmRepository,
          TestedOneRmRepository,
          TestedOneRmRepository
        >
    with $Provider<TestedOneRmRepository> {
  /// App-wide access to the [TestedOneRmRepository].
  TestedOneRmRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'testedOneRmRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$testedOneRmRepositoryHash();

  @$internal
  @override
  $ProviderElement<TestedOneRmRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TestedOneRmRepository create(Ref ref) {
    return testedOneRmRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TestedOneRmRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TestedOneRmRepository>(value),
    );
  }
}

String _$testedOneRmRepositoryHash() =>
    r'e764c8b6bdff6fafc359a7002f1c1f6ea119262c';
