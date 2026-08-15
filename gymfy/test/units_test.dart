// Weight units: converting at the edges, and never touching what's stored.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/shared/data/settings_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/format.dart';
import 'package:gymfy/shared/utils/units.dart';

void main() {
  group('WeightUnit.parse', () {
    test('reads back what was written', () {
      expect(WeightUnit.parse('kg'), WeightUnit.kg);
      expect(WeightUnit.parse('lbs'), WeightUnit.lbs);
    });

    test('anything unreadable falls back to kilograms', () {
      // Worst case is the user picking their unit again, never a screen that
      // can't render a weight.
      expect(WeightUnit.parse(null), WeightUnit.kg);
      expect(WeightUnit.parse(''), WeightUnit.kg);
      expect(WeightUnit.parse('pounds'), WeightUnit.kg);
      expect(WeightUnit.parse('KG'), WeightUnit.kg);
    });
  });

  group('converting', () {
    test('kilograms are left completely alone', () {
      // Not a rounding-tolerant check on purpose: choosing kg must be a no-op,
      // not a conversion that happens to land back where it started.
      expect(weightIn(82.5, WeightUnit.kg), 82.5);
      expect(weightToKilograms(82.5, WeightUnit.kg), 82.5);
    });

    test('kilograms to pounds', () {
      expect(weightIn(100, WeightUnit.lbs), closeTo(220.462, 0.001));
      expect(weightIn(20, WeightUnit.lbs), closeTo(44.092, 0.001));
    });

    test('pounds to kilograms', () {
      expect(weightToKilograms(220.462, WeightUnit.lbs), closeTo(100, 0.001));
      // The Olympic bar, which is where the definition of "45 lbs" comes from.
      expect(weightToKilograms(45, WeightUnit.lbs), closeTo(20.412, 0.001));
    });

    test('a round trip through pounds comes back unchanged', () {
      // This is the property that matters: storage is always kilograms, so
      // display and entry must be exact inverses or weights would drift every
      // time a set was edited.
      for (final kg in [1.0, 20.0, 62.5, 82.5, 100.0, 227.5]) {
        final shown = weightIn(kg, WeightUnit.lbs);
        expect(weightToKilograms(shown, WeightUnit.lbs), closeTo(kg, 1e-9));
      }
    });
  });

  group('roundToLoadable', () {
    test('kilograms snap to the half', () {
      expect(roundToLoadable(62.4, WeightUnit.kg), 62.5);
      expect(roundToLoadable(62.6, WeightUnit.kg), 62.5);
      expect(roundToLoadable(100.2, WeightUnit.kg), 100.0);
    });

    test('pounds snap to the pound, not to half a kilo', () {
      // 62.5 kg is 137.79 lbs. Rounding in kilograms and converting would show
      // that verbatim; rounding in pounds gives a number you could load.
      final rounded = roundToLoadable(62.5, WeightUnit.lbs);
      expect(weightIn(rounded, WeightUnit.lbs), closeTo(138, 1e-9));
    });

    test('a loadable weight is already loadable', () {
      expect(roundToLoadable(62.5, WeightUnit.kg), 62.5);
    });
  });

  group('formatting', () {
    test('kilograms read as before', () {
      expect(formatWeightUnit(62.5, WeightUnit.kg), '62.5 kg');
      expect(formatWeightUnit(100, WeightUnit.kg), '100 kg');
    });

    test('pounds are rounded rather than shown to five decimals', () {
      // The whole point: 62.5 kg must not surface as "137.78865 lbs".
      expect(formatWeightUnit(62.5, WeightUnit.lbs), '138 lbs');
      expect(formatWeightUnit(100, WeightUnit.lbs), '220 lbs');
    });

    test('the bare form leaves the label to the caller', () {
      expect(formatWeightIn(62.5, WeightUnit.kg), '62.5');
      expect(formatWeightIn(100, WeightUnit.lbs), '220.5');
    });
  });

  group('parseWeight', () {
    test('accepts a comma as the decimal separator', () {
      expect(parseWeight('62,5'), 62.5);
      expect(parseWeight('62.5'), 62.5);
      expect(parseWeight(' 80 '), 80);
    });

    test('rejects empty, non-numeric and non-positive text', () {
      expect(parseWeight(''), isNull);
      expect(parseWeight('abc'), isNull);
      expect(parseWeight('0'), isNull);
      expect(parseWeight('-5'), isNull);
    });
  });

  group('parseWeightAsKilograms', () {
    test('a typed weight is stored in kilograms', () {
      expect(parseWeightAsKilograms('100', WeightUnit.kg), 100);
      expect(
        parseWeightAsKilograms('220.462', WeightUnit.lbs),
        closeTo(100, 0.001),
      );
    });

    test('a comma decimal still works in either unit', () {
      // German keyboards put the comma on the number row.
      expect(parseWeightAsKilograms('82,5', WeightUnit.kg), 82.5);
      expect(
        parseWeightAsKilograms('181,9', WeightUnit.lbs),
        closeTo(82.51, 0.01),
      );
    });

    test('nonsense is rejected rather than stored', () {
      expect(parseWeightAsKilograms('', WeightUnit.lbs), isNull);
      expect(parseWeightAsKilograms('heavy', WeightUnit.lbs), isNull);
      expect(parseWeightAsKilograms('0', WeightUnit.lbs), isNull);
      expect(parseWeightAsKilograms('-10', WeightUnit.lbs), isNull);
    });
  });

  group('the stored preference', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() {
        container.dispose();
        return db.close();
      });
    });

    test('defaults to kilograms before anything is stored', () {
      expect(container.read(weightUnitProvider), WeightUnit.kg);
    });

    test('a stored choice is picked up', () async {
      container.listen(storedWeightUnitProvider, (_, _) {});
      await container
          .read(settingsRepositoryProvider)
          .write(weightUnitSetting, 'lbs');

      // Wait for the settings stream to carry the change through.
      await container.read(storedWeightUnitProvider.future);
      expect(container.read(weightUnitProvider), WeightUnit.lbs);
    });

    test('an unreadable stored value still shows kilograms', () async {
      container.listen(storedWeightUnitProvider, (_, _) {});
      await container
          .read(settingsRepositoryProvider)
          .write(weightUnitSetting, 'stones');

      await container.read(storedWeightUnitProvider.future);
      expect(container.read(weightUnitProvider), WeightUnit.kg);
    });
  });
}
