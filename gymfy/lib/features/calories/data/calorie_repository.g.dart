// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide access to the [CalorieRepository].

@ProviderFor(calorieRepository)
final calorieRepositoryProvider = CalorieRepositoryProvider._();

/// App-wide access to the [CalorieRepository].

final class CalorieRepositoryProvider
    extends
        $FunctionalProvider<
          CalorieRepository,
          CalorieRepository,
          CalorieRepository
        >
    with $Provider<CalorieRepository> {
  /// App-wide access to the [CalorieRepository].
  CalorieRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieRepositoryHash();

  @$internal
  @override
  $ProviderElement<CalorieRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieRepository create(Ref ref) {
    return calorieRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieRepository>(value),
    );
  }
}

String _$calorieRepositoryHash() => r'9b52b5c3c8b6b579737211ac254477fe812f474e';
