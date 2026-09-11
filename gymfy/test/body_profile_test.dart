// Height and age: the two body facts that are not measurements.
//
// The interesting one is age. It is stored as a *year of birth*, never as a
// number of years — an age written down as "31" is wrong on the next birthday
// and nothing in the app would ever notice or correct it.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymfy/shared/data/body_profile.dart';
import 'package:gymfy/shared/data/settings_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/units.dart';

void main() {
  group('formatHeight', () {
    test('centimetres for a kilogram user', () {
      expect(formatHeight(180, WeightUnit.kg), '180 cm');
    });

    test('feet and inches for a pounds user', () {
      // Follows the weight unit rather than adding a second preference:
      // someone who thinks in pounds thinks in feet, and asking twice would be
      // two ways to say the same thing.
      expect(formatHeight(180, WeightUnit.lbs), '5′ 11″');
      expect(formatHeight(183, WeightUnit.lbs), '6′ 0″');
    });

    test('never reports twelve inches', () {
      // 12 inches is a foot. Rounding up to the next foot has to carry.
      for (var cm = minHeightCm; cm <= maxHeightCm; cm++) {
        expect(
          formatHeight(cm, WeightUnit.lbs),
          isNot(contains('12″')),
          reason: '$cm cm',
        );
      }
    });
  });

  group('birthYearForAge', () {
    test('turns an age into the year it implies', () {
      expect(birthYearForAge(30, now: DateTime(2026, 9, 5)), 1996);
    });

    test('round-trips back to the same age', () {
      final now = DateTime(2026, 9, 5);
      for (var age = minAge; age <= maxAge; age++) {
        expect(now.year - birthYearForAge(age, now: now), age);
      }
    });
  });

  group('stored profile', () {
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

    Future<T> firstValue<T>(StreamProvider<T> provider) {
      container.listen(provider, (_, _) {});
      return container.read(provider.future);
    }

    test('unset reads as null, not as zero', () async {
      expect(await firstValue(heightCmProvider), isNull);
      expect(await firstValue(birthYearProvider), isNull);
    });

    test('a stored height comes back', () async {
      await container
          .read(settingsRepositoryProvider)
          .write(heightCmSetting, '183');

      expect(await firstValue(heightCmProvider), 183);
    });

    test('an impossible height reads as unset rather than showing', () async {
      // A hand-edited database or a future build shouldn't put "7 cm" on
      // screen. Out of range is treated as absent, which every caller handles.
      for (final raw in ['7', '400', 'tall', '']) {
        await container
            .read(settingsRepositoryProvider)
            .write(heightCmSetting, raw);

        expect(await firstValue(heightCmProvider), isNull, reason: raw);
      }
    });

    test('age is derived from the year, so it ages with you', () async {
      // The whole reason a year is stored rather than a number: someone who
      // said "30" in 2026 is 31 in 2027 without touching anything.
      final now = DateTime.now().year;
      await container
          .read(settingsRepositoryProvider)
          .write(birthYearSetting, '${now - 30}');

      await firstValue(birthYearProvider);
      expect(container.read(ageProvider), 30);
    });

    test('a year implying an absurd age reads as unset', () async {
      await container
          .read(settingsRepositoryProvider)
          .write(birthYearSetting, '1200');

      expect(await firstValue(birthYearProvider), isNull);
      await firstValue(birthYearProvider);
      expect(container.read(ageProvider), isNull);
    });
  });
}
