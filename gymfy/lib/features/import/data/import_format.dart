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

  /// How long a set was held. Hevy writes `duration_seconds`, StrengthLog a
  /// `time` column spelled `mm:ss` or `hh:mm:ss`.
  static const seconds = [
    'duration_seconds',
    'set_duration_sec',
    'seconds',
    'time',
    'duration',
  ];

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
    required this.seconds,
  });

  final String exerciseName;

  /// Always kilograms, converted on the way in.
  final double weightKg;

  final int reps;

  /// Seconds held, for a set logged by time. Null for a counted set.
  final int? seconds;

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
    required this.skippedNoDate,
    required this.unreadableDate,
    required this.namesWorkouts,
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

  /// How many of [skippedRows] were dropped because their date could not be
  /// read, and the first such date exactly as the file spelled it.
  ///
  /// These two exist because of how the Hevy bug presented. Every column was
  /// present, so nothing threw; every row was dropped, so the screen said the
  /// file contained no sets — which read as "your export is empty" when what
  /// it meant was "this app cannot read `18 Sept. 2026`". A count and one
  /// sample of the offending cell turn that into a message someone can
  /// forward and a one-line fix here.
  final int skippedNoDate;
  final String? unreadableDate;

  /// Whether the file had a column naming each workout.
  ///
  /// Without one every session is called "Imported workout", which is fine as
  /// a label on a history and useless as a plan: a split built from it would
  /// be a single day holding every lift the person has ever done. So the
  /// split builder asks this before offering anything.
  final bool namesWorkouts;

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
  final secondsColumn = table.columnFor(ImportColumns.seconds);
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
  var skippedNoDate = 0;
  String? unreadableDate;
  // A title *column* is not the same as a title. An export with the column
  // present and empty on every row would otherwise offer to build a split of
  // one day called "Imported workout" holding everything ever lifted.
  var sawWorkoutName = false;

  for (final row in table.rows) {
    final rawDate = cell(row, dateColumn);
    final start = parseImportDate(rawDate);
    if (start == null && rawDate.isNotEmpty) {
      skippedNoDate++;
      // The first one only. A thousand identical complaints say no more than
      // one, and the screen has room for a sample, not a list.
      unreadableDate ??= rawDate;
    }
    final exerciseName = cell(row, exerciseColumn);
    final reps = int.tryParse(cell(row, repsColumn));

    // The plain weight where there is one, otherwise the added load of a
    // bodyweight movement. Never the bodyweight itself — see
    // [ImportColumns.extraWeight].
    final weight =
        _number(cell(row, weightColumn)) ?? _number(cell(row, extraColumn));

    final seconds = parseDurationCell(cell(row, secondsColumn));

    // A row is a set only if it has a date, an exercise, and either reps that
    // actually happened or a hold that lasted. Everything else — a blank
    // line, a summary row, a cardio entry logged only by distance — is not
    // something this app can store.
    //
    // `reps == 0` is the one worth spelling out: an exporter writes out the
    // *planned* rows of a workout template whether or not they were
    // performed, so a day you cut short leaves behind sets of 0 × 0. One real
    // export had 28 of them. Importing those would add phantom sets to the
    // history, inflate every set count, and put a 0 kg entry in the charts.
    final counted = reps != null && reps > 0;
    final held = seconds != null && seconds > 0;
    if (start == null || exerciseName.isEmpty || (!counted && !held)) {
      skipped++;
      continue;
    }

    final name = workoutColumn == null ? '' : cell(row, workoutColumn);
    final key = '${start.toIso8601String()}|$name';
    if (!grouped.containsKey(key)) {
      order.add(key);
      starts[key] = start;
      ends[key] = endColumn == null
          ? null
          : plausibleEnd(start, parseImportDate(cell(row, endColumn)));
      names[key] = name.isEmpty ? 'Imported workout' : name;
      if (name.isNotEmpty) sawWorkoutName = true;
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
        // One or the other, matching how the app stores them. A row with
        // both is read as counted: reps are the more specific claim, and an
        // exporter that also records how long the set took is describing the
        // same set, not a second one.
        reps: counted ? reps : 0,
        seconds: counted ? null : seconds,
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
    skippedNoDate: skippedNoDate,
    unreadableDate: unreadableDate,
    namesWorkouts: sawWorkoutName,
    source: detectSource(table),
  );
}

/// The longest a workout is allowed to have lasted for its end time to be
/// believed.
///
/// Four hours, chosen off the two real exports rather than picked as a round
/// number. A year of Hevy workouts runs 25 to 165 minutes, and the longest is
/// 2h 45m. The StrengthLog file's believable durations stop at 176 minutes and
/// the record-close artefacts start at 269 — a clean gap, with the ceiling in
/// the middle of it.
///
/// It was six hours first, which let five artefacts through: one of them still
/// put its workout on the following day, which is the whole defect this is
/// here to prevent.
const maxWorkoutDuration = Duration(hours: 4);

