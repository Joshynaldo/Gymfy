// The redesign reaches every screen, not just the ones that were checked.
//
// Source-level, for the same reason `one_wheel_test.dart` is: the failure being
// guarded against is somebody reaching for the Material widget directly on a
// new screen, which is not a thing that shows up as a wrong pixel anywhere in
// particular. It shows up as one screen out of thirty that quietly looks like
// the old app.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every Dart source file in the app, generated ones excluded.
Iterable<File> _sources() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));

/// Windows and POSIX separators both, so the checks read the same either way.
String _path(File file) => file.path.replaceAll(r'\', '/');

void main() {
  test('no screen builds a bare Material Card', () {
    // AppCard is where the surface is decided — the glass pane, the press
    // scale, the top highlight, the outline rule for AMOLED and high contrast.
    // A raw Card gets none of it, which is how the whole Home tab ended up
    // looking a generation behind the rest of the app without anyone noticing.
    final offenders = [
      for (final file in _sources())
        if (RegExp(r'(?<![A-Za-z_])Card\(').hasMatch(file.readAsStringSync()))
          _path(file),
    ];

    expect(
      offenders,
      isEmpty,
      reason:
          'These build a Material Card instead of an AppCard:\n'
          '${offenders.join('\n')}',
    );
  });

  test('a screen with a glass app bar puts its body behind it', () {
    // The two halves of the same arrangement. A GlassAppBar on a plain Scaffold
    // is a translucent bar with the content stopping dead underneath it — the
    // blur filters nothing, and the effect is a tinted rectangle.
    final offenders = <String>[];

    for (final file in _sources()) {
      final source = file.readAsStringSync();
      if (!source.contains('appBar: GlassAppBar') &&
          !source.contains('appBar: const GlassAppBar') &&
          !source.contains('? GlassAppBar')) {
        continue;
      }
      if (!source.contains('GlassScaffold(')) offenders.add(_path(file));
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These wear the glass bar but lay their body out beneath it:\n'
          '${offenders.join('\n')}',
    );
  });

  test('no screen still builds a bare AlertDialog', () {
    // GlassDialog *is* an AlertDialog on the flat themes, so the only file
    // allowed to name one is the one that falls back to it.
    const implementation = 'lib/shared/widgets/glass_dialog.dart';

    final offenders = [
      for (final file in _sources())
        if (!_path(file).endsWith(implementation) &&
            file.readAsStringSync().contains('AlertDialog('))
          _path(file),
    ];

    expect(
      offenders,
      isEmpty,
      reason:
          'These build a plain AlertDialog instead of a GlassDialog:\n'
          '${offenders.join('\n')}',
    );
  });

  test('the shared pieces are used widely enough to be shared', () {
    // The counterpart to the three rules above. Each of them would be satisfied
    // by a widget nobody calls, and a design system nothing uses is just more
    // code.
    int usersOf(String name) => _sources()
        .where((f) => !_path(f).endsWith('${_snake(name)}.dart'))
        .where((f) => f.readAsStringSync().contains('$name('))
        .length;

    expect(usersOf('GlassScaffold'), greaterThan(10));
    expect(usersOf('GlassAppBar'), greaterThan(10));
    expect(usersOf('GlassDialog'), greaterThan(5));
    expect(usersOf('AppCard'), greaterThan(5));
  });
}

/// `GlassAppBar` -> `glass_app_bar`, so a widget's own file can be skipped.
String _snake(String name) => name
    .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) => '${m[1]}_${m[2]}')
    .toLowerCase();
