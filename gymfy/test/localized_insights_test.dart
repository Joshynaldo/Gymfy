// The last features to speak German: progress, stats and rank, goals,
// reviews, calories, backup, export, import, Health Connect and the watch.
//
// What is checked here is what no screen test sees on its own: the helpers
// that word things away from a widget (goal captions, the backfill snackbar,
// the watch payload), the exceptions a screen words in the app's language
// while their English stays what the old tests read, and the Android string
// resources that live beside the ARB files rather than in them.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/backup/data/auto_backup.dart';
import 'package:gymfy/features/backup/data/backup_format.dart';
import 'package:gymfy/features/calculator/data/one_rm_math.dart';
import 'package:gymfy/features/calculator/data/strength_standards.dart';
import 'package:gymfy/features/goals/data/goal_labels.dart';
import 'package:gymfy/features/goals/data/goal_progress.dart';
import 'package:gymfy/features/health_connect/data/health_connect_bridge.dart';
import 'package:gymfy/features/health_connect/widgets/health_connect_settings_panel.dart';
import 'package:gymfy/features/import/data/csv_reader.dart';
import 'package:gymfy/features/import/data/import_format.dart';
import 'package:gymfy/features/import/data/import_plan.dart';
import 'package:gymfy/features/progress/screens/progress_screen.dart';
import 'package:gymfy/features/reviews/data/review.dart';
import 'package:gymfy/features/stats/data/training_totals.dart';
import 'package:gymfy/features/wear/data/wear_sync.dart';
import 'package:gymfy/l10n/l10n.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/models/goal.dart';
import 'package:gymfy/shared/models/set_type.dart';
import 'package:gymfy/shared/utils/format.dart';
import 'package:gymfy/shared/utils/units.dart';
import 'package:intl/date_symbol_data_local.dart';

final en = lookupAppLocalizations(const Locale('en'));
final de = lookupAppLocalizations(const Locale('de'));

Goal _goal(GoalKind kind, double target, {DateTime? deadline}) => Goal(
  id: 1,
  kind: kind.name,
  exerciseId: kind == GoalKind.lift ? 'barbell_bench_press' : null,
  target: target,
  startValue: kind == GoalKind.frequency ? null : target - 10,
  deadline: deadline,
  createdAt: DateTime(2026, 9, 1),
);

GoalStatus _status(
  GoalKind kind,
  double target, {
  double? current,
  DateTime? reachedAt,
  int? daysLeft,
  DateTime? deadline,
  int weekStreak = 0,
}) => GoalStatus(
  goal: _goal(kind, target, deadline: deadline),
  kind: kind,
  current: current,
  fraction: 0.5,
  reachedAt: reachedAt,
  daysLeft: daysLeft,
  weekStreak: weekStreak,
);

/// The `name` attributes of every `<string>` and `<plurals>` in an Android
/// resource file.
Set<String> _resourceNames(String path) => {
  for (final match in RegExp(
    r'<(?:string|plurals) name="([^"]+)"',
  ).allMatches(File(path).readAsStringSync()))
    match.group(1)!,
};

