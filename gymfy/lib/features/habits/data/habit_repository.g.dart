// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide access to the [HabitRepository].

@ProviderFor(habitRepository)
final habitRepositoryProvider = HabitRepositoryProvider._();

/// App-wide access to the [HabitRepository].

final class HabitRepositoryProvider
    extends
        $FunctionalProvider<HabitRepository, HabitRepository, HabitRepository>
    with $Provider<HabitRepository> {
  /// App-wide access to the [HabitRepository].
  HabitRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'habitRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$habitRepositoryHash();

  @$internal
  @override
  $ProviderElement<HabitRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HabitRepository create(Ref ref) {
    return habitRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HabitRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HabitRepository>(value),
    );
  }
}

String _$habitRepositoryHash() => r'd532f7f02ff4d2f383749da7ddd8740407d990c7';
