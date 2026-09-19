// Turning somebody else's workout export into sessions and sets.
//
// The hard part is not parsing — it is that every app spells its columns
// differently, renames them between versions, and some do not say what unit
// their weights are in. So nothing here matches an exact layout. Each field
// carries a list of names it answers to, the file is asked which of them it
// has, and anything missing is reported by name alongside the headers the
// file *does* contain. A file this cannot read should tell you why in one
// sentence and let you send the header line on; it should never half-import.
//
// Weights are converted to kilograms here, once, because that is how the rest
// of the app stores them.

import '../../../shared/utils/units.dart';
import 'csv_reader.dart';

/// Thrown when a file is readable as CSV but is not a workout export.
class ImportFormatException implements Exception {
  const ImportFormatException(this.message);

  /// Written for a person. Names what was missing and what was found.
  final String message;

  @override
  String toString() => message;
}

/// The column names each field answers to, best guess first.
///
/// Deliberately generous. A name that belongs to no exporter costs nothing;
/// a missing one costs an import. Add to these rather than writing a new
/// parser when a file will not load — that is the whole point of the design,
/// and `import_format_test.dart` covers the shapes known so far.
class ImportColumns {
  static const date = [
    'start_time',
    'start_date',
    'date',
    'workout_date',
    'start',
    'datetime',
  ];

  /// A unit named per *row*, as FitNotes on Android writes it.
  ///
  /// Beaten by an explicit `weight_kg` column, and beats the file-wide
  /// assumption. A file can genuinely mix the two — someone who travelled, or
  /// switched their app's setting halfway through a training year — and one
  /// unit for the whole file would silently rescale half of it.
  static const weightUnit = ['weight_unit', 'unit'];
  static const endDate = ['end_time', 'end'];
  static const workout = ['title', 'workout_name', 'workout', 'name'];
  static const exercise = [
    'exercise_title',
    'exercise_name',
    'exercise',
    'movement',
  ];
  static const reps = ['reps', 'rep_count', 'repetitions'];
  static const setOrder = ['set_index', 'set_order', 'set_number', 'set'];
  static const setType = ['set_type', 'type'];

  /// A boolean warm-up column, as opposed to a set-*type* string.
  ///
  /// StrengthLog writes `warmup,true`. Read as a set type that would be a
  /// working set, and 88 ramp-up sets in a year of training would arrive as
  /// working ones — dragging every chart down and feeding progressive
  /// overload the lightest set of each exercise as though it counted.
  static const warmupFlag = ['warmup', 'is_warmup', 'iswarmup'];

  /// Weight, in the order that tells us the unit for free. A bare "weight"
  /// is last because it says nothing about what it is measured in.
  static const weightKg = ['weight_kg', 'weightkg', 'kg'];
  static const weightLbs = ['weight_lbs', 'weight_lb', 'weightlbs', 'lbs'];
  static const weightAny = ['weight', 'load'];

  /// Load added to a bodyweight movement.
  ///
  /// StrengthLog splits these: a weighted crunch exports `weight` empty,
  /// `bodyweight` 58 and `extraWeight` 10. Gymfy logs bodyweight work as the
  /// *added* load — zero when there is none, which is what the overload maths
  /// already assumes — so the extra is the number that maps across.
  /// `bodyweight` itself is deliberately ignored: adding it would make a
  /// chin-up look like a 58 kg lift and put a personal record on it.
  static const extraWeight = [
    'extra_weight',
    'extraweight',
    'added_weight',
    'additional_weight',
  ];
}

/// One set read out of a file.
class ImportedSet {
  const ImportedSet({
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.isWarmup,
  });

  final String exerciseName;

  /// Always kilograms, converted on the way in.
  final double weightKg;

  final int reps;

  /// Exporters that distinguish a ramp-up say so in a "set type" column.
  /// Where they don't, everything is a working set — the safe direction,
  /// since mislabelling a working set as a warm-up hides it from progress.
  final bool isWarmup;
}

