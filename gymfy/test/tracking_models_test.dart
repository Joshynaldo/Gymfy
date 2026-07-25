// Verifies the Phase 7 tracking tables (calories + habits) create, persist,
// and enforce their constraints. In-memory database, no device.

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

  test('deleting a habit cascades to its entries', () async {
    final habitId = await db.into(db.habits).insert(
      HabitsCompanion.insert(name: 'Drink 3L water'),
    );
    await db.into(db.habitEntries).insert(
      HabitEntriesCompanion.insert(habitId: habitId, date: DateTime(2026, 7, 24)),
    );

    await (db.delete(db.habits)..where((t) => t.id.equals(habitId))).go();

    final remaining = await db.select(db.habitEntries).get();
    expect(remaining, isEmpty);
  });

  test('a habit can only be completed once per day', () async {
    final habitId = await db.into(db.habits).insert(
      HabitsCompanion.insert(name: 'Stretch'),
    );
    final day = DateTime(2026, 7, 24);
    await db.into(db.habitEntries).insert(
      HabitEntriesCompanion.insert(habitId: habitId, date: day),
    );

    // Second insert for the same habit + day violates the unique key.
    expect(
      () => db.into(db.habitEntries).insert(
        HabitEntriesCompanion.insert(habitId: habitId, date: day),
      ),
      throwsA(isA<Exception>()),
    );
  });
}
