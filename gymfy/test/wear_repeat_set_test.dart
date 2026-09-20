// Logging a set from the wrist.
//
// This is the first thing the watch can do that *writes*, so it is the
// first place a watch bug can cost you real training data. A missed set is
// annoying; an invented one is worse, because months later there is nothing
// in the history that says it did not happen.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/wear/data/wear_sync.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/units.dart';

LoggedSet _set({
  int id = 1,
  String exerciseId = 'bench',
  double weight = 80,
  int reps = 8,
  bool isWarmup = false,
  int? seconds,
}) => LoggedSet(
  id: id,
  sessionId: 1,
  exerciseId: exerciseId,
  setNumber: id,
  weight: weight,
  reps: reps,
  isWarmup: isWarmup,
  seconds: seconds,
);

void main() {
  group('picking the set to repeat', () {
    test('takes the most recent working set', () {
      final last = lastWorkingSet([
        _set(id: 1, weight: 60),
        _set(id: 2, weight: 80),
      ]);

      expect(last?.weight, 80);
    });

    test('skips warm-ups, however recent', () {
      // "Do it again" after a warm-up means the working set, not the
      // empty-bar one. Repeating a warm-up *as a working set* would also
      // feed progressive overload the lightest set of the session, which
      // reads the top set and would quietly stall your programme.
      final last = lastWorkingSet([
        _set(id: 1, weight: 80),
        _set(id: 2, weight: 20, isWarmup: true),
      ]);

      expect(last?.weight, 80);
    });

    test('and finds nothing when there are only warm-ups', () {
      expect(lastWorkingSet([_set(isWarmup: true)]), isNull);
    });

    test('or no sets at all', () {
      expect(lastWorkingSet(const []), isNull);
    });
  });

  group('the button label', () {
    test('reads as weight and reps in the display unit', () {
      expect(
        describeRepeatableSet(_set(weight: 80, reps: 8), WeightUnit.kg),
        '80 kg x 8',
      );
    });

    test('converts for a lbs user', () {
      final label = describeRepeatableSet(
        _set(weight: 100, reps: 5),
        WeightUnit.lbs,
      );

      expect(label, contains('lbs'));
      expect(label, isNot(contains('kg')));
    });

    test('says reps alone for a bodyweight set', () {
      // "0 kg x 12" is not a thing anyone did.
      expect(
        describeRepeatableSet(_set(weight: 0, reps: 12), WeightUnit.kg),
        '12 reps',
      );
    });

    test('is empty for a timed hold, so no button is offered', () {
      // A hold has no reps to repeat, and "the same again" means holding
      // still for a while — not something a button can do for you. Empty
      // is also how the watch decides not to show the button, so this is
      // the whole guard.
      expect(
        describeRepeatableSet(_set(seconds: 45, reps: 0), WeightUnit.kg),
        isEmpty,
      );
    });

    test('and empty when there is nothing to repeat', () {
      expect(describeRepeatableSet(null, WeightUnit.kg), isEmpty);
    });
  });
}
