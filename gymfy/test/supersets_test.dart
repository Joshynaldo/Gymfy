// Superset grouping: which planned exercises are done back to back, and when
// the rest timer starts.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/workout/data/supersets.dart';

/// (name, group) pairs stand in for planned exercises.
typedef _Item = (String, int?);

int? _group(_Item item) => item.$2;

List<List<String>> _names(List<List<_Item>> blocks) => [
  for (final block in blocks) [for (final item in block) item.$1],
];

void main() {
  group('supersetBlocks', () {
    test('standalone exercises are blocks of one', () {
      final day = <_Item>[('bench', null), ('row', null)];
      expect(_names(supersetBlocks(day, _group)), [
        ['bench'],
        ['row'],
      ]);
    });

    test('neighbours sharing a group form one block', () {
      final day = <_Item>[
        ('bench', null),
        ('curl', 1),
        ('pushdown', 1),
        ('raise', 2),
        ('fly', 2),
        ('squat', null),
      ];
      expect(_names(supersetBlocks(day, _group)), [
        ['bench'],
        ['curl', 'pushdown'],
        ['raise', 'fly'],
        ['squat'],
      ]);
    });

    test('members split apart by another exercise are two blocks', () {
      final day = <_Item>[('curl', 1), ('bench', null), ('pushdown', 1)];
      expect(_names(supersetBlocks(day, _group)), [
        ['curl'],
        ['bench'],
        ['pushdown'],
      ]);
    });

    test('an empty day has no blocks', () {
      expect(supersetBlocks(<_Item>[], _group), isEmpty);
    });
  });

  group('restsAfter', () {
    const _Item curl = ('curl', 1);
    const _Item pushdown = ('pushdown', 1);
    const _Item bench = ('bench', null);
    final day = [bench, curl, pushdown];

    test('rest waits for the last exercise of a superset', () {
      expect(restsAfter(day, curl, _group), isFalse);
      expect(restsAfter(day, pushdown, _group), isTrue);
    });

    test('a standalone exercise rests as it always did', () {
      expect(restsAfter(day, bench, _group), isTrue);
    });

    test('an exercise not in the list rests', () {
      expect(restsAfter(day, ('squat', 1), _group), isTrue);
    });
  });
}
