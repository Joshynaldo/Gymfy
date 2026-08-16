// Verifies the calorie table creates, persists, and enforces its constraints.
// In-memory database, no device.
//
// The habit tables that used to be tested here were removed in v17 — the streak
// they existed for is counted from logged workouts now, and lives in
// workout_streak_test.dart.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('calorie entries persist with macros', () async {
    await db.into(db.calorieEntries).insert(
      CalorieEntriesCompanion.insert(
        date: DateTime(2026, 7, 24),
        name: 'Chicken & rice',
        calories: const Value(650),
        protein: const Value(50),
        carbs: const Value(70),
        fat: const Value(12),
      ),
    );

    final rows = await db.select(db.calorieEntries).get();
    expect(rows, hasLength(1));
    expect(rows.single.calories, 650);
    expect(rows.single.protein, 50);
  });

  test('macros default to zero rather than being required', () async {
    // A quick "300 kcal" entry shouldn't demand a macro breakdown nobody has.
    await db.into(db.calorieEntries).insert(
      CalorieEntriesCompanion.insert(
        date: DateTime(2026, 7, 24),
        name: 'Snack',
        calories: const Value(300),
      ),
    );

    final row = (await db.select(db.calorieEntries).get()).single;
    expect(row.protein, 0);
    expect(row.carbs, 0);
    expect(row.fat, 0);
  });
}
