// Unit tests for the habit streak calculation. Pure logic, no database.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/habits/data/habit_repository.dart';

void main() {
  final today = DateTime(2026, 7, 24);
  DateTime daysAgo(int n) => DateTime(2026, 7, 24 - n);

  test('no completed days means no streak', () {
    expect(streakEndingAt(const {}, today), 0);
  });

  test('counts consecutive days including today', () {
    final days = {daysAgo(0), daysAgo(1), daysAgo(2)};
    expect(streakEndingAt(days, today), 3);
  });

  test('a streak ending yesterday still counts (today not yet done)', () {
    final days = {daysAgo(1), daysAgo(2)};
    expect(streakEndingAt(days, today), 2);
  });

  test('a gap breaks the streak', () {
    // Done today, missed yesterday, done the two days before.
    final days = {daysAgo(0), daysAgo(2), daysAgo(3)};
    expect(streakEndingAt(days, today), 1);
  });

  test('missing both today and yesterday is a broken streak', () {
    final days = {daysAgo(2), daysAgo(3)};
    expect(streakEndingAt(days, today), 0);
  });
}
