// The words the workout, plan, programme and plate code puts together itself,
// in German — every helper here takes an optional `l10n` and has to keep
// printing exactly the old English without one.
//
// The screens are laid out in German in german_workout_layout_test.dart; this
// file is about what the sentences say.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/exercises/data/muscle_groups.dart';
import 'package:gymfy/features/overload/data/overload_preference.dart';
import 'package:gymfy/features/overload/data/percent_target.dart';
import 'package:gymfy/features/overload/data/training_block.dart';
import 'package:gymfy/features/plan_share/data/plan_document.dart';
import 'package:gymfy/features/plan_share/data/plan_pdf.dart';
import 'package:gymfy/features/plates/data/plate_math.dart';
import 'package:gymfy/features/programs/data/program_catalog.dart';
import 'package:gymfy/features/programs/screens/programs_screen.dart';
import 'package:gymfy/features/programs/widgets/training_block_settings.dart';
import 'package:gymfy/features/workout/data/logging_preferences.dart';
import 'package:gymfy/features/workout/data/next_set.dart';
import 'package:gymfy/features/workout/data/personal_records.dart';
import 'package:gymfy/features/workout/data/rest_timer_controller.dart';
import 'package:gymfy/features/workout/widgets/record_celebration.dart';
import 'package:gymfy/features/workout_notification/data/workout_notification.dart';
import 'package:gymfy/l10n/l10n.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/format.dart';
import 'package:gymfy/shared/utils/units.dart';
import 'package:intl/date_symbol_data_local.dart';

final _de = lookupAppLocalizations(const Locale('de'));
final _en = lookupAppLocalizations(const Locale('en'));

NextSet _next({
  int number = 2,
  int planned = 3,
  double weight = 80,
  int reps = 8,
  int? seconds,
}) => (
  exerciseId: 'barbell_bench_press',
  exerciseName: 'Bench Press',
  setNumber: number,
  plannedSets: planned,
  weightKg: weight,
  reps: seconds == null ? reps : 0,
  seconds: seconds,
  confident: true,
);

