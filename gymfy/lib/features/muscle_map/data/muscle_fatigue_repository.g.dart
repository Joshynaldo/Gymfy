// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'muscle_fatigue_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide access to the [MuscleFatigueRepository].

@ProviderFor(muscleFatigueRepository)
final muscleFatigueRepositoryProvider = MuscleFatigueRepositoryProvider._();

/// App-wide access to the [MuscleFatigueRepository].

final class MuscleFatigueRepositoryProvider
    extends
        $FunctionalProvider<
          MuscleFatigueRepository,
          MuscleFatigueRepository,
          MuscleFatigueRepository
        >
    with $Provider<MuscleFatigueRepository> {
  /// App-wide access to the [MuscleFatigueRepository].
  MuscleFatigueRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'muscleFatigueRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$muscleFatigueRepositoryHash();

  @$internal
  @override
  $ProviderElement<MuscleFatigueRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MuscleFatigueRepository create(Ref ref) {
    return muscleFatigueRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MuscleFatigueRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MuscleFatigueRepository>(value),
    );
  }
}

String _$muscleFatigueRepositoryHash() =>
    r'82556eaa18adb8ee9ca65328bbd1f14ee8a2c839';
