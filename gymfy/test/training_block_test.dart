// Training blocks: N training weeks, one deload week, repeat.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/overload/data/training_block.dart';
import 'package:gymfy/shared/database/app_database.dart';

Split _split({int? blockWeeks, double? deloadPercent, DateTime? startedAt}) =>
    Split(
      id: 1,
      name: 'PPL',
      position: 0,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      blockWeeks: blockWeeks,
      deloadPercent: deloadPercent,
      blockStartedAt: startedAt,
    );

void main() {
  final start = DateTime(2026, 9, 7, 18, 30); // a Monday evening

  group('trainingBlockWeek', () {
    test('is null without a block or before it starts', () {
      expect(
        trainingBlockWeek(blockWeeks: null, startedAt: start, on: start),
        isNull,
      );
      expect(
        trainingBlockWeek(blockWeeks: 0, startedAt: start, on: start),
        isNull,
      );
      expect(
        trainingBlockWeek(blockWeeks: 4, startedAt: null, on: start),
        isNull,
      );
      expect(
        trainingBlockWeek(
          blockWeeks: 4,
          startedAt: start,
          on: DateTime(2026, 9, 6),
        ),
        isNull,
      );
    });

    test('counts training weeks, then a deload, then starts again', () {
      ({int week, bool deload, int cycle}) at(int daysIn) {
        final w = trainingBlockWeek(
          blockWeeks: 3,
          startedAt: start,
          on: DateTime(2026, 9, 7 + daysIn, 8),
        )!;
        return (week: w.week, deload: w.isDeload, cycle: w.cycle);
      }

      // The start day itself is week 1, whatever the time of day.
      expect(at(0), (week: 1, deload: false, cycle: 1));
      expect(at(6), (week: 1, deload: false, cycle: 1));
      expect(at(7), (week: 2, deload: false, cycle: 1));
      expect(at(20), (week: 3, deload: false, cycle: 1));
      expect(at(21), (week: 4, deload: true, cycle: 1));
      expect(at(28), (week: 1, deload: false, cycle: 2));
    });

    test('a daylight-saving change does not move a week boundary', () {
      // Late October crosses the EU clock change.
      final w = trainingBlockWeek(
        blockWeeks: 4,
        startedAt: DateTime(2026, 10, 19),
        on: DateTime(2026, 10, 26),
      )!;
      expect(w.week, 2);
    });
  });

  group('for a split', () {
    test('reads the stored block fields', () {
      final split = _split(blockWeeks: 2, startedAt: start);
      final w = trainingBlockWeekForSplit(split, DateTime(2026, 9, 21))!;
      expect(w.isDeload, isTrue);
    });

    test('a split without a block has no block week', () {
      expect(trainingBlockWeekForSplit(_split(), start), isNull);
    });

    test('deload percent falls back to the conventional 10 % off', () {
      expect(deloadPercentFor(_split()), defaultDeloadPercent);
      expect(deloadPercentFor(_split(deloadPercent: 0)), defaultDeloadPercent);
      expect(
        deloadPercentFor(_split(deloadPercent: 140)),
        defaultDeloadPercent,
      );
      expect(deloadPercentFor(_split(deloadPercent: 60)), 60);
    });
  });
}
