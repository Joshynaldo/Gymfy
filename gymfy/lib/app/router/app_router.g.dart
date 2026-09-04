// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's navigation configuration.
///
/// We use a [StatefulShellRoute] so the bottom navigation bar stays put while
/// each tab keeps its own navigation stack / scroll position.
///
/// Kept alive for the app's lifetime so navigation state isn't thrown away —
/// e.g. when the accent colour changes and the theme (but not the router)
/// rebuilds.

@ProviderFor(goRouter)
final goRouterProvider = GoRouterProvider._();

/// The app's navigation configuration.
///
/// We use a [StatefulShellRoute] so the bottom navigation bar stays put while
/// each tab keeps its own navigation stack / scroll position.
///
/// Kept alive for the app's lifetime so navigation state isn't thrown away —
/// e.g. when the accent colour changes and the theme (but not the router)
/// rebuilds.

final class GoRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// The app's navigation configuration.
  ///
  /// We use a [StatefulShellRoute] so the bottom navigation bar stays put while
  /// each tab keeps its own navigation stack / scroll position.
  ///
  /// Kept alive for the app's lifetime so navigation state isn't thrown away —
  /// e.g. when the accent colour changes and the theme (but not the router)
  /// rebuilds.
  GoRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return goRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$goRouterHash() => r'037e6884b3b2be16c6a6ca4f5c8cff75d0068512';
