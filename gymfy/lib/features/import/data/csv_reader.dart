// Reading a CSV file that somebody else's app wrote.
//
// Hand-written rather than pulling in a package, for one reason worth stating:
// this project has already lost days to dependency conflicts (`share_plus`
// against `file_picker` against AGP 9 — see the note in pubspec.yaml), and it
// is heading for release. CSV is a small, fixed grammar; a hundred lines under
// test is a better trade here than another entry in the dependency graph.
//
// What it handles, because real exports contain all of it:
//
// - Quoted fields, so a workout note with a comma in it stays one field.
// - Newlines *inside* quotes. A multi-line note is why a CSV cannot be read
//   line by line, and reading it line by line is the bug every hand-rolled
//   parser ships with.
// - Doubled quotes (`""`) as an escaped quote inside a quoted field.
// - CRLF or LF, since these files come off phones, Macs and Windows alike.
// - A UTF-8 BOM, which Excel adds and which otherwise becomes an invisible
//   character on the front of the first header — so the first column silently
//   fails to match its own name.

/// Thrown when a file cannot be read as CSV at all.
///
/// Its [message] is written to be shown to a person, not logged.
class CsvException implements Exception {
  const CsvException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Splits CSV [source] into rows of fields.
///
/// Returns rows exactly as written — no header handling, no type guessing.
/// Blank lines are dropped, since exporters commonly end the file with one and
/// a row of one empty string is not a record.
List<List<String>> parseCsv(String source) {
  if (source.isEmpty) return const [];

  // Excel and some exporters prefix UTF-8 files with a byte-order mark. Left
  // in, it becomes part of the first header name, and every lookup for that
  // column misses for a reason nothing on screen can explain.
  var text = source;
  if (text.codeUnitAt(0) == 0xFEFF) text = text.substring(1);

  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  var index = 0;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    // A trailing newline produces one empty field; that is not a record.
    if (row.length > 1 || row.first.isNotEmpty) rows.add(row);
    row = <String>[];
  }

  while (index < text.length) {
    final char = text[index];

    if (quoted) {
      if (char == '"') {
        // A doubled quote inside quotes is one literal quote.
        if (index + 1 < text.length && text[index + 1] == '"') {
          field.write('"');
          index += 2;
          continue;
        }
        quoted = false;
        index++;
        continue;
      }
      field.write(char);
      index++;
      continue;
    }

    switch (char) {
      case '"':
        quoted = true;
      case ',':
        endField();
      case '\r':
        // Swallow the LF of a CRLF pair so it does not open a second row.
        if (index + 1 < text.length && text[index + 1] == '\n') index++;
        endRow();
      case '\n':
        endRow();
      default:
        field.write(char);
    }
    index++;
  }

  // Whatever is left when the text runs out is the last row, unless the file
  // ended on a newline and there is nothing pending.
  if (field.isNotEmpty || row.isNotEmpty) endRow();

  if (quoted) {
    throw const CsvException(
      'This file has a quote that is never closed, so the rest of it cannot '
      'be read. It may have been cut short while being saved.',
    );
  }

  return rows;
}

/// A CSV parsed into a header and its rows, with lookup by column name.
///
/// Column names are matched case-insensitively and ignoring spaces and
/// underscores, so `Set Order`, `set_order` and `setorder` are the same
/// column. Exporters are not consistent about this even between their own
/// versions, and a rename should not break an import.
class CsvTable {
  CsvTable._(this.headers, this.rows, this._columnOf);

  /// The header names exactly as the file spells them — shown back to the user
  /// when a column cannot be found, which is the only useful thing to say.
  final List<String> headers;

  final List<List<String>> rows;

  final Map<String, int> _columnOf;

  /// Parses [source], treating its first row as the header.
  factory CsvTable.parse(String source) {
    final raw = parseCsv(source);
    if (raw.isEmpty) {
      throw const CsvException('That file is empty.');
    }

    final headers = raw.first.map((h) => h.trim()).toList();
    final columnOf = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      // First wins. A duplicate header is malformed, and quietly preferring
      // the later one would read values from a column the user cannot see.
      columnOf.putIfAbsent(normaliseHeader(headers[i]), () => i);
    }

    return CsvTable._(headers, raw.skip(1).toList(), columnOf);
  }

  /// The index of the first of [names] present, or null if none are.
  int? columnFor(List<String> names) {
    for (final name in names) {
      final index = _columnOf[normaliseHeader(name)];
      if (index != null) return index;
    }
    return null;
  }

  /// Whether every one of [names] resolves to a column.
  bool hasAll(Iterable<List<String>> names) =>
      names.every((aliases) => columnFor(aliases) != null);
}

/// A header reduced to its letters and digits.
///
/// The one place header spelling is decided, so aliases elsewhere can be
/// written the way a human would read them.
///
/// Everything that is not alphanumeric goes, brackets included — some
/// exporters write `Weight (kg)` and `Set Duration (sec)` rather than
/// `weight_kg`. Stripping only spaces and underscores left those as
/// `weight(kg)`, which matches no alias, so the column was invisible and the
/// file read as having no weights at all.
String normaliseHeader(String header) =>
    header.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// The field at [column] in [row], or '' when the row is short.
///
/// Short rows are normal: exporters omit trailing empty fields, so a set with
/// no RPE simply ends early. Reading that as an error would reject most real
/// files.
String cell(List<String> row, int? column) {
  if (column == null || column >= row.length) return '';
  return row[column].trim();
}
