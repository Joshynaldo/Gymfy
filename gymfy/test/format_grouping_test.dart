// Big numbers read at a glance; small ones are left alone.
//
// The same function prints what is on the bar and what a season came to, so the
// rule has to serve both: "62.5" needs no help, and "41040" is a number you have
// to count the digits of before you know what it says.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/shared/utils/format.dart';

void main() {
  group('formatWeight', () {
    test('leaves a plate weight alone', () {
      expect(formatWeight(60), '60');
      expect(formatWeight(62.5), '62.5');
      expect(formatWeight(100), '100');
    });

    test('groups from four digits, as the design does', () {
      expect(formatWeight(9480), '9,480');
      expect(formatWeight(41040), '41,040');
      expect(formatWeight(158900), '158,900');
      expect(formatWeight(1842400), '1,842,400');
    });

    test('groups the whole part only', () {
      // The separator belongs left of the point; a grouped decimal would read
      // as a second number.
      expect(formatWeight(1234.5), '1,234.5');
    });

    test('does not group three digits', () {
      // 999 is a weight; 1,000 is a total. The boundary is where a number stops
      // being something you could put on a bar.
      expect(formatWeight(999), '999');
    });
  });
}