/// One workout read out of a file.
class ImportedSession {
  const ImportedSession({
    required this.name,
    required this.start,
    required this.end,
    required this.sets,
  });

  final String name;
  final DateTime start;

  /// Null when the file records no end time; the importer then leaves the
  /// duration as zero rather than inventing one.
  final DateTime? end;

  final List<ImportedSet> sets;
}

/// Everything a file turned into, plus what could not be made sense of.
class WorkoutImport {
  const WorkoutImport({
    required this.sessions,
    required this.unit,
    required this.unitWasStated,
    required this.skippedRows,
    required this.source,
  });

  /// Newest last, so importing them in order gives sessions increasing ids.
  final List<ImportedSession> sessions;

  /// The unit the file's weights were read as.
  final WeightUnit unit;

  /// Whether the file said so itself (a `weight_kg` column, or a per-row unit
  /// column) or whether this was the caller's assumption. The UI says which,
  /// because getting it wrong silently doubles or halves a whole history.
  final bool unitWasStated;

  /// The app this looks like it came from, when the header says so clearly.
  ///
  /// Nothing depends on it — every column is still matched by name — but it
  /// is worth showing. This screen asks someone to commit a year of their
  /// training on the strength of a preview, and "Looks like a Strong export"
  /// is the line that tells them the file was understood rather than merely
  /// accepted.
  final String? source;

  /// Rows that were not sets — no reps, no exercise, a summary line at the
  /// bottom. Counted rather than listed: the number is reassurance, and a
  /// list of them is noise.
  final int skippedRows;

  int get setCount => sessions.fold(0, (n, s) => n + s.sets.length);

  Set<String> get exerciseNames => {
    for (final session in sessions)
      for (final set in session.sets) set.exerciseName,
  };
}

