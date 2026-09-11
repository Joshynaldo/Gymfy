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
    declared = _declaredPaths(router.configuration.routes).map(_shape).toSet();
  });

  test('the router still serves the screens it is supposed to', () {
    // A guard on the guard: if the walk above ever stops finding routes, every
    // other assertion here passes vacuously.
    expect(declared, contains('/home'));
    expect(declared, contains('/progress'));
    expect(declared, contains('/progress/photos/compare'));
    expect(declared, contains('/progress/measurements/history'));
    expect(declared, contains('/exercises/*'));
  });

  test('Progress answers at the top level, and only there', () {
    // It came back out of More when the bar went to four tabs. Leaving the old
    // nested paths alive alongside the new ones would be worse than moving
    // them: two routes to one screen, one of them with the wrong tab lit
    // underneath it.
    expect(declared, contains('/progress'));
    expect(declared, isNot(contains('/more/progress')));
    expect(declared, isNot(contains('/more/progress/photos')));
  });

  test('a screen only links within its own tab', () {
    // `go` to a path in another branch does not simply open that screen: it
    // switches the whole shell to that branch. The row lights a different tab
    // and there is no way back to where you were except the bar — which, on a
    // hub like More, means a row that throws your place away.
    //
    // This caught exactly that: More's link to the stats screen, whose route
    // had been left in the Progress branch. It compiled, it navigated, and
    // every other test passed.
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final shell =
        container.read(goRouterProvider).configuration.routes.first
            as StatefulShellRoute;

    // Which branch each path belongs to.
    final branchOf = <String, int>{};
    for (var i = 0; i < shell.branches.length; i++) {
      for (final path in _declaredPaths(shell.branches[i].routes)) {
        branchOf[path] = i;
      }
    }

    // More's rows navigate through a *variable* — `context.go(tool.route)` —
    // so what has to be read is the table of routes the screen declares, not
    // its call sites. The first version of this test scanned for `.go('…')`
    // literals, found none in that file, and passed with the bug still in.
    final rows = RegExp(r"""route:\s*'(/[^']*)'""")
        .allMatches(
          File('lib/features/more/screens/more_screen.dart').readAsStringSync(),
        )
        .map((m) => m.group(1)!)
        .toList();

    expect(
      rows,
      isNotEmpty,
      reason: 'found no More rows to check — the scan has stopped working',
    );

    for (final row in rows) {
      expect(
        branchOf[_shape(row)],
        branchOf['/more'],
        reason:
            '$row is a More row but lives in another branch, so tapping it '
            'changes tab',
      );
    }
  });

  test('every context.go in the app points at a real route', () {
    final calls = <String, String>{}; // path -> file it appears in
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'),
            )) {
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