/// An end time, or null when the file's is not one.
///
/// StrengthLog's `end` column is when the workout *record* was last closed,
/// not when training stopped — so a session left open until the next one was
/// started exports an end days later. In the real export, ten of thirty
/// workouts ended on a different calendar day from the one they were trained
/// on, and one claimed 33 days of continuous training.
///
/// That is not a cosmetic problem. The year activity dates each square by the
/// *end* and shades it by the duration, so those ten workouts appeared on the
/// wrong day, and the long one would have saturated a month of the map. Nulled
/// rather than clipped to six hours: the file has told us nothing usable about
/// when this workout finished, and inventing a plausible-looking end would put
/// a number on screen that no one could tell was made up.
///
/// A genuine session that runs past midnight is kept — the real Hevy export
/// has one starting 23:50 and ending 02:14, and it is a workout, not an error.
DateTime? plausibleEnd(DateTime start, DateTime? end) {
  if (end == null) return null;
  if (end.isBefore(start)) return null;
  if (end.difference(start) > maxWorkoutDuration) return null;
  return end;
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
  // Some phones write a non-breaking or narrow space before the time rather
  // than a plain one — ICU does it for `4:01 PM` on newer Android and iOS.
  // It is invisible, it is not `\s` to a regex, and left in it fails every
  // pattern below for a reason nothing on screen could explain.
  final text = raw.replaceAll(RegExp(r'[    ]'), ' ').trim();
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
  if (match == null) return _parseNamedMonthDate(text);

  return DateTime(
    int.parse(match.group(3)!),
    int.parse(match.group(2)!),
    int.parse(match.group(1)!),
    int.tryParse(match.group(4) ?? '') ?? 0,
    int.tryParse(match.group(5) ?? '') ?? 0,
    int.tryParse(match.group(6) ?? '') ?? 0,
  );
}

