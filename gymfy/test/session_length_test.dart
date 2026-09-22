// How long a workout took, and when the honest answer is "nobody knows".
//
// One rule, tested in one place, because four screens ask it — the workout
// summary, the Home card, the year grid and the training totals — and three
// different answers across them would be worse than any one being wrong.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/shared/utils/session_length.dart';

void main() {
  final started = DateTime(2026, 9, 16, 18, 58);

  test('a finished session is as long as the clock says', () {
    expect(
      sessionLength(started, DateTime(2026, 9, 16, 20, 6)),
      const Duration(minutes: 68),
    );
  });

  test('a session still running has no length yet', () {
    expect(sessionLength(started, null), isNull);
  });

  test('an end equal to the start is unknown, not zero', () {
    // What an import writes when the file recorded no usable end. "0 min"
    // beside eighteen logged sets is a confident statement of something
    // false; this is what makes every screen say nothing instead.
    expect(sessionLength(started, started), isNull);
  });

  test('an end before the start is unknown too', () {
    // The clock moved. The difference is not a duration, and a negative one
    // would subtract from the year's total.
    expect(
      sessionLength(started, started.subtract(const Duration(hours: 2))),
      isNull,
    );
  });

  test('a genuinely short session keeps its length', () {
    // Distinct from unknown: forty seconds is a number, and the grid rounds
    // it up to a minute so the day still counts.
    expect(
      sessionLength(started, started.add(const Duration(seconds: 40))),
      const Duration(seconds: 40),
    );
  });
}
