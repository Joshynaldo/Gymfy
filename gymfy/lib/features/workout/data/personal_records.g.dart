// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_records.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide access to the [PersonalRecordsRepository].

@ProviderFor(personalRecordsRepository)
final personalRecordsRepositoryProvider = PersonalRecordsRepositoryProvider._();

/// App-wide access to the [PersonalRecordsRepository].

final class PersonalRecordsRepositoryProvider
    extends
        $FunctionalProvider<
          PersonalRecordsRepository,
          PersonalRecordsRepository,
          PersonalRecordsRepository
        >
    with $Provider<PersonalRecordsRepository> {
  /// App-wide access to the [PersonalRecordsRepository].
  PersonalRecordsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'personalRecordsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$personalRecordsRepositoryHash();

  @$internal
  @override
  $ProviderElement<PersonalRecordsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PersonalRecordsRepository create(Ref ref) {
    return personalRecordsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PersonalRecordsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PersonalRecordsRepository>(value),
    );
  }
}

String _$personalRecordsRepositoryHash() =>
    r'88c88750e04d0b0c03014080e3aadcade8463f4a';