/// Reads a duration cell, in seconds.
///
/// Two spellings, because exporters use both: a plain number of seconds
/// (`45`), and a clock (`0:45`, `1:30:00`). Returns null for anything else,
/// and for a zero-length one — `00:00:00` is what an exporter writes for a
/// set that was set up and never done, and importing that as a hold would put
/// a zero-second plank in the history.
int? parseDurationCell(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;

  final plain = int.tryParse(text);
  if (plain != null) return plain > 0 ? plain : null;

  final parts = text.split(':');
  if (parts.length < 2 || parts.length > 3) return null;

  var total = 0;
  for (final part in parts) {
    final value = int.tryParse(part.trim());
    if (value == null || value < 0) return null;
    total = total * 60 + value;
  }
  return total > 0 ? total : null;
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

/// Month names, folded to plain letters, for the dates Hevy writes.
///
/// Hevy exports its dates in the *device's* locale and puts nothing in the
/// file to say which one: a German phone writes `18 Sept. 2026, 16:01`, an
/// English one `18 Sep 2026, 16:01`, an American one `Sep 18, 2026, 4:01 PM`.
/// None of those parse as a number or as ISO-8601, so without this table every
/// row of a Hevy export fails its date and the screen reports a year of
/// training as an empty file. That is exactly what it did: a real 1,466-row
/// export read as 0 workouts.
///
/// The languages Hevy ships in, each with the abbreviations its locale
/// actually produces. Looked up as whole tokens rather than by a three-letter
/// prefix, because a prefix is not unique — French `juin` and `juillet` both
/// start `jui`, and guessing between June and July would move a workout by a
/// month.
///
/// Every key here means one month in all of them; no spelling is January in
/// one language and October in another. `import_format_test.dart` asserts
/// that, so a language added later cannot quietly introduce a clash.
const monthNumbers = <String, int>{
  // English.
  'jan': 1, 'january': 1,
  'feb': 2, 'february': 2,
  'mar': 3, 'march': 3,
  'apr': 4, 'april': 4,
  'may': 5,
  'jun': 6, 'june': 6,
  'jul': 7, 'july': 7,
  'aug': 8, 'august': 8,
  'sep': 9, 'sept': 9, 'september': 9,
  'oct': 10, 'october': 10,
  'nov': 11, 'november': 11,
  'dec': 12, 'december': 12,

  // German. `Sept.` is the spelling that broke the real file — German
  // abbreviates September to four letters where English uses three.
  'januar': 1, 'februar': 2, 'marz': 3, 'maerz': 3, 'mai': 5,
  'juni': 6, 'juli': 7, 'okt': 10, 'oktober': 10, 'dez': 12, 'dezember': 12,

  // Spanish.
  'ene': 1, 'enero': 1, 'febrero': 2, 'marzo': 3, 'abr': 4, 'abril': 4,
  'mayo': 5, 'junio': 6, 'julio': 7, 'ago': 8, 'agosto': 8,
  'setiembre': 9, 'septiembre': 9, 'octubre': 10, 'noviembre': 11,
  'dic': 12, 'diciembre': 12,

  // French. `aout` and `fevr` arrive here already stripped of their accents.
  'janv': 1, 'janvier': 1, 'fevr': 2, 'fevrier': 2, 'mars': 3,
  'avr': 4, 'avril': 4, 'juin': 6, 'juil': 7, 'juillet': 7, 'aout': 8,
  'septembre': 9, 'octobre': 10, 'novembre': 11, 'decembre': 12,

  // Italian.
  'gen': 1, 'gennaio': 1, 'febbraio': 2, 'aprile': 4, 'mag': 5, 'maggio': 5,
  'giu': 6, 'giugno': 6, 'lug': 7, 'luglio': 7, 'set': 9, 'settembre': 9,
  'ott': 10, 'ottobre': 10, 'dicembre': 12,

  // Portuguese. `marco` is `março` folded.
  'janeiro': 1, 'fev': 2, 'fevereiro': 2, 'marco': 3, 'maio': 5,
  'junho': 6, 'julho': 7, 'setembro': 9, 'out': 10, 'outubro': 10,
  'novembro': 11, 'dezembro': 12,

  // Dutch.
  'januari': 1, 'februari': 2, 'mrt': 3, 'maart': 3, 'mei': 5,
  'augustus': 8,
};

/// Weekday abbreviations, folded the same way month names are.
///
/// A locale that prefixes its dates with the weekday (`mar., 18 ago. 2026`)
/// is otherwise harmless — an unrecognised short word is skipped. The one that
/// is not harmless is `mar`, which is Tuesday in Spanish, French and Italian
/// and March in all three: taken as a month it moves every Tuesday workout in
/// the file six months into the past, with nothing on screen to show for it.
///
/// Listed in full rather than as the single colliding entry, so that adding a
/// language to [monthNumbers] later cannot quietly create a second one.
const weekdayNames = <String>{
  // English, German, Dutch.
  'mon', 'monday', 'tue', 'tues', 'tuesday', 'wed', 'wednesday',
  'thu', 'thur', 'thurs', 'thursday', 'fri', 'friday', 'sat', 'saturday',
  'sun', 'sunday',
  'mo', 'di', 'mi', 'do', 'fr', 'sa', 'so',
  'montag', 'dienstag', 'mittwoch', 'donnerstag', 'freitag', 'samstag',
  'sonntag',
  'ma', 'wo', 'vr', 'za', 'zo',
  // Spanish, French, Italian, Portuguese.
  'lun', 'mar', 'mer', 'mie', 'jue', 'jeu', 'vie', 'ven', 'sab', 'dom',
  'gio', 'seg', 'ter', 'qua', 'qui', 'sex',
  'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo',
  'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche',
  'lunedi', 'martedi', 'mercoledi', 'giovedi', 'venerdi', 'sabato',
  'domenica',
};

/// A month token reduced to plain lowercase letters.
///
/// Strips the trailing period German and French abbreviations carry (`Sept.`,
/// `janv.`) and folds the accents, so `März`, `août` and `março` arrive as
/// `marz`, `aout` and `marco` — the spellings [monthNumbers] is keyed by.
/// Folding rather than listing both spellings keeps one entry per month name
/// instead of two that can drift apart.
String foldMonthName(String token) {
  const accents = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };

  final folded = StringBuffer();
  for (final character in token.toLowerCase().split('')) {
    folded.write(accents[character] ?? character);
  }
  // Everything that is not a letter goes: the abbreviation's period, and the
  // stray punctuation a locale occasionally leaves next to it.
  return folded.toString().replaceAll(RegExp(r'[^a-z]'), '');
}

