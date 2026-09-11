// Turning your logged history into a file you can take somewhere else.
//
// Two formats, because they answer different questions:
//
//   * **CSV** is one row per logged set — flat, sortable, and something a
//     spreadsheet can pivot. It's what you want to plot your own charts.
//   * **JSON** keeps the structure CSV has to flatten away (sets nested inside
//     sessions) and carries the rest of your data too, so it's the honest
//     answer to "give me everything I've put in".
//
// Neither is an app backup: there is no importer for these, and they carry no
// ids. They exist so your data isn't trapped, not so it can be restored.

import 'dart:convert';

/// One logged set, flattened for export.
typedef ExportSet = ({
  DateTime performedAt,
  String sessionName,
  String exerciseName,
  List<String> muscleIds,
  int setNumber,
  bool isWarmup,
  double weightKg,
  int reps,
});

/// One body measurement, for the JSON export.
typedef ExportMeasurement = ({
  DateTime date,
  double? weightKg,
  double? chestCm,
  double? waistCm,
  double? hipsCm,
  double? armsCm,
  double? legsCm,
});

/// One logged meal, for the JSON export.
typedef ExportMeal = ({
  DateTime date,
  String name,
  int calories,
  int protein,
  int carbs,
  int fat,
});

/// Everything the exporter reads.
class ExportData {
  const ExportData({
    required this.sets,
    this.measurements = const [],
    this.meals = const [],
  });

  final List<ExportSet> sets;
  final List<ExportMeasurement> measurements;
  final List<ExportMeal> meals;
}

/// Column order of the CSV. Named here so the header and the rows can't drift
/// apart — the classic way an export ends up one column out.
const csvColumns = [
  'date',
  'time',
  'session',
  'exercise',
  'muscles',
  'set',
  'type',
  'weight_kg',
  'reps',
  'volume_kg',
];

/// Renders [sets] as CSV, newest last.
///
/// Weights are always in kilograms and the column says so. The app stores kg
/// whatever unit you read in, and a column called plain "weight" would be a
/// number with no unit attached the moment it left the app.
String toCsv(List<ExportSet> sets) {
  final buffer = StringBuffer()..writeln(csvColumns.join(','));

  for (final set in sets) {
    buffer.writeln(
      [
        _date(set.performedAt),
        _time(set.performedAt),
        set.sessionName,
        set.exerciseName,
        // Semicolons inside the field, not commas: a comma here would be quoted
        // correctly but still trips up every naive splitter someone points at it.
        set.muscleIds.join('; '),
        '${set.setNumber}',
        set.isWarmup ? 'warmup' : 'working',
        _number(set.weightKg),
        '${set.reps}',
        _number(set.weightKg * set.reps),
      ].map(csvField).join(','),
    );
  }

  return buffer.toString();
}

/// Escapes one CSV field per RFC 4180.
///
/// Exercise names and session names are user-typed, so "Farmer's Walk, heavy"
/// and a name containing a quote both have to survive. Unquoted, that one comma
/// would shift every later column by one and silently corrupt the row.
String csvField(String value) {
  final needsQuotes =
      value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r');
  if (!needsQuotes) return value;
  return '"${value.replaceAll('"', '""')}"';
}

/// Renders everything as JSON, structured rather than flattened.
String toJson(ExportData data, {DateTime? exportedAt}) {
  // Sets grouped back into the sessions they belong to. CSV has to repeat the
  // session name on every row; JSON doesn't, and the nesting is the shape the
  // data actually has.
  final sessions = <String, List<ExportSet>>{};
  for (final set in data.sets) {
    // Keyed on name + timestamp: two sessions can share a name, and the same
    // name on the same second is one session by any reading.
    sessions
        .putIfAbsent(
          '${set.performedAt.toIso8601String()}|${set.sessionName}',
          () => [],
        )
        .add(set);
  }

  return const JsonEncoder.withIndent('  ').convert({
    'app': 'gymfy',
    'exportedAt': (exportedAt ?? DateTime.now()).toIso8601String(),
    // Named so nobody mistakes this for a backup and expects to restore it.
    'note':
        'A copy of your data for your own use. Weights are in kilograms. '
        'This file cannot be imported back into Gymfy.',
    'workouts': [
      for (final entry in sessions.entries)
        {
          'date': entry.value.first.performedAt.toIso8601String(),
          'name': entry.value.first.sessionName,
          'sets': [
            for (final set in entry.value)
              {
                'exercise': set.exerciseName,
                'muscles': set.muscleIds,
                'set': set.setNumber,
                'warmup': set.isWarmup,
                'weightKg': set.weightKg,
                'reps': set.reps,
              },
          ],
        },
    ],
    'measurements': [
      for (final m in data.measurements)
        {
          'date': m.date.toIso8601String(),
          // Omitted rather than null: you didn't measure your hips that day,
          // and a null reads as a failed measurement rather than a skipped one.
          if (m.weightKg != null) 'weightKg': m.weightKg,
          if (m.chestCm != null) 'chestCm': m.chestCm,
          if (m.waistCm != null) 'waistCm': m.waistCm,
          if (m.hipsCm != null) 'hipsCm': m.hipsCm,
          if (m.armsCm != null) 'armsCm': m.armsCm,
          if (m.legsCm != null) 'legsCm': m.legsCm,
        },
    ],
    'meals': [
      for (final meal in data.meals)
        {
          'date': meal.date.toIso8601String(),
          'name': meal.name,
          'calories': meal.calories,
          'protein': meal.protein,
          'carbs': meal.carbs,
          'fat': meal.fat,
        },
    ],
  });
}

/// `gymfy-workouts-2026-08-24.csv` — dated, because you will export more than
/// once and two files called `gymfy.csv` in a downloads folder are useless.
String exportFileName(String extension, {DateTime? on}) {
  final day = on ?? DateTime.now();
  return 'gymfy-workouts-${_date(day)}.$extension';
}

String _date(DateTime dt) => '${dt.year}-${_two(dt.month)}-${_two(dt.day)}';

String _time(DateTime dt) => '${_two(dt.hour)}:${_two(dt.minute)}';

String _two(int value) => value.toString().padLeft(2, '0');

/// Trims the pointless `.0` off whole numbers without rounding real decimals
/// away — 82.5 has to stay 82.5.
String _number(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';
