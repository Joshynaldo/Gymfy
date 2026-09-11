// Loading a barbell: the arithmetic, the float traps, and what happens when the
// target isn't reachable with the plates on hand.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/plates/data/plate_math.dart';
import 'package:gymfy/shared/data/settings_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/units.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  List<double> sideFor(
    double target, {
    double bar = 20,
    List<double> plates = defaultPlatesKg,
  }) {
    return calculatePlates(target: target, bar: bar, plates: plates).perSide;
  }

  group('calculatePlates', () {
    test('an empty bar needs no plates', () {
      final load = calculatePlates(
        target: 20,
        bar: 20,
        plates: defaultPlatesKg,
      );

      expect(load.perSide, isEmpty);
      expect(load.achieved, 20);
      expect(load.isExact, isTrue);
      expect(load.belowBar, isFalse);
    });

    test('plates go on in pairs', () {
      // 60 kg = 20 kg bar + 20 kg a side.
      expect(sideFor(60), [20]);
    });

    test('uses the heaviest plates first', () {
      // 100 kg = 20 bar + 40 a side, which is 25 + 15, not 20 + 20 or eight 5s.
      expect(sideFor(100), [25, 15]);
    });

    test('repeats a plate when it is needed twice', () {
      expect(sideFor(140), [25, 25, 10]);
    });

    test('handles the classic 102.5 kg', () {
      // The case that catches naive float arithmetic.
      expect(sideFor(102.5), [25, 15, 1.25]);
    });

    test('a weight below the bar is called out, not made negative', () {
      final load = calculatePlates(
        target: 10,
        bar: 20,
        plates: defaultPlatesKg,
      );

      expect(load.belowBar, isTrue);
      expect(load.perSide, isEmpty);
      // The bar's own weight, not a negative number.
      expect(load.achieved, 20);
    });

    test('an unreachable target gives the closest loadable weight under it', () {
      // 61 kg wants 20.5 a side; after the 20 goes on, 0.5 is left and the
      // lightest plate here is 1.25.
      final load = calculatePlates(
        target: 61,
        bar: 20,
        plates: defaultPlatesKg,
      );

      expect(load.perSide, [20]);
      expect(load.achieved, 60);
      expect(load.isExact, isFalse);
      // Reported as a shortfall rather than silently rounded, because "closest
      // I can load" is a different fact from "your target".
      expect(load.difference, -1);
    });

    test('never overshoots the target', () {
      for (var target = 20.0; target <= 200; target += 1.25) {
        final load = calculatePlates(
          target: target,
          bar: 20,
          plates: defaultPlatesKg,
        );
        expect(
          load.achieved,
          lessThanOrEqualTo(target + 0.001),
          reason: 'overshot at $target',
        );
      }
    });

    test('every 2.5 kg step is loadable exactly', () {
      // Float dust would show up here first: 2.5 * 3 is 7.500000000000001, and
      // without an epsilon a perfectly loadable weight comes back short.
      for (var target = 20.0; target <= 220; target += 2.5) {
        final load = calculatePlates(
          target: target,
          bar: 20,
          plates: defaultPlatesKg,
        );
        expect(load.isExact, isTrue, reason: '$target was not exact');
      }
    });

    test('the plate list need not be sorted', () {
      expect(sideFor(100, plates: const [5, 25, 2.5, 15, 20, 10, 1.25]), [
        25,
        15,
      ]);
    });

    test('no plates at all means just the bar', () {
      final load = calculatePlates(target: 100, bar: 20, plates: const []);

      expect(load.perSide, isEmpty);
      expect(load.achieved, 20);
    });

    test('a restricted inventory only uses what is there', () {
      // A home gym with nothing lighter than 10 kg.
      final load = calculatePlates(
        target: 100,
        bar: 20,
        plates: const [20, 10],
      );

      expect(load.perSide, [20, 20]);
      expect(load.achieved, 100);
    });

    test('pounds work the same way with pound plates', () {
      final load = calculatePlates(
        target: 225,
        bar: 45,
        plates: defaultPlatesLbs,
      );

      // The most famous bar load there is: two 45s a side on a 45 lb bar.
      expect(load.perSide, [45, 45]);
      expect(load.achieved, 225);
    });
  });
  group('plateColor', () {
    test('uses the competition colours for kilo plates', () {
      // Hardcoded on purpose: a 20 kg plate is blue in every gym on earth, and
      // recolouring it to the accent would throw away the fastest way to read a
      // loaded bar.
      expect(
        plateColor(25, WeightUnit.kg),
        isNot(plateColor(20, WeightUnit.kg)),
      );
      expect(
        plateColor(20, WeightUnit.kg),
        isNot(plateColor(15, WeightUnit.kg)),
      );
      expect(
        plateColor(15, WeightUnit.kg),
        isNot(plateColor(10, WeightUnit.kg)),
      );
    });

    test('the small plates repeat the big ones colours', () {
      // 2.5 is red like 25, 2 is blue like 20 — that is how calibrated sets are
      // made, and copying it means one habit reads both.
      expect(plateColor(2.5, WeightUnit.kg), plateColor(25, WeightUnit.kg));
      expect(plateColor(2, WeightUnit.kg), plateColor(20, WeightUnit.kg));
    });

    test('an unknown plate gets a neutral colour, not an invented one', () {
      expect(plateColor(3.75, WeightUnit.kg), plateColor(1.25, WeightUnit.kg));
    });

    test('pound plates rank the same way', () {
      expect(plateColor(45, WeightUnit.lbs), plateColor(20, WeightUnit.kg));
      expect(plateColor(35, WeightUnit.lbs), plateColor(15, WeightUnit.kg));
    });

    test('light plates ask for a dark label', () {
      // A white 5 kg plate with white text on it would be unreadable.
      expect(plateNeedsDarkLabel(plateColor(5, WeightUnit.kg)), isTrue);
      expect(plateNeedsDarkLabel(plateColor(25, WeightUnit.kg)), isFalse);
    });
  });

  group('groupPlates', () {
    test('collapses runs into counts', () {
      expect(groupPlates([25, 25, 10]), [
        (plate: 25.0, count: 2),
        (plate: 10.0, count: 1),
      ]);
    });

    test('an empty load groups to nothing', () {
      expect(groupPlates([]), isEmpty);
    });
  });

  group('formatPlate', () {
    test('drops a pointless decimal', () {
      expect(formatPlate(20), '20');
      expect(formatPlate(2.5), '2.5');
      expect(formatPlate(1.25), '1.25');
    });
  });

  group('parsePlates', () {
    test('reads what encodePlates writes', () {
      final encoded = encodePlates([2.5, 25, 10]);

      expect(encoded, '25,10,2.5');
      expect(parsePlates(encoded, fallback: const []), [25, 10, 2.5]);
    });

    test('always comes back heaviest first', () {
      expect(parsePlates('2.5,25,10', fallback: const []), [25, 10, 2.5]);
    });

    test('an unset value falls back to the defaults', () {
      expect(parsePlates(null, fallback: defaultPlatesKg), defaultPlatesKg);
      expect(parsePlates('  ', fallback: defaultPlatesKg), defaultPlatesKg);
    });

    test('junk falls back rather than leaving no plates', () {
      // A broken setting must not make the calculator answer "just the bar" to
      // everything.
      expect(parsePlates('abc,,-', fallback: defaultPlatesKg), defaultPlatesKg);
    });

    test('unreadable entries are skipped, readable ones kept', () {
      expect(parsePlates('25,oops,10', fallback: const []), [25, 10]);
    });

    test('zero and negative plates are ignored', () {
      expect(parsePlates('25,0,-5', fallback: const []), [25]);
    });
  });

  group('the stored inventory', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<void> settle() async {
      container.listen(availablePlatesProvider, (_, _) {});
      container.listen(barWeightProvider, (_, _) {});
      await container.read(storedWeightUnitProvider.future);
    }

    test('starts on the kilo defaults', () async {
      await settle();

      expect(container.read(availablePlatesProvider), defaultPlatesKg);
      expect(container.read(barWeightProvider), 20);
    });

    test('switching to pounds switches the whole inventory', () async {
      await container
          .read(settingsRepositoryProvider)
          .write(weightUnitSetting, 'lbs');
      await settle();
      await container.read(rawSettingProvider(platesLbsSetting).future);

      // Not converted — a pound gym owns different physical plates, and a
      // "20.41 kg plate" is a weight nobody has.
      expect(container.read(availablePlatesProvider), defaultPlatesLbs);
      expect(container.read(barWeightProvider), 45);
    });

    test('a stored inventory is used instead of the defaults', () async {
      await container
          .read(settingsRepositoryProvider)
          .write(platesKgSetting, '20,10,5');
      await settle();
      await container.read(rawSettingProvider(platesKgSetting).future);

      expect(container.read(availablePlatesProvider), [20, 10, 5]);
    });

    test('a bar weight we do not offer falls back to the standard one', () async {
      await container
          .read(settingsRepositoryProvider)
          .write(barKgSetting, '17');
      await settle();
      await container.read(rawSettingProvider(barKgSetting).future);

      // A value from some other build shouldn't put an unloadable bar on screen.
      expect(container.read(barWeightProvider), 20);
    });

    test('a bar weight we do offer is used', () async {
      await container
          .read(settingsRepositoryProvider)
          .write(barKgSetting, '15');
      await settle();
      await container.read(rawSettingProvider(barKgSetting).future);

      expect(container.read(barWeightProvider), 15);
    });
  });
}
