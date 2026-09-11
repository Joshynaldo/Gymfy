// The two inputs a strength rank needs: the lifter's sex (a stored setting) and
// their latest logged bodyweight (read from the measurements they already keep).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/calculator/data/rank_inputs.dart';
import 'package:gymfy/features/progress/data/measurements_repository.dart';
import 'package:gymfy/shared/data/settings_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/models/body_measurement.dart';

void main() {
  group('parseLifterSex', () {
    test('round-trips what the repository stores', () {
      for (final sex in LifterSex.values) {
        expect(parseLifterSex(sex.name), sex);
      }
    });

    test('unknown and missing values read as "not set"', () {
      // A hand-edited database or a value from a future version must not crash
      // a screen — it just means we still have to ask.
      expect(parseLifterSex(null), isNull);
      expect(parseLifterSex(''), isNull);
      expect(parseLifterSex('nonbinary'), isNull);
      expect(parseLifterSex('MALE'), isNull);
    });
  });

  group('settings storage', () {
    late AppDatabase db;
    late SettingsRepository settings;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      settings = SettingsRepository(db);
    });

    tearDown(() => db.close());

    test('an unset setting is null, not an empty string', () async {
      expect(await settings.readRaw(lifterSexSetting), isNull);
    });

    test('writing then reading gives the value back', () async {
      await settings.write(lifterSexSetting, LifterSex.female.name);
      expect(
        parseLifterSex(await settings.readRaw(lifterSexSetting)),
        LifterSex.female,
      );
    });

    test(
      'writing the same key twice replaces rather than duplicates',
      () async {
        await settings.write(lifterSexSetting, LifterSex.male.name);
        await settings.write(lifterSexSetting, LifterSex.female.name);

        final rows = await db.select(db.appSettings).get();
        expect(rows.length, 1);
        expect(rows.single.value, LifterSex.female.name);
      },
    );

    test('settings do not collide with each other', () async {
      await settings.write(lifterSexSetting, LifterSex.male.name);
      await settings.write('units', 'lbs');

      expect(await settings.readRaw(lifterSexSetting), LifterSex.male.name);
      expect(await settings.readRaw('units'), 'lbs');
    });

    test('clearing makes it unset again', () async {
      await settings.write(lifterSexSetting, LifterSex.male.name);
      await settings.clear(lifterSexSetting);
      expect(await settings.readRaw(lifterSexSetting), isNull);
    });

    test('the stream reports changes as they happen', () async {
      final seen = <String?>[];
      final sub = settings.watchRaw(lifterSexSetting).listen(seen.add);
      // Let the initial "unset" value land before writing, otherwise the first
      // emission we see is already the written one.
      await pumpEventQueue();

      await settings.write(lifterSexSetting, LifterSex.male.name);
      await pumpEventQueue();
      await settings.write(lifterSexSetting, LifterSex.female.name);
      await pumpEventQueue();
      await sub.cancel();

      expect(seen.last, LifterSex.female.name);
      expect(seen.first, isNull); // starts out unset
    });
  });

  group('latest bodyweight', () {
    late AppDatabase db;
    late MeasurementsRepository measurements;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      measurements = MeasurementsRepository(db);
    });

    tearDown(() => db.close());

    /// Mirrors what latestBodyweightProvider does with the history rows.
    MeasurementPoint? latestFrom(List<BodyMeasurement> history) {
      for (final row in history) {
        final weight = valueOf(row, MeasurementField.weight);
        if (weight != null) return (day: row.date, value: weight);
      }
      return null;
    }

    test('nothing measured means no bodyweight', () async {
      expect(latestFrom(await measurements.watchAll().first), isNull);
    });

    test('takes the newest weigh-in', () async {
      await measurements.setField(
        day: DateTime(2026, 7, 1),
        field: MeasurementField.weight,
        value: 84,
      );
      await measurements.setField(
        day: DateTime(2026, 7, 20),
        field: MeasurementField.weight,
        value: 82.5,
      );

      final latest = latestFrom(await measurements.watchAll().first)!;
      expect(latest.value, 82.5);
      expect(latest.day, DateTime(2026, 7, 20));
    });

    test('skips newer days that recorded no weight', () async {
      await measurements.setField(
        day: DateTime(2026, 7, 1),
        field: MeasurementField.weight,
        value: 84,
      );
      // A later day where only the waist was measured must not hide the weight
      // or read as zero.
      await measurements.setField(
        day: DateTime(2026, 7, 20),
        field: MeasurementField.waist,
        value: 81,
      );

      final latest = latestFrom(await measurements.watchAll().first)!;
      expect(latest.value, 84);
      expect(latest.day, DateTime(2026, 7, 1));
    });
  });
}
