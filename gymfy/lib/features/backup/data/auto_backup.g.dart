// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_backup.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide access to the [AutoBackupService].

@ProviderFor(autoBackupService)
final autoBackupServiceProvider = AutoBackupServiceProvider._();

/// App-wide access to the [AutoBackupService].

final class AutoBackupServiceProvider
    extends
        $FunctionalProvider<
          AutoBackupService,
          AutoBackupService,
          AutoBackupService
        >
    with $Provider<AutoBackupService> {
  /// App-wide access to the [AutoBackupService].
  AutoBackupServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoBackupServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoBackupServiceHash();

  @$internal
  @override
  $ProviderElement<AutoBackupService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AutoBackupService create(Ref ref) {
    return autoBackupService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AutoBackupService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AutoBackupService>(value),
    );
  }
}

String _$autoBackupServiceHash() => r'1e27fffddda83b13b503b12f721666ef493f9db9';

/// Runs automatic backups when they are due.
///
/// Watched from the app root, like the watch sync, because the moments that
/// matter — opening the app, finishing a workout — happen on screens that have
/// nothing to do with backups.

@ProviderFor(AutoBackupWatcher)
final autoBackupWatcherProvider = AutoBackupWatcherProvider._();

/// Runs automatic backups when they are due.
///
/// Watched from the app root, like the watch sync, because the moments that
/// matter — opening the app, finishing a workout — happen on screens that have
/// nothing to do with backups.
final class AutoBackupWatcherProvider
    extends $NotifierProvider<AutoBackupWatcher, void> {
  /// Runs automatic backups when they are due.
  ///
  /// Watched from the app root, like the watch sync, because the moments that
  /// matter — opening the app, finishing a workout — happen on screens that have
  /// nothing to do with backups.
  AutoBackupWatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoBackupWatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoBackupWatcherHash();

  @$internal
  @override
  AutoBackupWatcher create() => AutoBackupWatcher();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$autoBackupWatcherHash() => r'15f7044414539341d8844755c19f933dafc4127a';

/// Runs automatic backups when they are due.
///
/// Watched from the app root, like the watch sync, because the moments that
/// matter — opening the app, finishing a workout — happen on screens that have
/// nothing to do with backups.

abstract class _$AutoBackupWatcher extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