/// Reads a workout export.
///
/// [assumedUnit] is used only when the file does not name its unit in a column
/// header. Files that say `weight_kg` are read as kilograms whatever is passed.
WorkoutImport parseWorkoutCsv(
  String source, {
  WeightUnit assumedUnit = WeightUnit.kg,
}) {
  final table = CsvTable.parse(source);

  final dateColumn = table.columnFor(ImportColumns.date);
  final exerciseColumn = table.columnFor(ImportColumns.exercise);
  final repsColumn = table.columnFor(ImportColumns.reps);

  // Unit from the header where the file states it, otherwise the caller's.
  final kgColumn = table.columnFor(ImportColumns.weightKg);
  final lbsColumn = table.columnFor(ImportColumns.weightLbs);
  final weightColumn =
      kgColumn ?? lbsColumn ?? table.columnFor(ImportColumns.weightAny);
  final unitColumn = table.columnFor(ImportColumns.weightUnit);
  final unitWasStated =
      kgColumn != null || lbsColumn != null || unitColumn != null;
  final unit = kgColumn != null
      ? WeightUnit.kg
      : (lbsColumn != null ? WeightUnit.lbs : assumedUnit);

  final missing = <String>[
    if (dateColumn == null) 'a date',
    if (exerciseColumn == null) 'an exercise name',
    if (repsColumn == null) 'reps',
    if (weightColumn == null) 'a weight',
  ];
  if (missing.isNotEmpty) {
    // Naming the headers found is the only genuinely useful thing to say: it
    // turns "it did not work" into something the user can forward, and into a
    // one-line fix here.
    throw ImportFormatException(
      "This does not look like a workout export — it has no "
      "${_list(missing)} column.\n\nThe columns found were: "
      "${table.headers.join(', ')}.",
    );
  }

  final workoutColumn = table.columnFor(ImportColumns.workout);
  final endColumn = table.columnFor(ImportColumns.endDate);
  final typeColumn = table.columnFor(ImportColumns.setType);
  final warmupColumn = table.columnFor(ImportColumns.warmupFlag);
  final extraColumn = table.columnFor(ImportColumns.extraWeight);

  // Grouped by start time *and* name: two workouts can begin in the same
  // minute only if the file is odd, but one long workout split across a
  // midnight boundary must not become two.
  final grouped = <String, List<ImportedSet>>{};
  final starts = <String, DateTime>{};
  final ends = <String, DateTime?>{};
  final names = <String, String>{};
  final order = <String>[];
  var skipped = 0;

  for (final row in table.rows) {
    final start = parseImportDate(cell(row, dateColumn));
    final exerciseName = cell(row, exerciseColumn);
    final reps = int.tryParse(cell(row, repsColumn));

    // The plain weight where there is one, otherwise the added load of a
    // bodyweight movement. Never the bodyweight itself — see
    // [ImportColumns.extraWeight].
    final weight =
        _number(cell(row, weightColumn)) ?? _number(cell(row, extraColumn));

    // A row is a set only if it has a date, an exercise, and reps that
    // actually happened. Everything else — a blank line, a summary row, a
    // cardio entry logged by distance — is not something this app can store.
    //
    // `reps == 0` is the one worth spelling out: an exporter writes out the
    // *planned* rows of a workout template whether or not they were
    // performed, so a day you cut short leaves behind sets of 0 × 0. This
    // file has 28 of them. Importing those would add phantom sets to the
    // history, inflate every set count, and put a 0 kg entry in the charts.
    if (start == null || exerciseName.isEmpty || reps == null || reps <= 0) {
      skipped++;
      continue;
    }

    final name = workoutColumn == null ? '' : cell(row, workoutColumn);
    final key = '${start.toIso8601String()}|$name';
    if (!grouped.containsKey(key)) {
      order.add(key);
      starts[key] = start;
      ends[key] = endColumn == null ? null : parseImportDate(cell(row, endColumn));
      names[key] = name.isEmpty ? 'Imported workout' : name;
      grouped[key] = [];
    }

    grouped[key]!.add(
      ImportedSet(
        exerciseName: exerciseName,
        // A bodyweight set exports as an empty weight or a zero, and both are
        // true: no *added* load. Stored as zero rather than skipped, because
        // the reps are real.
        // The row's own unit beats the file's, so a history that switched
        // units halfway through converts correctly on both sides of the
        // switch rather than having half of it rescaled.
        weightKg: weightToKilograms(
          weight ?? 0,
          parseUnitCell(cell(row, unitColumn)) ?? unit,
        ),
        reps: reps,
        // Either spelling: a set-type string, or a boolean column of its own.
        isWarmup:
            isWarmupType(cell(row, typeColumn)) ||
            isTrueish(cell(row, warmupColumn)),
      ),
    );
  }

  final sessions = [
    for (final key in order)
      ImportedSession(
        name: names[key]!,
        start: starts[key]!,
        end: ends[key],
        sets: grouped[key]!,
      ),
  ]..sort((a, b) => a.start.compareTo(b.start));

  return WorkoutImport(
    sessions: sessions,
    unit: unit,
    unitWasStated: unitWasStated,
    skippedRows: skipped,
    source: detectSource(table),
  );
}

/// Which app a file looks like it came from, or null.
///
/// Recognition only — nothing depends on the answer, and an unrecognised file
/// still imports on its column names alone. Each rule is a pair of headers
/// that together are distinctive; one column is not enough, since half these
/// apps have a plain `exercise`.
String? detectSource(CsvTable table) {
  bool has(String name) => table.columnFor([name]) != null;

  if (has('exercise_title') && has('set_index')) return 'Hevy';
  if (has('exercise_name') && has('set_order')) return 'Strong';
  // StrengthLog is the one that arrived as a real file rather than a guess.
  // `extraWeight` alongside `bodyweight` is its signature; no other export
  // splits a weighted crunch into those two columns.
  if (has('bodyweight') && has('extraweight')) return 'StrengthLog';
  if (has('exercise') && has('kind')) return 'FitNotes (iOS)';
  if (has('exercise') && has('weight_unit')) return 'FitNotes';
  return null;
}