void main() {
  group('plurals count the same thing in both languages', () {
    test('a day card', () {
      expect(_en.workoutDayCardSubtitle(1, 'Mon'), '1 exercise • Mon');
      expect(_en.workoutDayCardSubtitle(4, 'Mon'), '4 exercises • Mon');
      expect(_de.workoutDayCardSubtitle(1, 'Mo.'), '1 Übung • Mo.');
      expect(_de.workoutDayCardSubtitle(4, 'Mo.'), '4 Übungen • Mo.');
    });

    test('a planned exercise in the day builder', () {
      // English as it always read, the old "1 sets" included: the template
      // keeps the English verbatim.
      expect(_en.workoutPlannedSetsReps(3, '8–12'), '3 sets × 8–12 reps');
      expect(_de.workoutPlannedSetsReps(1, '10'), '1 Satz × 10 Wdh.');
      expect(_de.workoutPlannedSetsReps(3, '8–12'), '3 Sätze × 8–12 Wdh.');
      expect(_de.workoutPlannedWarmups(1), '1 Aufwärmsatz');
      expect(_de.workoutPlannedWarmups(2), '2 Aufwärmsätze');
    });

    test('the picker, the summary and the warm-up button', () {
      expect(_en.workoutPickerSelected(0), 'Nothing selected');
      expect(_en.workoutPickerSelected(1), '1 selected');
      expect(_de.workoutPickerSelected(0), 'Nichts ausgewählt');
      expect(_de.workoutPickerSelected(3), '3 ausgewählt');
      expect(_de.workoutSummaryExerciseSets(1), '1 Satz');
      expect(_de.workoutSummaryExerciseSets(5), '5 Sätze');
      expect(_en.workoutWarmupLogSets(1), 'Log 1 warm-up set');
      expect(_de.workoutWarmupLogSets(1), '1 Aufwärmsatz loggen');
      expect(_de.workoutWarmupLogSets(3), '3 Aufwärmsätze loggen');
      expect(_de.workoutRecordCount(1), '1 Bestleistung');
      expect(_de.workoutRecordCount(2), '2 Bestleistungen');
      expect(_de.programsBlockWeeks(1), '1 Woche');
      expect(_de.programsBlockWeeks(4), '4 Wochen');
      expect(_de.planShareImported(0), 'Nichts importiert');
      expect(_de.planShareImported(2), '2 Pläne importiert');
    });
  });

  group('the next set', () {
    test('reads as it always has without a language', () {
      expect(describeSetPosition(_next()), 'Set 2 of 3');
      expect(describeSetPosition(_next(number: 4)), 'Set 4');
      expect(describeNextNumbers(_next(), WeightUnit.kg), '80 kg × 8 reps');
      expect(
        describeNextNumbers(_next(weight: 0, reps: 12), WeightUnit.kg),
        '12 reps',
      );
    });

    test('in German', () {
      expect(describeSetPosition(_next(), l10n: _de), 'Satz 2 von 3');
      expect(describeSetPosition(_next(number: 4), l10n: _de), 'Satz 4');
      expect(
        describeNextNumbers(_next(weight: 62.5), WeightUnit.kg, l10n: _de),
        '62,5 kg × 8 Wdh.',
      );
      expect(
        describeNextNumbers(
          _next(weight: 0, reps: 12),
          WeightUnit.kg,
          l10n: _de,
        ),
        '12 Wdh.',
      );
      // A hold is a clock, the same in both.
      expect(
        describeNextNumbers(
          _next(weight: 0, seconds: 90),
          WeightUnit.kg,
          l10n: _de,
        ),
        '1:30',
      );
    });
  });

  group('a beaten record', () {
    const record = BrokenRecord(
      kind: RecordKind.weight,
      value: 102.5,
      previous: 100,
    );

    test('reads as it always has without a language', () {
      expect(
        describeRecord(record, WeightUnit.kg),
        'Heaviest weight · 102.5 kg, was 100 kg',
      );
      expect(formatRecordValue(RecordKind.reps, 12, WeightUnit.kg), '12 reps');
    });

    test('in German', () {
      expect(
        describeRecord(record, WeightUnit.kg, l10n: _de),
        'Höchstes Gewicht · 102,5 kg, vorher 100 kg',
      );
      expect(
        formatRecordValue(RecordKind.reps, 12, WeightUnit.kg, l10n: _de),
        '12 Wdh.',
      );
    });

    test('every kind has a German name of its own', () {
      final names = {
        for (final kind in RecordKind.values) kind.localizedLabel(_de),
      };
      expect(names, hasLength(RecordKind.values.length));
      for (final kind in RecordKind.values) {
        expect(kind.localizedLabel(_en), kind.label);
        expect(kind.localizedLabel(_de), isNot(kind.label));
      }
    });
  });

  group('percentages, plates and bars', () {
    test('a percentage puts a space before the sign in German', () {
      expect(formatPercent(75), '75%');
      expect(formatPercent(72.5), '72.5%');
      // A no-break space, so "%" never wraps onto a line of its own.
      expect(formatPercent(72.5, l10n: _de), '72,5 %');
    });

    test('a plate takes the decimal comma on screen, never in storage', () {
      expect(formatPlate(1.25), '1.25');
      expect(formatPlate(1.25, l10n: _de), '1,25');
      expect(formatPlate(20, l10n: _de), '20');
      // Stored with commas between the plates, so the decimal has to stay a
      // point there whatever the language.
      expect(parsePlates(encodePlates([1.25, 20]), fallback: const []), [
        20,
        1.25,
      ]);
    });

    test('no bar is "Keine"', () {
      expect(formatBar(0, WeightUnit.kg), 'None');
      expect(formatBar(0, WeightUnit.kg, l10n: _de), 'Keine');
      expect(formatBar(20, WeightUnit.kg, l10n: _de), '20 kg');
    });
  });

  group('enum labels stay English, the localized ones are German', () {
    test('overload modes and effort rating', () {
      expect(OverloadMode.fixed.localizedLabel(_de), 'Fest');
      expect(OverloadMode.percent.localizedLabel(_de), 'Prozent');
      expect(OverloadMode.fixed.label, 'Fixed');
      expect(EffortRatingMode.off.localizedLabel(_de), 'Aus');
      // The scales are the same abbreviations in German.
      expect(EffortRatingMode.rpe.localizedLabel(_de), 'RPE');
      expect(EffortRatingMode.rir.localizedLabel(_de), 'RIR');
    });

    test('library sections', () {
      for (final group in MuscleGroup.values) {
        expect(group.localizedLabel(_en), group.label);
      }
      expect(MuscleGroup.back.localizedLabel(_de), 'Rücken');
      expect(MuscleGroup.core.localizedLabel(_de), 'Rumpf');
    });
  });

  group('programmes', () {
    test('facts read the same as before without a language', () {
      final beginner = bundledPrograms.first;
      expect(programFacts(beginner), '3 days a week · Beginner');
      expect(
        programFacts(beginner, l10n: _de),
        '3 Tage pro Woche · Einsteiger',
      );
    });

    test('every bundled programme has a German summary and description', () {
      // The switch falls back to the English for an id it does not know, so
      // a programme added without a translation would show up here.
      for (final program in bundledPrograms) {
        expect(
          program.localizedSummary(_en),
          program.summary,
          reason: program.id,
        );
        expect(
          program.localizedDescription(_en),
          program.description,
          reason: program.id,
        );
        expect(
          program.localizedSummary(_de),
          isNot(program.summary),
          reason: program.id,
        );
        expect(
          program.localizedDescription(_de),
          isNot(program.description),
          reason: program.id,
        );
      }
    });

    test('a training block week', () {
      const week = TrainingBlockWeek(week: 2, blockWeeks: 4, cycle: 1);
      const deload = TrainingBlockWeek(week: 5, blockWeeks: 4, cycle: 1);
      expect(blockWeekLabel(week), 'Week 2 of 4');
      expect(blockWeekLabel(week, l10n: _de), 'Woche 2 von 4');
      expect(blockWeekLabel(deload, l10n: _de), 'Deload-Woche');
    });
  });

  group('a plan file that cannot be read', () {
    test('says why in the reader\'s language', () {
      Object? caught;
      try {
        PlanDocument.decode('{"format": "something.else"}');
      } catch (error) {
        caught = error;
      }

      expect(caught, isA<PlanFormatException>());
      final error = caught! as PlanFormatException;
      expect(error.problem, PlanFormatProblem.wrongFormat);
      expect(
        error.message,
        "That file isn't a Gymfy plan. Look for a file ending in .gymfy.",
      );
      expect(
        error.describe(_de),
        'Diese Datei ist kein Gymfy-Plan. Such nach einer Datei mit der '
        'Endung .gymfy.',
      );
    });

    test('has a German sentence for every problem', () {
      for (final problem in PlanFormatProblem.values) {
        final error = PlanFormatException(problem);
        expect(error.describe(_de), isNot(error.message), reason: '$problem');
      }
    });
  });

  group('the printed plan', () {
    test('only uses characters the PDF font can draw', () {
      // Helvetica without an embedded font has Latin-1 and nothing else. An
      // en dash or a curly quote in one of these would throw while printing.
      final german =
          jsonDecode(File('lib/l10n/app_de.arb').readAsStringSync())
              as Map<String, dynamic>;
      for (final entry in german.entries) {
        if (!entry.key.startsWith('planSharePdf')) continue;
        final text = entry.value as String;
        expect(
          text.runes.every((rune) => rune <= 0xff),
          isTrue,
          reason: '${entry.key}: $text',
        );
      }
    });

    test('builds in German, weekdays and all', () async {
      await initializeDateFormatting('de');
      final bytes = await buildPlanPdf(
        const PlanDocument(
          splits: [
            SharedSplit(
              name: 'PPL',
              days: [
                SharedDay(
                  name: 'Push',
                  weekdays: [1, 4],
                  exercises: [
                    SharedExercise(
                      exerciseId: 'barbell_bench_press',
                      name: 'Barbell Bench Press',
                      muscleIds: ['chest'],
                      sets: 3,
                      reps: 8,
                      repsMax: 12,
                      warmupSets: 2,
                    ),
                  ],
                ),
                SharedDay(name: 'Beine', weekdays: [], exercises: []),
              ],
            ),
          ],
        ),
        l10n: _de,
      );

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });

  group('the workout notification', () {
    final session = WorkoutSession(
      id: 1,
      name: 'Push A',
      startedAt: DateTime(2026, 10, 1, 18),
    );
    final now = DateTime(2026, 10, 1, 18, 30);
    const RestTimerState rest = (
      exerciseId: 'barbell_bench_press',
      exerciseName: 'Bench Press',
      totalSeconds: 90,
      remainingSeconds: 60,
    );

    WorkoutNotificationContent? content({AppLocalizations? l10n}) =>
        workoutNotificationFrom(
          session: session,
          next: _next(),
          rest: rest,
          now: now,
          unit: WeightUnit.kg,
          logId: 'n1',
          l10n: l10n,
        );

    test('reads as it always has without a language', () {
      final english = content()!;
      expect(english.text, 'Bench Press · Set 2 of 3');
      expect(english.bigText, 'Bench Press · Set 2 of 3\nNext: 80 kg × 8 reps');
      expect(english.subText, 'Resting');
      expect(english.labels.logSet, 'Log set');
      expect(english.labels.channelName, 'Workout in progress');
    });

    test('in German, buttons and channel included', () {
      final german = content(l10n: _de)!;
      // The workout's and the exercise's names are the user's, untouched.
      expect(german.title, 'Push A');
      expect(german.text, 'Bench Press · Satz 2 von 3');
      expect(
        german.bigText,
        'Bench Press · Satz 2 von 3\nAls Nächstes: 80 kg × 8 Wdh.',
      );
      expect(german.subText, 'Pause');
      expect(german.labels, workoutNotificationLabels(_de));
      expect(german.labels.logSet, 'Satz loggen');
      expect(german.labels.skipRest, 'Pause überspringen');
      expect(german.labels.tapToOpen, 'Tippen, um Gymfy zu öffnen');
      expect(german.labels.channelName, 'Laufendes Training');
    });

    test('an empty workout says so in German', () {
      final german = workoutNotificationFrom(
        session: session,
        next: null,
        rest: null,
        now: now,
        unit: WeightUnit.kg,
        logId: 'n1',
        l10n: _de,
      )!;
      expect(german.text, 'Noch keine Übungen');
      expect(german.subText, isEmpty);
    });

    test('a language switch is a change worth re-posting', () {
      // The sync only sends what differs from the last post, so the labels
      // have to be part of what is compared.
      expect(content(l10n: _de), isNot(content(l10n: _en)));
    });
  });

  test('the formatting the sheets do by hand uses the language separator', () {
    expect(decimalSeparator(), '.');
    expect(decimalSeparator(l10n: _de), ',');
  });
}