void main() {
  setUpAll(() => initializeDateFormatting('de'));

  group('numbers that are not weights', () {
    test('keep their digits and take the language\'s comma', () {
      expect(formatDecimal(1.254, 2), '1.25');
      expect(formatDecimal(1.254, 2, l10n: en), '1.25');
      expect(formatDecimal(1.254, 2, l10n: de), '1,25');
    });

    test('the volume comparison is a sentence of its own in each language', () {
      const bus = (label: 'a London bus', times: 2.34);
      expect(describeVolumeComparison(bus), 'That is 2.3× a London bus.');
      expect(
        describeVolumeComparison(bus, l10n: de),
        'Das sind 2,3 Londoner Doppeldeckerbusse.',
      );

      // Every thing on the list has its own German, so none falls through to
      // the piano.
      final german = {
        for (final item in volumeComparisons)
          describeVolumeComparison((label: item.label, times: 2), l10n: de),
      };
      expect(german, hasLength(volumeComparisons.length));
    });
  });

  group('strength rank', () {
    test('tiers keep their English label and gain a German one', () {
      expect(
        [for (final tier in StrengthTier.values) tier.localizedLabel(en)],
        [for (final tier in StrengthTier.values) tier.label],
      );
      expect(
        [for (final tier in StrengthTier.values) tier.localizedLabel(de)],
        ['Neuling', 'Anfänger', 'Fortgeschritten', 'Erfahren', 'Elite'],
      );
    });

    test('the overall line declines nothing it cannot', () {
      expect(
        en.statsOverallEvery('advanced'),
        'Every ranked lift is advanced.',
      );
      expect(
        de.statsOverallEvery('advanced'),
        'Alle bewerteten Übungen liegen auf Stufe Erfahren.',
      );
      expect(
        de.statsOverallWeakest('elite'),
        'Deine schwächste bewertete Übung. Deine beste liegt auf Stufe Elite.',
      );
    });

    test('formula notes are translated, formula names are not', () {
      for (final formula in OneRmFormula.values) {
        expect(formula.localizedNote(en), formula.note);
        expect(formula.localizedNote(de), isNot(formula.note));
      }
    });
  });

  group('goals', () {
    test('word their title, value and caption in German', () {
      final lift = _status(GoalKind.lift, 102.5, current: 95);
      expect(
        goalTitle(
          lift,
          exerciseName: 'Bench Press',
          unit: WeightUnit.kg,
          l10n: de,
        ),
        'Bench Press · 102,5 kg',
      );
      expect(goalValue(lift, unit: WeightUnit.kg, l10n: de), '95 kg');
      expect(goalCaption(lift, l10n: de), 'Schwerster Arbeitssatz');

      final weekly = _status(GoalKind.frequency, 3, current: 1, weekStreak: 4);
      expect(
        goalTitle(weekly, exerciseName: null, unit: WeightUnit.kg, l10n: de),
        '3 Trainings pro Woche',
      );
      expect(goalValue(weekly, unit: WeightUnit.kg, l10n: de), '1 von 3');
      expect(
        goalCaption(weekly, l10n: de),
        'Noch 2 diese Woche · 4 Wochen in Folge',
      );
      expect(workoutsPerWeekLabel(1, l10n: de), '1 Training pro Woche');
    });

    test('count down and date their deadlines in German', () {
      final soon = _status(
        GoalKind.bodyweight,
        78,
        current: 80,
        daysLeft: 1,
        deadline: DateTime(2026, 10, 3),
      );
      expect(goalCaption(soon, l10n: de), 'Noch 1 Tag');
      expect(goalCaption(soon), '1 day left');

      final late = _status(
        GoalKind.bodyweight,
        78,
        current: 80,
        daysLeft: -3,
        deadline: DateTime(2026, 9, 25),
      );
      expect(goalCaption(late, l10n: de), 'War fällig am 25. Sept. 2026');
    });

    test('say why a draft cannot be saved, in either language', () {
      const draft = GoalDraft(kind: GoalKind.frequency, target: 9);
      final today = DateTime(2026, 10, 2);
      expect(
        goalDraftProblem(draft, today: today),
        'Pick between 1 and 7 workouts a week.',
      );
      expect(
        goalDraftProblem(draft, today: today, l10n: de),
        'Wähl zwischen 1 und 7 Trainings pro Woche.',
      );
    });
  });

  test('a review names its month in the app\'s language', () {
    final october = ReviewPeriod.month(2026, 10);
    expect(october.label, 'October 2026');
    expect(october.localizedLabel(de), 'Oktober 2026');
    expect(october.localizedShortLabel(de), 'Oktober');
    expect(ReviewPeriod.year(2026).localizedLabel(de), '2026');
  });

  test('the progress segments, backup modes and Health Connect states', () {
    expect(
      [for (final view in ProgressView.values) view.localizedLabel(de)],
      ['Körper', 'Verlauf', 'Gesamt'],
    );
    expect(
      [for (final mode in AutoBackupMode.values) mode.localizedLabel(de)],
      ['Aus', 'Wöchentlich', 'Nach dem Training'],
    );
    expect(
      HealthConnectAvailability.notInstalled.localizedLabel(de),
      'Nicht installiert',
    );
    expect(
      HealthConnectAvailability.notInstalled.localizedLabel(en),
      HealthConnectAvailability.notInstalled.label,
    );
  });

  test('the backfill snackbar is whole sentences in German', () {
    expect(
      describeBackfill((
        written: 12,
        deleted: 0,
        untimed: 3,
        error: null,
      ), l10n: de),
      '12 Trainings in Health Connect eingetragen. 3 Trainings ohne erfasste '
      'Dauer wurden ausgelassen.',
    );
    expect(
      describeBackfill((
        written: 0,
        deleted: 0,
        untimed: 0,
        error: 'busy',
      ), l10n: de),
      'Es musste kein Training eingetragen werden. Dann wurde abgebrochen: '
      'busy',
    );
  });

  group('a file that cannot be used', () {
    test('a backup problem is worded by the screen, its English unchanged', () {
      final error = _thrown<BackupException>(
        () => BackupPayload.decode('not json'),
      );
      expect(error.problem, BackupProblem.notABackup);
      expect(error.message, 'That file is not a Gymfy backup.');
      expect(error.describe(de), 'Diese Datei ist kein Gymfy-Backup.');

      final newer = _thrown<BackupException>(
        () => checkRestorable(9999, currentVersion: 26),
      );
      expect(newer.message, contains('newer version'));
      expect(newer.describe(de), contains('neueren Gymfy-Version'));
    });

    test('a damaged backup quotes its diagnostic as it is', () {
      const error = BackupException(BackupProblem.damaged, 'it has no tables');
      expect(
        error.message,
        'That backup is damaged and cannot be read (it has no tables).',
      );
      expect(
        error.describe(de),
        'Dieses Backup ist beschädigt und kann nicht gelesen werden '
        '(it has no tables).',
      );
    });

    test('a file that is not an export names what is missing, and the '
        'columns exactly as the file spells them', () {
      final error = _thrown<ImportFormatException>(
        () => parseWorkoutCsv('Foo,Bar\n1,2'),
      );
      expect(
        error.message,
        'This does not look like a workout export — it has no a date, an '
        'exercise name, reps or a weight column.\n\nThe columns found were: '
        'Foo, Bar.',
      );
      expect(
        error.describe(de),
        'Das sieht nicht nach einem Trainings-Export aus – es fehlt eine '
        'Spalte für Datum, Übungsname, Wiederholungen oder Gewicht.\n\n'
        'Gefundene Spalten: Foo, Bar.',
      );
    });

    test('an empty file says so in German', () {
      final error = _thrown<CsvException>(() => CsvTable.parse(''));
      expect(error.message, 'That file is empty.');
      expect(error.describe(de), 'Diese Datei ist leer.');
    });
  });

  group('an import', () {
    const csv =
        'date,exercise,reps,weight_kg\n'
        '2026-09-20T18:00:00,Bench Press,5,100\n';

    test('reads its columns the same whatever the language', () {
      final english = parseWorkoutCsv(csv);
      final german = parseWorkoutCsv(
        csv,
        untitledName: de.importUntitledWorkout,
      );
      expect(german.setCount, english.setCount);
      expect(german.exerciseNames, english.exerciseNames);
      expect(german.sessions.single.start, english.sessions.single.start);
      // Only the name of an untitled workout follows the language.
      expect(english.sessions.single.name, 'Imported workout');
      expect(german.sessions.single.name, 'Importiertes Training');
    });

    test('names the split it builds in the language it is shown in', () {
      expect(defaultSplitName('Hevy'), 'Hevy import');
      expect(defaultSplitName('Hevy', l10n: de), 'Hevy-Import');
      expect(defaultSplitName(null, l10n: de), 'Importierter Split');
    });
  });

  group('the watch', () {
    final session = WorkoutSession(
      id: 1,
      name: 'Push A',
      startedAt: DateTime(2026, 9, 20, 18),
    );
    const next = (
      exerciseId: 'barbell_bench_press',
      exerciseName: 'Bench Press',
      setNumber: 2,
      plannedSets: 4,
      weightKg: 82.5,
      reps: 8,
      seconds: null,
      confident: true,
    );

    test('is told its lines in the phone app\'s language', () {
      final payload = wearWorkoutFrom(
        session: session,
        rest: null,
        loggedSets: 1,
        now: DateTime(2026, 9, 20, 18, 30),
        next: next,
        l10n: de,
      );
      expect(payload.sets, '1 Satz geloggt');
      expect(payload.nextSet, 'Satz 2 von 4');

      final none = wearWorkoutFrom(
        session: session,
        rest: null,
        loggedSets: 0,
        now: DateTime(2026, 9, 20, 18, 30),
        l10n: de,
      );
      expect(none.sets, 'Noch keine Sätze');
    });

    test('its repeat button reads the German way', () {
      LoggedSet set(double weight) => LoggedSet(
        id: 1,
        sessionId: 1,
        exerciseId: 'barbell_bench_press',
        setNumber: 1,
        weight: weight,
        reps: 8,
        setType: SetType.normal.name,
      );
      expect(
        describeRepeatableSet(set(82.5), WeightUnit.kg, l10n: de),
        '82,5 kg x 8',
      );
      expect(describeRepeatableSet(set(0), WeightUnit.kg, l10n: de), '8 Wdh.');
      expect(describeRepeatableSet(set(82.5), WeightUnit.kg), '82.5 kg x 8');
    });

    test('has its own words in English and German, and the same ones', () {
      const res = 'android/wear/src/main/res';
      final english = _resourceNames('$res/values/strings.xml');
      expect(english, isNotEmpty);
      expect(_resourceNames('$res/values-de/strings.xml'), english);
    });
  });

  test('the Health Connect privacy screen has a German twin that names the '
      'switches as German Settings does', () {
    const res = 'android/app/src/main/res';
    expect(
      _resourceNames('$res/values-de/strings.xml'),
      _resourceNames('$res/values/strings.xml'),
    );

    // Line breaks in a resource file are spaces to Android.
    final german = File(
      '$res/values-de/strings.xml',
    ).readAsStringSync().replaceAll(RegExp(r'\s+'), ' ');
    final arb =
        jsonDecode(File('lib/l10n/app_de.arb').readAsStringSync())
            as Map<String, dynamic>;
    for (final key in [
      'healthConnectWriteTitle',
      'healthConnectReadTitle',
      'healthConnectBackfillTile',
      'healthConnectManageTitle',
    ]) {
      expect(german, contains(arb[key] as String), reason: key);
    }
  });
}

/// What [body] throws, as a [T].
T _thrown<T extends Object>(void Function() body) {
  try {
    body();
  } on T catch (error) {
    return error;
  }
  fail('expected a $T');
}
