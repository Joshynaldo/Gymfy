// The per-exercise bar weight.
//
// "Plate-loaded" does not mean "on a barbell". A hack squat, a leg press and a
// plate-loaded T-bar all take plates onto a carriage that does not weigh 20 kg
// — and the calculator was adding a bar that wasn't there, so every total on
// those machines was wrong by exactly one bar.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
import 'package:gymfy/features/plates/data/plate_math.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/units.dart';

void main() {
  group('barOptionsFor', () {
    test('offers no-bar last, so it never reads as the default', () {
      for (final unit in WeightUnit.values) {
        final options = barOptionsFor(unit);
        expect(options.last, 0);
        expect(options.first, isNot(0), reason: 'zero must not be the default');
      }
    });

    test('keeps the real bars, in their own unit', () {
      // Nothing is converted: a 45 lb bar is not a 20.4 kg bar.
      expect(barOptionsFor(WeightUnit.kg), containsAll(barsKg));
      expect(barOptionsFor(WeightUnit.lbs), containsAll(barsLbs));
    });

    test('reads as "None" rather than "0 kg"', () {
      // "0 kg" invites the question of whether it's a bug.
      expect(formatBar(0, WeightUnit.kg), 'None');
      expect(formatBar(20, WeightUnit.kg), '20 kg');
      expect(formatBar(45, WeightUnit.lbs), '45 lbs');
    });
  });

  group('barForExercise', () {
    test('falls back to the gym default when unset', () {
      // Which is every exercise until someone says otherwise.
      expect(barForExercise(null, 20, WeightUnit.kg), 20);
      expect(barForExercise(null, 45, WeightUnit.lbs), 45);
    });

    test('zero means zero in either unit', () {
      // Not "convert zero kilograms into pounds" — no bar is no bar.
      expect(barForExercise(0, 20, WeightUnit.kg), 0);
      expect(barForExercise(0, 45, WeightUnit.lbs), 0);
    });

    test('a stored bar is converted for display, not reinterpreted', () {
      // Stored in kilograms like every other weight. A 20 kg bar must not
      // become a 20 lb one just because the display unit changed.
      expect(barForExercise(20, 45, WeightUnit.kg), 20);
      expect(barForExercise(20, 45, WeightUnit.lbs), closeTo(44.09, 0.01));
    });
  });

  group('a bar of zero', () {
    test('the whole target is plates', () {
      final load = calculatePlates(
        target: 100,
        bar: 0,
        plates: defaultPlatesKg,
      );

      expect(load.achieved, 100);
      expect(load.perSide.fold<double>(0, (s, p) => s + p) * 2, 100);
      expect(load.isExact, isTrue);
    });

    test('nothing is ever below an absent bar', () {
      // `belowBar` is what shows "lighter than the bar itself". With no bar
      // there is no such thing, and any positive target is loadable.
      final load = calculatePlates(target: 5, bar: 0, plates: defaultPlatesKg);

      expect(load.belowBar, isFalse);
    });
  });

  group('storing it on the exercise', () {
    late AppDatabase db;
    late ExerciseRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = ExerciseRepository(db);
      await repo.seed();
    });

    tearDown(() async => db.close());

    Future<double?> barOf(String id) async {
      final row = await (db.select(
        db.exercises,
      )..where((t) => t.id.equals(id))).getSingle();
      return row.barWeightKg;
    }

    test('starts unset, so nothing changes until asked', () async {
      expect(await barOf('leg_press'), isNull);
    });

    test('remembers zero as a real answer, not as unset', () async {
      // The distinction the whole feature rests on: null means "use the gym
      // default", zero means "there is no bar".
      await repo.setBarWeight('leg_press', 0);

      expect(await barOf('leg_press'), 0);
      expect(barForExercise(await barOf('leg_press'), 20, WeightUnit.kg), 0);
    });

    test('survives the seed upsert that runs on every launch', () async {
      // The reason this column is deliberately absent from the seed
      // companions. `insertAllOnConflictUpdate` rewrites every built-in row at
      // startup, but only the columns those companions carry — so a value the
      // user chose has to be on a column the seed never mentions. If that ever
      // stops being true, a leg press would silently regrow a 20 kg bar on the
      // next app start.
      await repo.setBarWeight('leg_press', 0);
      await repo.setBarWeight('barbell_bench_press', 15);

      await repo.seed();
      await repo.seed();

      expect(await barOf('leg_press'), 0);
      expect(await barOf('barbell_bench_press'), 15);
    });

    test('can be cleared back to the gym default', () async {
      await repo.setBarWeight('leg_press', 0);
      await repo.setBarWeight('leg_press', null);

      expect(await barOf('leg_press'), isNull);
    });

    test('touches only the exercise it names', () async {
      await repo.setBarWeight('leg_press', 0);

      expect(await barOf('hack_squat'), isNull);
    });
  });
}
