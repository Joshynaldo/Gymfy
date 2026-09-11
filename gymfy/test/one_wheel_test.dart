// There is one wheel widget, and everything that scrolls numbers uses it.
//
// Written because there were three. `shared/widgets/number_wheel.dart`, a
// private copy in the day builder's sets & reps dialog, and a third inside the
// picker sheets — all doing the same job with slightly different item heights,
// highlight colours and padding. Nothing was broken by that, which is exactly
// why it survived: three controls wearing one costume look fine until you put
// two of them on screen together.
//
// A source-level check rather than a widget test, because the failure it
// guards against is someone reaching for `ListWheelScrollView` directly rather
// than any particular thing appearing on screen.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The one file allowed to build a wheel from scratch.
const _wheelImplementation = 'lib\\shared\\widgets\\number_wheel.dart';

void main() {
  test('only NumberWheel builds a ListWheelScrollView', () {
    final offenders = <String>[];

    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'),
            )) {
      final normalised = file.path.replaceAll('/', r'\');
      if (normalised.endsWith(_wheelImplementation)) continue;
      if (file.readAsStringSync().contains('ListWheelScrollView')) {
        offenders.add(file.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These build their own wheel instead of using NumberWheel:\n'
          '${offenders.join('\n')}',
    );
  });

  test('the shared wheel is actually used in more than one place', () {
    // The other half of the same rule: a single implementation nobody imports
    // would satisfy the check above and mean nothing.
    final importers = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.readAsStringSync().contains('number_wheel.dart'))
        .length;

    // The wheel's own file plus the sets/reps dialog, the weight wheel and the
    // picker sheets.
    expect(importers, greaterThanOrEqualTo(3));
  });
}
