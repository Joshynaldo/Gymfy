// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_overview_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide access to the [WeeklyOverviewRepository].

@ProviderFor(weeklyOverviewRepository)
final weeklyOverviewRepositoryProvider = WeeklyOverviewRepositoryProvider._();

/// App-wide access to the [WeeklyOverviewRepository].

final class WeeklyOverviewRepositoryProvider
    extends
        $FunctionalProvider<
          WeeklyOverviewRepository,
          WeeklyOverviewRepository,
          WeeklyOverviewRepository
        >
    with $Provider<WeeklyOverviewRepository> {
  /// App-wide access to the [WeeklyOverviewRepository].
  WeeklyOverviewRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weeklyOverviewRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weeklyOverviewRepositoryHash();

  @$internal
  @override
  $ProviderElement<WeeklyOverviewRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WeeklyOverviewRepository create(Ref ref) {
    return weeklyOverviewRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WeeklyOverviewRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WeeklyOverviewRepository>(value),
    );
  }
}

String _$weeklyOverviewRepositoryHash() =>
    r'0dcada8a5b8e931fe458a09db4804c7009e272fe';
