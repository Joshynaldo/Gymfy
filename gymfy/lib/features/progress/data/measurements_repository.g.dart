// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurements_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide access to the [MeasurementsRepository].

@ProviderFor(measurementsRepository)
final measurementsRepositoryProvider = MeasurementsRepositoryProvider._();

/// App-wide access to the [MeasurementsRepository].

final class MeasurementsRepositoryProvider
    extends
        $FunctionalProvider<
          MeasurementsRepository,
          MeasurementsRepository,
          MeasurementsRepository
        >
    with $Provider<MeasurementsRepository> {
  /// App-wide access to the [MeasurementsRepository].
  MeasurementsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'measurementsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$measurementsRepositoryHash();

  @$internal
  @override
  $ProviderElement<MeasurementsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MeasurementsRepository create(Ref ref) {
    return measurementsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MeasurementsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MeasurementsRepository>(value),
    );
  }
}

String _$measurementsRepositoryHash() =>
    r'3691a4539527140eeca892dd32d86cd8bbb46501';
