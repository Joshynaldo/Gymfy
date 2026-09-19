// The CSV reader, tested against the shapes real exports actually contain.
//
// Written before the importer that uses it, because every mistake a
// hand-rolled CSV parser makes is silent: a note with a comma in it becomes
// two fields, every column after it shifts by one, and the weights land in
// the reps. Nothing throws. You just get a workout history that is wrong.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/import/data/csv_reader.dart';

void main() {
  group('parseCsv', () {
    test('reads plain rows', () {
      expect(parseCsv('a,b,c\n1,2,3'), [
        ['a', 'b', 'c'],
        ['1', '2', '3'],
      ]);
    });

    test('keeps a quoted comma inside its field', () {
      // The one that shifts every later column by one if it is wrong, and the
      // reason a workout note can never be split on commas.
      expect(parseCsv('a,"one, two",c'), [
        ['a', 'one, two', 'c'],
      ]);
    });

    test('keeps a newline inside quotes', () {
      // Why this cannot be done line by line. A multi-line note is one field.
      expect(parseCsv('a,"line one\nline two",c'), [
        ['a', 'line one\nline two', 'c'],
      ]);
    });

    test('a doubled quote is one literal quote', () {
      expect(parseCsv('a,"he said ""hi""",c'), [
        ['a', 'he said "hi"', 'c'],
      ]);
    });

    test('handles CRLF without leaving a stray carriage return', () {
      // A file written on Windows. Left in, every last field on a row ends
      // with an invisible \r and never equals the string it looks like.
      expect(parseCsv('a,b\r\n1,2\r\n'), [
        ['a', 'b'],
        ['1', '2'],
      ]);
    });

    test('strips a UTF-8 byte order mark', () {
      // Excel writes one. Left in, the first header is not the name it
      // appears to be and its column silently never matches.
      final table = CsvTable.parse('﻿Date,Reps\n2026-01-01,8');

      expect(table.headers.first, 'Date');
      expect(table.columnFor(['Date']), 0);
    });

    test('empty trailing fields are kept, not dropped', () {
      // "no RPE recorded" is a value. Dropping it would shorten the row and
      // shift nothing — but it would also make a short row indistinguishable
      // from a malformed one.
      expect(parseCsv('a,b,,'), [
        ['a', 'b', '', ''],
      ]);
    });

    test('a blank line is not a record', () {
      expect(parseCsv('a,b\n\n1,2\n'), [
        ['a', 'b'],
        ['1', '2'],
      ]);
    });

    test('an empty file reads as no rows', () {
      expect(parseCsv(''), isEmpty);
    });

    test('an unclosed quote is refused, not guessed at', () {
      // A truncated download. Carrying on would swallow the rest of the file
      // into one field and import a single enormous nonsense row.
      expect(
        () => parseCsv('a,"never closed\n1,2'),
        throwsA(isA<CsvException>()),
      );
    });
  });

  group('CsvTable', () {
    test('matches headers ignoring case, spaces and underscores', () {
      // Exporters are not consistent about this between their own versions,
      // and a rename should not break an import.
      final table = CsvTable.parse('Set Order,weight_kg,REPS\n1,100,8');

      expect(table.columnFor(['set order']), 0);
      expect(table.columnFor(['setorder']), 0);
      expect(table.columnFor(['Weight KG']), 1);
      expect(table.columnFor(['reps']), 2);
    });

    test('matches a header that puts its unit in brackets', () {
      // Some exporters write `Weight (kg)` rather than `weight_kg`. Stripping
      // only spaces and underscores left that as `weight(kg)`, which matches
      // no alias — so the column was invisible and the file read as having
      // no weights at all.
      final table = CsvTable.parse('Weight (kg),Set Duration (sec)\n100,45');

      expect(table.columnFor(['weight_kg']), 0);
      expect(table.columnFor(['set_duration_sec']), 1);
    });

    test('takes the first of several aliases that is present', () {
      final table = CsvTable.parse('Weight,Reps\n100,8');

      expect(table.columnFor(['weight_kg', 'weight']), 0);
    });

    test('reports a missing column rather than guessing one', () {
      final table = CsvTable.parse('Weight,Reps\n100,8');

      expect(table.columnFor(['duration']), isNull);
      expect(table.hasAll([
        ['weight'],
        ['duration'],
      ]), isFalse);
    });

    test('keeps the header spelling for showing back to the user', () {
      // When a column is missing, the only useful thing to say is what the
      // file actually contains.
      final table = CsvTable.parse('Set Order,weight_kg\n1,100');

      expect(table.headers, ['Set Order', 'weight_kg']);
    });

    test('a duplicate header resolves to the first one', () {
      // Malformed either way, but preferring the later column would read
      // values the user cannot see in their spreadsheet.
      final table = CsvTable.parse('Reps,Reps\n8,12');

      expect(table.columnFor(['reps']), 0);
    });

    test('an empty file is refused with something readable', () {
      expect(() => CsvTable.parse(''), throwsA(isA<CsvException>()));
    });
  });

  group('cell', () {
    test('trims', () {
      expect(cell(['  100  '], 0), '100');
    });

    test('a short row reads as empty, not as an error', () {
      // Exporters omit trailing empty fields, so a set with no RPE ends
      // early. Treating that as malformed would reject most real files.
      expect(cell(['100'], 3), '');
    });

    test('a missing column reads as empty', () {
      expect(cell(['100'], null), '');
    });
  });
}
