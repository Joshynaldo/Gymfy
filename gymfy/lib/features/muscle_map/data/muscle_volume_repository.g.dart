// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'muscle_volume_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide access to the [MuscleVolumeRepository].

@ProviderFor(muscleVolumeRepository)
final muscleVolumeRepositoryProvider = MuscleVolumeRepositoryProvider._();

/// App-wide access to the [MuscleVolumeRepository].

final class MuscleVolumeRepositoryProvider
    extends
        $FunctionalProvider<
          MuscleVolumeRepository,
          MuscleVolumeRepository,
          MuscleVolumeRepository
        >
    with $Provider<MuscleVolumeRepository> {
  /// App-wide access to the [MuscleVolumeRepository].
  MuscleVolumeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'muscleVolumeRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$muscleVolumeRepositoryHash();

  @$internal
  @override
  $ProviderElement<MuscleVolumeRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MuscleVolumeRepository create(Ref ref) {
    return muscleVolumeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MuscleVolumeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MuscleVolumeRepository>(value),
    );
  }
}

String _$muscleVolumeRepositoryHash() =>
    r'51e3611a10b219249706e7673d56c922b8a543d7';
