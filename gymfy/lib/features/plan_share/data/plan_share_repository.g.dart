// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_share_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide access to the [PlanShareRepository].

@ProviderFor(planShareRepository)
final planShareRepositoryProvider = PlanShareRepositoryProvider._();

/// App-wide access to the [PlanShareRepository].

final class PlanShareRepositoryProvider
    extends
        $FunctionalProvider<
          PlanShareRepository,
          PlanShareRepository,
          PlanShareRepository
        >
    with $Provider<PlanShareRepository> {
  /// App-wide access to the [PlanShareRepository].
  PlanShareRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planShareRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planShareRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlanShareRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlanShareRepository create(Ref ref) {
    return planShareRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanShareRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanShareRepository>(value),
    );
  }
}

String _$planShareRepositoryHash() =>
    r'1b7f4cd0d8b60ceb1a746819af03f699e8a002eb';
