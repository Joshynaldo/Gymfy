// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide access to the [ExerciseRepository].

@ProviderFor(exerciseRepository)
final exerciseRepositoryProvider = ExerciseRepositoryProvider._();

/// App-wide access to the [ExerciseRepository].

final class ExerciseRepositoryProvider
    extends
        $FunctionalProvider<
          ExerciseRepository,
          ExerciseRepository,
          ExerciseRepository
        >
    with $Provider<ExerciseRepository> {
  /// App-wide access to the [ExerciseRepository].
  ExerciseRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exerciseRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exerciseRepositoryHash();

  @$internal
  @override
  $ProviderElement<ExerciseRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExerciseRepository create(Ref ref) {
    return exerciseRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExerciseRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExerciseRepository>(value),
    );
  }
}

String _$exerciseRepositoryHash() =>
    r'96035dc6b6b421cb33795968aa387a4278313e26';
