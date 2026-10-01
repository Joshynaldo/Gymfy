// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_plan_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide access to the [TrainingPlanRepository].

@ProviderFor(trainingPlanRepository)
final trainingPlanRepositoryProvider = TrainingPlanRepositoryProvider._();

/// App-wide access to the [TrainingPlanRepository].

final class TrainingPlanRepositoryProvider
    extends
        $FunctionalProvider<
          TrainingPlanRepository,
          TrainingPlanRepository,
          TrainingPlanRepository
        >
    with $Provider<TrainingPlanRepository> {
  /// App-wide access to the [TrainingPlanRepository].
  TrainingPlanRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trainingPlanRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trainingPlanRepositoryHash();

  @$internal
  @override
  $ProviderElement<TrainingPlanRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TrainingPlanRepository create(Ref ref) {
    return trainingPlanRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrainingPlanRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrainingPlanRepository>(value),
    );
  }
}

String _$trainingPlanRepositoryHash() =>
    r'f6fbd465f054d47319583ae79dd86af99394a40f';