/// Reads a per-row unit cell, or null when it says nothing recognisable.
WeightUnit? parseUnitCell(String raw) {
  final value = raw.toLowerCase().trim();
  if (value == 'kg' || value == 'kgs' || value == 'kilograms') {
    return WeightUnit.kg;
  }
  if (value == 'lb' || value == 'lbs' || value == 'pounds') {
    return WeightUnit.lbs;
  }
  return null;
}

/// Whether a "set type" value means a ramp-up rather than a working set.
///
/// Only the words that unambiguously mean it. Anything unrecognised is a
/// working set: calling a real set a warm-up would quietly drop it out of
/// every chart and personal record, which is the more damaging mistake.
bool isWarmupType(String raw) {
  // Contains rather than equals: exporters write `warmup`, `Warm-up` and
  // `Warm Up` for the same thing, and there is no other set type with "warm"
  // in it. Everything unrecognised stays a working set — calling a real set a
  // warm-up would quietly drop it out of every chart and personal record,
  // which is the more damaging mistake of the two.
  return raw.toLowerCase().contains('warm');
}

/// Parses the date formats these exports actually use.
///
/// [DateTime.tryParse] first, which covers ISO-8601 and the
/// `2026-01-15 18:30:00` that most of them write. The rest are the shapes
/// seen in the wild, tried in turn. Returns null rather than a guess — a
/// wrong date puts a workout in the wrong week and quietly reshapes every
/// chart that counts by week.
DateTime? parseImportDate(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;

  // A bare number is a Unix timestamp, which is what StrengthLog writes
  // (`start,1789740587220`). This has to come *before* `DateTime.tryParse`,
  // and it is the single thing that decides whether such a file imports at
  // all: `tryParse` returns null for it, every row then fails its date, and
  // the screen truthfully reports that the file contains no sets — for a file
  // holding a year of training.
  //
  // Ten digits is seconds, thirteen is milliseconds. Anything shorter is not
  // a timestamp: a four-digit year would otherwise be read as 1970.
  if (RegExp(r'^\d{10,13}$').hasMatch(text)) {
    final value = int.parse(text);
    return DateTime.fromMillisecondsSinceEpoch(
      text.length <= 10 ? value * 1000 : value,
    );
  }

  final iso = DateTime.tryParse(text);
  if (iso != null) return iso;

  // "15/01/2026 18:30" and "15.01.2026, 18:30" — day first, which is what a
  // European export writes. Deliberately not supporting the American order:
  // the two are indistinguishable for the first twelve days of any month, and
  // a silent 50/50 guess about somebody's training history is worse than
  // saying the date could not be read.
  final match = RegExp(
    r'^(\d{1,2})[./-](\d{1,2})[./-](\d{4})'
    r'(?:[,\s]+(\d{1,2}):(\d{2})(?::(\d{2}))?)?$',
  ).firstMatch(text);
  if (match == null) return null;

  return DateTime(
    int.parse(match.group(3)!),
    int.parse(match.group(2)!),
    int.parse(match.group(1)!),
    int.tryParse(match.group(4) ?? '') ?? 0,
    int.tryParse(match.group(5) ?? '') ?? 0,
    int.tryParse(match.group(6) ?? '') ?? 0,
  );
}

/// Whether a boolean-ish cell means yes.
///
/// Exporters write `true`, `1`, `yes` and `Y` for the same thing. Anything
/// else — including an empty cell — is no.
bool isTrueish(String raw) {
  final value = raw.toLowerCase().trim();
  return value == 'true' || value == '1' || value == 'yes' || value == 'y';
}

/// A number, tolerating a comma as the decimal separator.
///
/// An empty cell is null rather than zero, so "no weight recorded here" can
/// fall through to the next column instead of stopping at a real-looking 0.
double? _number(String raw) {
  if (raw.isEmpty) return null;
  return double.tryParse(raw.replaceAll(',', '.'));
}

String _list(List<String> items) {
  if (items.length == 1) return items.single;
  return '${items.sublist(0, items.length - 1).join(', ')} or ${items.last}';
}
