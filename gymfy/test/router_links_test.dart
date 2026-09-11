// Every in-app link resolves to a route that exists.
//
// Written after Progress moved from a bottom-nav tab to a screen under More,
// which changed six paths at once. A stale `context.go('/progress/photos')`
// left behind anywhere would compile, pass every other test, and fail only
// when a user tapped it — go_router throws at navigation time, not build time.
//
// So rather than testing one screen, this reads the router's own route tree
// and checks it against every literal navigation in the source.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymfy/app/router/app_router.dart';

/// Every full path the router can serve.
Set<String> _declaredPaths(List<RouteBase> routes, [String prefix = '']) {
  final paths = <String>{};
  for (final route in routes) {
    switch (route) {
      case GoRoute():
        final path = route.path.startsWith('/')
            ? route.path
            : '$prefix/${route.path}';
        paths.add(path);
        paths.addAll(_declaredPaths(route.routes, path));
      case ShellRouteBase():
        // A shell contributes no path of its own; its branches carry them.
        for (final child in route.routes) {
          paths.addAll(_declaredPaths([child], prefix));
        }
    }
  }
  return paths;
}

/// Collapses a route's `:id` and a call site's interpolation to one token, so
/// the two compare equal.
///
/// Both spellings of interpolation are handled: `${expression}` and the bare
/// `$identifier`, which Dart allows and which this missed at first.
String _shape(String path) => path
    .replaceAll(RegExp(r'\$\{[^}]*\}'), '*')
    .replaceAll(RegExp(r'\$[A-Za-z_][A-Za-z0-9_]*'), '*')
    .replaceAll(RegExp(r':[A-Za-z0-9_]+'), '*');

void main() {
  late Set<String> declared;

  setUpAll(() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);
    declared = _declaredPaths(
      router.configuration.routes,
    ).map(_shape).toSet();
  });

  test('the router still serves the screens it is supposed to', () {
    // A guard on the guard: if the walk above ever stops finding routes, every
    // other assertion here passes vacuously.
    expect(declared, contains('/home'));
    expect(declared, contains('/more/progress'));
    expect(declared, contains('/more/progress/photos/compare'));
    expect(declared, contains('/more/progress/measurements/history'));
    expect(declared, contains('/exercises/*'));
  });

  test('Progress no longer answers at the top level', () {
    // It moved under More. Leaving the old paths alive would be worse than
    // removing them: two routes to one screen, one of them with no tab
    // highlighted underneath it.
    expect(declared, isNot(contains('/progress')));
    expect(declared, isNot(contains('/progress/photos')));
  });

  test('every context.go in the app points at a real route', () {
    final calls = <String, String>{}; // path -> file it appears in
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))) {
      for (final match in RegExp(
        // Single-quoted literals only; anything built at runtime is out of
        // reach of a static check like this one.
        r"""\.go\(\s*'(/[^']*)'""",
      ).allMatches(file.readAsStringSync())) {
        calls[match.group(1)!] = file.path;
      }
    }

    expect(calls, isNotEmpty, reason: 'found no navigation to check');
    for (final entry in calls.entries) {
      expect(
        declared,
        contains(_shape(entry.key)),
        reason: '${entry.key} (in ${entry.value}) matches no route',
      );
    }
  });
}