/// Parses a date written with its month spelled out, in any order.
///
/// `18 Sept. 2026, 16:01`, `Sep 18, 2026, 4:01 PM`, `18th March 2026`. Read by
/// pulling the time off the end and then sorting the remaining tokens by what
/// they are rather than by where they sit: a four-digit number is the year, a
/// word is the month, what is left is the day. Order therefore does not
/// matter — and unlike a numeric `01/02/2026` it cannot be ambiguous, because
/// the month has named itself.
///
/// Returns null unless all three parts were found and the result is a real
/// calendar date. `31 February 2026` is rejected rather than rolled forward
/// into March: [DateTime] would accept it silently, and a workout moved to the
/// wrong month is worse than one the user is told could not be read.
DateTime? _parseNamedMonthDate(String text) {
  var head = text;
  var hour = 0;
  var minute = 0;
  var second = 0;

  // The clock is last whatever order the date parts came in, so it can be
  // taken off before anything else is worked out. Two patterns rather than one
  // optional group: a trailing `(am|pm)?` also matches the empty string, and
  // then the 24-hour case would fall into the meridiem branch with no
  // meridiem.
  // `\s*` between the two letters because Spanish writes the day period as
  // `4:01 p. m.`, with a space in the middle. Without it that string matches
  // neither pattern, the time is never taken off, and the date silently comes
  // back as midnight — which is worse than failing, since two workouts on one
  // day would then share a start time and be merged into one.
  final meridiemTime = RegExp(
    r'[\s,]+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([ap])\.?\s*m\.?$',
    caseSensitive: false,
  ).firstMatch(text);
  final time =
      meridiemTime ??
      RegExp(r'[\s,]+(\d{1,2}):(\d{2})(?::(\d{2}))?$').firstMatch(text);

  if (time != null) {
    hour = int.parse(time.group(1)!);
    minute = int.parse(time.group(2)!);
    second = int.tryParse(time.group(3) ?? '') ?? 0;

    // A 12-hour clock needs moving at both ends: 12:30 AM is 00:30, 1:30 PM is
    // 13:30, and 12:30 PM is already right.
    final meridiem = meridiemTime?.group(4)?.toLowerCase();
    if (meridiem == 'p' && hour < 12) hour += 12;
    if (meridiem == 'a' && hour == 12) hour = 0;

    head = text.substring(0, time.start);
  }

  // A clock still sitting in what is left means the time was not understood —
  // `16:01 Uhr`, `16:01 GMT+2`. Carrying on would drop it and hand back
  // midnight, and a workout silently moved to 00:00 is the one outcome worse
  // than an honest refusal: two sessions on the same day would then share a
  // start time and be merged into one.
  if (RegExp(r'\d{1,2}:\d{2}').hasMatch(head)) return null;

  int? day;
  int? month;
  int? year;

  // A month name that is *also* a weekday abbreviation, held back in case a
  // real month turns up later in the string. See [weekdayNames].
  int? weekdayMonth;

  for (final token in head.split(RegExp(r'[\s,./-]+'))) {
    if (token.isEmpty) continue;

    final number = int.tryParse(token);
    if (number != null) {
      // Four digits is the year, one or two the day. A three-digit number is
      // neither, and a two-digit year has no unambiguous reading — `18 Sep 26`
      // could be 2026 or the 26th — so both give up rather than guess.
      //
      // A second number for a slot already filled means this is not a plain
      // date either: `18 Sep 2026 16.01` splits into 18, Sep, 2026, 16, 01,
      // and quietly ignoring the 16 and the 01 would hand back midnight for a
      // string that plainly states a time.
      if (token.length == 4) {
        if (year != null) return null;
        year = number;
      } else if (token.length <= 2) {
        if (day != null) return null;
        day = number;
      } else {
        return null;
      }
      continue;
    }

    // `18th`, `1er` — an English or French ordinal day.
    final ordinal = RegExp(
      r'^(\d{1,2})(?:st|nd|rd|th|er|e)$',
      caseSensitive: false,
    ).firstMatch(token);
    if (ordinal != null) {
      if (day != null) return null;
      day = int.parse(ordinal.group(1)!);
      continue;
    }

    final word = foldMonthName(token);
    final named = monthNumbers[word];
    if (named != null) {
      // `mar` is March in Spanish, French and Italian *and* the abbreviation
      // for Tuesday in all three. Taken as a month, `mar, 18 ago 2026` reads
      // as 18 March — every Tuesday workout in the file jumping six months
      // into the past, silently. So a token that could be either waits: if a
      // real month name turns up, it wins.
      if (weekdayNames.contains(word)) {
        weekdayMonth ??= named;
      } else {
        month ??= named;
      }
      continue;
    }

    // A word this long that is not a month means the cell is not a date, and
    // reading a date out of whatever digits it happens to contain would be
    // exactly the silent guess this whole function refuses to make: `Week 12
    // 2026` would otherwise come back as the 12th of some month.
    //
    // Short words are let through, because the formats that need it are real:
    // Portuguese writes `18 de set. de 2026`, Spanish `18 de septiembre de
    // 2026`, German `18. September 2026 um 16:01`.
    if (word.length > 3) return null;
  }

  // Only now, once nothing better has turned up.
  month ??= weekdayMonth;

  if (day == null || month == null || year == null) return null;
  if (day < 1 || day > 31 || hour > 23 || minute > 59 || second > 59) {
    return null;
  }

  final date = DateTime(year, month, day, hour, minute, second);
  // DateTime rolls a day past the end of its month into the next one without
  // complaint. Caught here, because a silently shifted date is the one kind of
  // wrong this function exists to avoid.
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}
